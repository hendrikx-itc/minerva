

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,2,0)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


DROP FUNCTION IF EXISTS "trend_directory"."completeness"(name, timestamp with time zone, timestamp with time zone);

CREATE TABLE "trend_directory"."trend_store_part_stats"
(
  "trend_store_part_id" integer NOT NULL,
  "timestamp" timestamp with time zone NOT NULL,
  "modified" timestamp with time zone NOT NULL,
  "count" integer NOT NULL,
  PRIMARY KEY (trend_store_part_id, timestamp)
);

COMMENT ON COLUMN "trend_directory"."trend_store_part_stats"."modified" IS 'Time of the last modification';

GRANT SELECT ON TABLE "trend_directory"."trend_store_part_stats" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."trend_store_part_stats" TO minerva_writer;

CREATE VIEW "trend_directory"."trend_store_part_stats_to_update" AS
SELECT tsps.trend_store_part_id,
    tsps.timestamp
  FROM trend_directory.trend_store_part_stats tsps
  JOIN trend_directory.modified m
  ON tsps.trend_store_part_id = m.trend_store_part_id
    AND tsps.timestamp = m.timestamp
  WHERE tsps.modified < m.last;


CREATE FUNCTION "trend_directory"."completeness"(name, "start" timestamp with time zone, "end" timestamp with time zone)
    RETURNS TABLE("timestamp" timestamptz, "count" bigint)
AS $$
DECLARE
    gran interval;
    truncated_start timestamptz;
    truncated_end timestamptz;
BEGIN
    SELECT granularity INTO gran
    FROM trend_directory.trend_store_part tsp
    JOIN trend_directory.trend_store ts ON ts.id = tsp.trend_store_id
    WHERE tsp.name = $1;

    CASE gran
    WHEN '1month' THEN
        SELECT date_trunc('month', $2) INTO truncated_start;
        SELECT date_trunc('month', $3) INTO truncated_end;
    WHEN '1w' THEN
        SELECT date_trunc('week', $2) INTO truncated_start;
        SELECT date_trunc('week', $3) INTO truncated_end;
    WHEN '1d' THEN
        SELECT date_trunc('day', $2) INTO truncated_start;
        SELECT date_trunc('day', $3) INTO truncated_end;
    WHEN '1h' THEN
        SELECT date_trunc('hour', $2) INTO truncated_start;
        SELECT date_trunc('hour', $3) INTO truncated_end;
    ELSE
        SELECT trend_directory.index_to_timestamp(gran, trend_directory.timestamp_to_index(gran, $2)) INTO truncated_start;
        SELECT trend_directory.index_to_timestamp(gran, trend_directory.timestamp_to_index(gran, $3)) INTO truncated_end;
    END CASE;

    RETURN QUERY
    WITH trend_data AS (
        SELECT s.timestamp, s.count from trend_directory.trend_store_part_stats s
        JOIN trend_directory.trend_store_part p ON s.trend_store_part_id = p.id
        WHERE s.timestamp >= truncated_start and s.timestamp <= truncated_end and p.name = $1
    )
    SELECT t, coalesce(d.count, 0)::bigint
        FROM generate_series(truncated_start, truncated_end, gran) t
        LEFT JOIN trend_data d on d.timestamp = t ORDER BY t asc;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."completeness"(name, "start" timestamp with time zone, "end" timestamp with time zone) IS 'Return table with record counts grouped by timestamp';


CREATE FUNCTION "trend_directory"."base_table_name_by_trend_store_part_id"("trend_store_part_id" integer)
    RETURNS name
AS $$
SELECT name FROM trend_directory.trend_store_part
  WHERE id = $1;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "trend_directory"."get_count"("trend_store_part_id" integer, "timestamp" timestamptz)
    RETURNS integer
AS $$
DECLARE
  result integer;
BEGIN
  EXECUTE FORMAT('SELECT COUNT(*)::integer FROM trend.%I WHERE timestamp = ''%s''',
    trend_directory.base_table_name_by_trend_store_part_id($1),
    $2) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "trend_directory"."recalculate_trend_store_part_stats"("trend_store_part_id" integer, "timestamp" timestamptz)
    RETURNS void
AS $$
UPDATE trend_directory.trend_store_part_stats
  SET modified = now(), count = trend_directory.get_count($1, $2)
  WHERE trend_store_part_id = $1
    AND timestamp = $2;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."update_trend_store_part_stats"()
    RETURNS void
AS $$
SELECT trend_directory.recalculate_trend_store_part_stats(trend_store_part_id, timestamp)
  FROM trend_directory.trend_store_part_stats_to_update;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."create_missing_trend_store_part_stats"()
    RETURNS void
AS $$
INSERT INTO trend_directory.trend_store_part_stats (trend_store_part_id, timestamp, modified, count)
  SELECT m.trend_store_part_id, m.timestamp, '2000-01-01 00:00:00+02', 0
    FROM trend_directory.modified m
      LEFT JOIN trend_directory.trend_store_part_stats s
      ON s.trend_store_part_id = m.trend_store_part_id AND s.timestamp = m.timestamp
      WHERE s IS NULL;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."create_missing_trend_store_part_stats"() IS 'Create trend_store_part_stat where it does not exist yet.';


CREATE FUNCTION "trend_directory"."create_stats_on_creation"()
    RETURNS trigger
AS $$
BEGIN
  INSERT INTO trend_directory.trend_store_part_stats (trend_store_part_id, timestamp, modified, count)
    VALUES (NEW.trend_store_part_id, NEW.timestamp, '2000-01-01 00:00:00+02', 1);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION "trend_directory"."transfer"("materialization" trend_directory.view_materialization, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    columns_part text;
    row_count integer;
    job_id integer;
BEGIN
    SELECT logging.start_job(format('{"view_materialization": "%s", "timestamp": "%s"}', m::text, $2::text)::jsonb) INTO job_id
    FROM trend_directory.materialization m WHERE id = $1.materialization_id;

    SELECT trend_directory.columns_part($1) INTO columns_part;

    EXECUTE format(
        'INSERT INTO trend.%I (entity_id, timestamp, created, job_id, %s) SELECT entity_id, timestamp, now(), %s, %s FROM %s WHERE timestamp = $1',
        (trend_directory.dst_trend_store_part($1)).name,
        columns_part,
        job_id,
        columns_part,
        $1.src_view::name
    ) USING timestamp;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    PERFORM logging.end_job(job_id);

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."transfer"("materialization" trend_directory.view_materialization, "timestamp" timestamp with time zone) IS 'Transfer all records of the specified timestamp from the view to the target trend store of the materialization.';


CREATE OR REPLACE FUNCTION "trend_directory"."transfer"("materialization" trend_directory.function_materialization, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    columns_part text;
    row_count integer;
    job_id integer;
BEGIN
    SELECT logging.start_job(format('{"function_materialization": "%s", "timestamp": "%s"}', m::text, $2::text)::jsonb) INTO job_id
    FROM trend_directory.materialization m WHERE id = $1.materialization_id;

    SELECT trend_directory.columns_part($1) INTO columns_part;

    EXECUTE format(
        'INSERT INTO trend.%I (entity_id, timestamp, created, job_id, %s) SELECT entity_id, timestamp, now(), %s, %s FROM %s($1)',
        (trend_directory.dst_trend_store_part($1)).name,
        columns_part,
        job_id,
        columns_part,
        $1.src_function::regproc
    ) USING timestamp;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    PERFORM logging.end_job(job_id);

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TRIGGER create_stats_on_creation
  AFTER INSERT ON "trend_directory"."modified"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."create_stats_on_creation"();
