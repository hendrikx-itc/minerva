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


CREATE FUNCTION "trend_directory"."base_table_name_by_trend_store_part_id"("trend_store_part_id" integer)
    RETURNS name
AS $$
SELECT name FROM trend_directory.trend_store_part
  WHERE id = $1;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE VIEW "trend_directory"."trend_store_part_stats_to_update" AS
SELECT tsps.trend_store_part_id,
    tsps.timestamp
  FROM trend_directory.trend_store_part_stats tsps
  JOIN trend_directory.modified m
  ON tsps.trend_store_part_id = m.trend_store_part_id
    AND tsps.timestamp = m.timestamp
  WHERE tsps.modified < m.last;


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


CREATE TRIGGER create_stats_on_creation
  AFTER INSERT ON "trend_directory"."modified"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."create_stats_on_creation"();


ALTER TABLE "trend_directory"."trend_store_part_stats"
  ADD CONSTRAINT "trend_store_part_stats_trend_store_part_id_fkey"
  FOREIGN KEY (trend_store_part_id)
  REFERENCES "trend_directory"."trend_store_part" (id) ON DELETE CASCADE;
