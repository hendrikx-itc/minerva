

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,1,6)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


DROP FUNCTION "relation_directory"."remove"(name);

CREATE FUNCTION "relation_directory"."remove"(name)
    RETURNS text
AS $$
DECLARE
  result text;
BEGIN
  SELECT name FROM relation_directory.type WHERE name = $1 INTO result;
  PERFORM public.action(format('DROP MATERIALIZED VIEW IF EXISTS relation.%I', $1));
  DELETE FROM relation_directory.type WHERE name = $1;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


DROP FUNCTION "trend_directory"."assure_table_trends_exist"(trend_directory.trend_store_part, trend_directory.trend_descr[], trend_directory.generated_trend_descr[]);

DROP FUNCTION "trend_directory"."add_trends"(trend_directory.trend_store, trend_directory.trend_store_part_descr[]);

DROP FUNCTION "trend_directory"."get_trend_if_defined"(trend_directory.table_trend, trend_directory.trend_descr[], text);

DROP FUNCTION "trend_directory"."remove_trend_if_extraneous"(trend_directory.table_trend, trend_directory.trend_store_part_descr[]);

DROP FUNCTION "trend_directory"."remove_extra_trends"(trend_directory.trend_store, trend_directory.trend_store_part_descr[]);

DROP FUNCTION "trend_directory"."change_table_trend_data_unsafe"(trend_directory.table_trend, text, text, text);

DROP FUNCTION "trend_directory"."change_table_trend_data_safe"(trend_directory.table_trend, text, text, text);

DROP FUNCTION "trend_directory"."change_trend_data_unsafe"(trend_directory.table_trend, trend_directory.trend_descr[], text);

DROP FUNCTION "trend_directory"."change_trend_data_safe"(trend_directory.table_trend, trend_directory.trend_descr[], text);

DROP FUNCTION "trend_directory"."change_all_trend_data"(trend_directory.trend_store, trend_directory.trend_store_part_descr[]);

DROP FUNCTION "trend_directory"."change_trend_data_upward"(trend_directory.trend_store, trend_directory.trend_store_part_descr[]);

DROP FUNCTION "trend_directory"."change_trendstore_strong"(trend_directory.trend_store, trend_directory.trend_store_part_descr[]);

DROP FUNCTION "trend_directory"."change_trendstore_weak"(trend_directory.trend_store, trend_directory.trend_store_part_descr[]);

ALTER TABLE "trend_directory"."materialization_state" ADD COLUMN "max_modified" timestamp with time zone;


CREATE FUNCTION "trend_directory"."cleanup_for_materialization"()
    RETURNS trigger
AS $$
BEGIN
  EXECUTE format(
    'DROP FUNCTION trend.%I(timestamp with time zone)',
    trend_directory.fingerprint_function_name(OLD)
  );

  RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."cleanup_for_view_materialization"()
    RETURNS trigger
AS $$
BEGIN
    EXECUTE format('DROP VIEW %s', OLD.src_view);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."undefine_materialization"("name" name)
    RETURNS void
AS $$
DELETE FROM trend_directory.materialization
WHERE materialization::text = $1;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."undefine_materialization"("name" name) IS 'Undefine and remove a materialization';


CREATE FUNCTION "trend_directory"."cleanup_for_function_materialization"()
    RETURNS trigger
AS $$
BEGIN
    EXECUTE format('DROP FUNCTION %s', OLD.src_function);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."max_modified"(trend_directory.materialization, timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
SELECT max(last) FROM trend_directory.modified
  WHERE trend_store_part_id = $1.dst_trend_store_part_id
  AND timestamp < $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."fingerprint_function_name"(trend_directory.materialization)
    RETURNS name
AS $$
SELECT format('%s_fingerprint', $1::text)::name;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."get_partition_size"(trend_directory.trend_store_part)
    RETURNS interval
AS $$
SELECT partition_size FROM trend_directory.trend_store WHERE trend_store.id = $1.trend_store_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."create_partition"(trend_directory.trend_store_part, timestamp with time zone)
    RETURNS trend_directory.partition
AS $$
SELECT trend_directory.create_partition($1, trend_directory.timestamp_to_index(trend_directory.get_partition_size($1), $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."get_trend_store_id"(trend_directory.trend_store)
    RETURNS integer
AS $$
SELECT $1.id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."delete_trend_store"("data_source_name" text, "entity_type_name" text, "granularity" interval)
    RETURNS void
AS $$
SELECT trend_directory.delete_trend_store((trend_directory.get_trend_store($1, $2, $3)).id);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."get_trend_store_part_id"(trend_directory.trend_store_part)
    RETURNS integer
AS $$
SELECT $1.id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."assure_table_trends_exist"(trend_directory.trend_store_part, trend_directory.trend_descr[], trend_directory.generated_trend_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
BEGIN
  CREATE TEMP TABLE missing_trends(trend trend_directory.trend_descr);
  CREATE TEMP TABLE missing_generated_trends(trend trend_directory.generated_trend_descr);

  -- Normal trends
  INSERT INTO missing_trends SELECT trend_directory.missing_table_trends($1, $2);

  IF EXISTS (SELECT * FROM missing_trends LIMIT 1) THEN
    PERFORM trend_directory.create_table_trends($1, ARRAY(SELECT trend FROM missing_trends));
  END IF;

  -- Generated trends
  INSERT INTO missing_generated_trends SELECT trend_directory.missing_generated_table_trends($1, $3);

  IF EXISTS (SELECT * FROM missing_generated_trends LIMIT 1) THEN
    PERFORM trend_directory.create_generated_table_trends($1, missing_generated_trends);
  END IF;

  SELECT ARRAY(SELECT (mt).trend.name FROM missing_trends mt UNION SELECT (mt).trend.name FROM missing_generated_trends mt) INTO result;
  DROP TABLE missing_trends;
  DROP TABLE missing_generated_trends;

  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."add_trends"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
SELECT trend_directory.assure_table_trends_exist(
  trend_directory.get_or_create_trend_store_part($1.id, name),
  trends,
  generated_trends
)
FROM unnest($2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."get_trend_if_defined"("trend" trend_directory.table_trend, "trends" trend_directory.trend_descr[])
    RETURNS name
AS $$
SELECT t.name FROM trend_directory.table_trend t JOIN unnest($2) t2
  ON t.name = t2.name WHERE t.id = $1.id
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."get_trend_if_defined"("trend" trend_directory.table_trend, "trends" trend_directory.trend_descr[]) IS 'Return the trend, but only if it is a trend defined by trends';


CREATE FUNCTION "trend_directory"."remove_trend_if_extraneous"("trend" trend_directory.table_trend, "trends" trend_directory.trend_descr[])
    RETURNS text
AS $$
DECLARE
  result text;
  defined_trend name;
BEGIN
  SELECT trend_directory.get_trend_if_defined($1, $2) INTO defined_trend;
  IF defined_trend IS NULL THEN
    SELECT $1.name INTO result;
    PERFORM trend_directory.remove_table_trend($1);
  END IF;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."remove_trend_if_extraneous"("trend" trend_directory.table_trend, "trends" trend_directory.trend_descr[]) IS 'Remove the trend if it is not one that is described by trends';


CREATE FUNCTION "trend_directory"."remove_extra_trends"(trend_directory.trend_store_part, trend_directory.trend_descr[])
    RETURNS text[]
AS $$
DECLARE
  trend trend_directory.table_trend;
  removal_result text;
  result text[];
BEGIN
  FOR trend IN SELECT * FROM trend_directory.get_trends_for_trend_store_part($1)
  LOOP
    SELECT trend_directory.remove_trend_if_extraneous(trend, $2) INTO removal_result;
    IF removal_result IS NOT NULL THEN
      SELECT result || removal_result INTO result;
    END IF;
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."remove_extra_trends"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
  partresult text[];
BEGIN
  FOR partresult IN
    SELECT trend_directory.remove_extra_trends(
      trend_directory.get_trend_store_part($1.id, name), trends)
    FROM unnest($2)
  LOOP
    SELECT result || partresult INTO result;
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."change_table_trend_data_unsafe"(trend_directory.table_trend, "data_type" text, "entity_aggregation" text, "time_aggregation" text)
    RETURNS text
AS $$
DECLARE
  result text;
BEGIN
  IF $1.data_type <> $2 OR $1.entity_aggregation <> $3 OR $1.time_aggregation <> $4
  THEN
    UPDATE trend_directory.table_trend SET
      data_type = $2,
      entity_aggregation = $3,
      time_aggregation = $4
    WHERE id = $1.id;
    EXECUTE format('ALTER TABLE trend.%I ALTER %I TYPE %s USING CAST(%I AS %s)',
      trend_directory.trend_store_part_name_for_trend($1),
      $1.name,
      $2,
      $1.name,
      $2);
    SELECT $1.name INTO result;
  END IF;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."change_table_trend_data_safe"(trend_directory.table_trend, "data_type" text, "entity_aggregation" text, "time_aggregation" text)
    RETURNS text
AS $$
SELECT trend_directory.change_table_trend_data_unsafe(
  $1,
  trend_directory.greatest_data_type($2, $1.data_type),
  $3,
  $4);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trend_data_unsafe"("trend" trend_directory.table_trend, "trends" trend_directory.trend_descr[], "partname" text)
    RETURNS text
AS $$
SELECT trend_directory.change_table_trend_data_unsafe($1, t.data_type, t.entity_aggregation, t.time_aggregation)
  FROM unnest($2) t
  WHERE t.name = $1.name AND trend_directory.trend_store_part_name_for_trend($1) = $3;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trend_data_safe"("trend" trend_directory.table_trend, "trends" trend_directory.trend_descr[], "partname" text)
    RETURNS text
AS $$
SELECT trend_directory.change_table_trend_data_safe($1, t.data_type, t.entity_aggregation, t.time_aggregation)
  FROM unnest($2) t
  WHERE t.name = $1.name AND trend_directory.trend_store_part_name_for_trend($1) = $3;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."change_all_trend_data"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
  partresult text;
BEGIN
  FOR partresult IN
    SELECT trend_directory.change_trend_data_unsafe(
      trend_directory.get_trends_for_trend_store($1), trends, name)
    FROM unnest($2)
  LOOP
    IF partresult IS NOT null THEN
      SELECT result || partresult INTO result;
    END IF;
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trend_data_upward"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
  partresult text;
BEGIN
  FOR partresult IN
    SELECT trend_directory.change_trend_data_safe(
      trend_directory.get_trends_for_trend_store($1), trends, name)
    FROM unnest($2)
  LOOP
    IF partresult IS NOT null THEN
      SELECT result || partresult INTO result;
    END IF;
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trendstore_strong"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
  partresult text[];
BEGIN
  SELECT trend_directory.add_trends($1, $2) INTO partresult;
  IF array_ndims(partresult) > 0
  THEN
    SELECT result || ARRAY['added trends:'] || partresult INTO result;
  ELSE
    SELECT result || ARRAY['no trends added'] INTO result;
  END IF;
  
  SELECT trend_directory.remove_extra_trends($1, $2) INTO partresult;
  IF array_ndims(partresult) > 0
  THEN
    SELECT result || ARRAY['removed trends:'] || partresult INTO result;
  ELSE
    SELECT result || ARRAY['no trends removed'] INTO result;
  END IF;

  SELECT trend_directory.change_all_trend_data($1, $2) INTO partresult;
  IF array_ndims(partresult) > 0
  THEN
    SELECT result || ARRAY['changed trends:'] || partresult INTO result;
  ELSE
    SELECT result || ARRAY['no trends changed'] INTO result;
  END IF;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trendstore_weak"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
  partresult text[];
BEGIN
  SELECT trend_directory.add_trends($1, $2) INTO partresult;
  IF array_ndims(partresult) > 0
  THEN
    SELECT result || ARRAY['added trends:'] || partresult INTO result;
  ELSE
    SELECT result || ARRAY['no trends added'] INTO result;
  END IF;
  
  SELECT trend_directory.remove_extra_trends($1, $2) INTO partresult;
  IF array_ndims(partresult) > 0
  THEN
    SELECT result || ARRAY['removed trends:'] || partresult INTO result;
  ELSE
    SELECT result || ARRAY['no trends removed'] INTO result;
  END IF;

  SELECT trend_directory.change_trend_data_upward($1, $2) INTO partresult;
  IF array_ndims(partresult) > 0
  THEN
    SELECT result || ARRAY['changed trends:'] || partresult INTO result;
  ELSE
    SELECT result || ARRAY['no trends changed'] INTO result;
  END IF;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."get_table_name_for_trend"("trend" text, "entity" text, "granularity" interval)
    RETURNS name
AS $$
SELECT tsp.name FROM trend_directory.table_trend t
  JOIN trend_directory.trend_store_part tsp ON tsp.id = t.trend_store_part_id
  JOIN trend_directory.trend_store ts ON ts.id = tsp.trend_store_id
  JOIN directory.entity_type et ON et.id = ts.entity_type_id
  WHERE t.name = $1
    AND ts.granularity = $3
    AND et.name = $2;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION "trend_directory"."update_source_fingerprint"(trend_directory.materialization, timestamp with time zone)
    RETURNS void
AS $$
INSERT INTO trend_directory.materialization_state(materialization_id, timestamp, source_fingerprint, max_modified, processed_fingerprint, job_id)
VALUES ($1.id, $2, (trend_directory.source_fingerprint($1, $2)).body, trend_directory.max_modified($1, $2), null, null)
ON CONFLICT ON CONSTRAINT materialization_state_pkey DO UPDATE SET source_fingerprint = (trend_directory.source_fingerprint($1, $2)).body, max_modified = trend_directory.max_modified($1, $2);
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."update_source_fingerprint"(trend_directory.materialization, timestamp with time zone) IS 'Update the fingerprint of the sources in the materialization_state table.';


CREATE OR REPLACE FUNCTION "trend_directory"."create_base_table_sql"(trend_directory.trend_store_part)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE TABLE %I.%I ('
        'entity_id integer NOT NULL, '
        '"timestamp" timestamp with time zone NOT NULL, '
        'created timestamp with time zone NOT NULL, '
        '%s'
        ') PARTITION BY RANGE ("timestamp");',
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1),
        array_to_string(ARRAY['job_id bigint NOT NULL'] || trend_directory.column_specs($1), ',')
    ),
    format(
        'ALTER TABLE %I.%I ADD PRIMARY KEY (entity_id, "timestamp");',
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1)
    ),
    format(
        'CREATE INDEX ON %I.%I USING btree (job_id)',
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1)
    ),
    format(
        'CREATE INDEX ON %I.%I USING btree (timestamp);',
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1)
    ),
    format(
        'GRANT SELECT ON TABLE %I.%I TO minerva;',
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1)
    ),
    format(
        'GRANT INSERT,DELETE,UPDATE ON TABLE %I.%I TO minerva_writer;',
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1)
    )
];
$$ LANGUAGE sql STABLE STRICT;


CREATE OR REPLACE FUNCTION "trend_directory"."create_staging_table_sql"(trend_directory.trend_store_part)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE UNLOGGED TABLE %I.%I (entity_id integer, "timestamp" timestamp with time zone, created timestamp with time zone, job_id integer%s);',
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name($1),
        (
            SELECT string_agg(format(', %I %s', t.name, t.data_type), ' ')
            FROM trend_directory.table_trend t
            WHERE t.trend_store_part_id = $1.id
        )
    ),
    format(
        'ALTER TABLE ONLY %I.%I ADD PRIMARY KEY (entity_id, "timestamp");',
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name($1)
    ),
    format(
        'GRANT SELECT ON TABLE %I.%I TO minerva;',
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name($1)
    ),
    format(
        'GRANT INSERT,DELETE,UPDATE ON TABLE %I.%I TO minerva_writer;',
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name($1)
    )
];
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION "trend_directory"."get_trend_store_parts"("trend_store_id" integer)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT trend_store_part FROM trend_directory.trend_store_part WHERE trend_store_id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION "trend_directory"."alter_trend_name"(trend_directory.trend_store_part, "trend_name" name, "new_name" name)
    RETURNS trend_directory.trend_store_part
AS $$
UPDATE trend_directory.table_trend
  SET name = $3
  WHERE trend_store_part_id = $1.id AND name = $2
  RETURNING $1;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION "trend_directory"."get_trends_for_trend_store"("trend_store_id" integer)
    RETURNS SETOF trend_directory.table_trend
AS $$
SELECT table_trend
  FROM trend_directory.table_trend
  LEFT JOIN trend_directory.trend_store_part
  ON table_trend.trend_store_part_id = trend_store_part.id
  WHERE trend_store_part.trend_store_id = $1;
$$ LANGUAGE sql STABLE;


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

    PERFORM logging.end_job(job_id);

    GET DIAGNOSTICS row_count = ROW_COUNT;

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

    PERFORM logging.end_job(job_id);

    GET DIAGNOSTICS row_count = ROW_COUNT;

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION "trend_directory"."changes_on_trend_update"()
    RETURNS trigger
AS $$
DECLARE
    base_table_name text;
BEGIN
    IF NEW.name <> OLD.name THEN
        FOR base_table_name IN
            SELECT trend_directory.base_table_name(trend_store_part)
            FROM trend_directory.table_trend
            JOIN trend_directory.trend_store_part ON table_trend.trend_store_part_id = trend_store_part.id
            WHERE table_trend.id = NEW.id
        LOOP
            EXECUTE format('ALTER TABLE trend.%I RENAME COLUMN %I TO %I', base_table_name, OLD.name, NEW.name);
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


DROP FUNCTION "attribute_directory"."greatest_data_type"(varchar, varchar);

DROP FUNCTION "attribute_directory"."update_compacted"(integer, timestamp with time zone);

DROP FUNCTION "attribute_directory"."store_compacted"(integer, timestamp with time zone);

DROP FUNCTION "attribute_directory"."mark_compacted"(integer, timestamp with time zone);

DROP FUNCTION "attribute_directory"."mark_compacted"(integer);

ALTER TABLE "attribute_directory"."attribute_store_compacted" DROP COLUMN "compacted";
ALTER TABLE "attribute_directory"."attribute_store_compacted" ADD COLUMN "compacted" integer NOT NULL;


CREATE FUNCTION "attribute_directory"."get_attribute_store"("data_source" text, "entity_type" text)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_store
FROM attribute_directory.attribute_store
LEFT JOIN directory.data_source
  ON data_source_id = data_source.id
LEFT JOIN directory.entity_type
  ON entity_type_id = entity_type.id
WHERE data_source.name = $1 AND lower(entity_type.name) = lower($2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."get_attribute_store"("attribute_store_id" integer)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_store
FROM attribute_directory.attribute_store
WHERE id = $1

$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."to_compact_view_name"(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_to_compact')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."last_history_id"("attribute_store_id" integer)
    RETURNS integer
AS $$
DECLARE
  result integer;
BEGIN
  EXECUTE FORMAT(
    'SELECT COALESCE(MAX(id), 0) FROM attribute_history.%I', 
    attribute_directory.to_table_name(attribute_directory.get_attribute_store($1))
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "attribute_directory"."update_compacted"("attribute_store_id" integer, "compacted" integer)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
UPDATE attribute_directory.attribute_store_compacted
  SET compacted = greatest(compacted, $2)
  WHERE attribute_store_id = $1
RETURNING attribute_store_compacted;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."store_compacted"("attribute_store_id" integer, "compacted" integer)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
INSERT INTO attribute_directory.attribute_store_compacted (attribute_store_id, compacted)
VALUES ($1, $2)
RETURNING attribute_store_compacted;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."mark_compacted"("attribute_store_id" integer, "compacted" integer)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
SELECT COALESCE(attribute_directory.update_compacted($1, $2), attribute_directory.store_compacted($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."to_compact_view_query"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT FORMAT(
  'SELECT entity_id, MIN(id) AS first_id '
  'FROM attribute_history.%I '
  'WHERE id > attribute_directory.last_compacted(%s) '
  'GROUP BY entity_id',
  attribute_directory.to_table_name($1),
  $1.id
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."create_to_compact_view_sql"(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE VIEW attribute_history.%I AS %s',
        attribute_directory.to_compact_view_name($1),
        attribute_directory.to_compact_view_query($1)
    ),
    format(
        'ALTER TABLE attribute_history.%I OWNER TO minerva_writer',
        attribute_directory.to_compact_view_name($1)
    )
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."create_to_compact_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_to_compact_view_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_to_compact_view_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format('DROP VIEW attribute_history.%I', attribute_directory.to_compact_view_name($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_to_compact_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.drop_to_compact_view_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."insert_into_compacted_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT FORMAT(
  'INSERT INTO attribute_directory.attribute_store_compacted '
  '(attribute_store_id, compacted) '
  'VALUES (%s, 0)',
  $1.id
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."remove_from_compacted_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT FORMAT(
  'DELETE FROM attribute_directory.attribute_store_compacted '
  'WHERE attribute_store_id = %s',
  $1.id
);
  
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."insert_into_compacted"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.insert_into_compacted_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."remove_from_compacted"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.remove_from_compacted_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."last_compacted"("attribute_store_id" integer)
    RETURNS integer
AS $$
SELECT COALESCE(compacted, 0) FROM attribute_directory.attribute_store_compacted WHERE attribute_store_id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."compact"(attribute_directory.attribute_store, "max_compacting" integer)
    RETURNS attribute_directory.attribute_store
AS $$
DECLARE
    last_to_compact integer;
    table_name name := attribute_directory.to_table_name($1);
    compacted_tmp_table_name name := table_name || '_compacted_tmp';
    compacted_view_name name := attribute_directory.compacted_view_name($1);
    to_compact_name name := attribute_directory.to_compact_view_name($1);
    default_columns text[] := ARRAY['id', 'entity_id', 'timestamp', '"end"', 'first_appearance', 'modified', 'hash'];
    extended_default_columns text[] := ARRAY[
        format('%I.id', compacted_view_name), format('%I.entity_id', compacted_view_name), 'timestamp', '"end"', 'first_appearance', 'modified', 'hash'
    ];
    attribute_columns text[];
    columns_part text;
    extended_columns_part text;
    row_count integer;
BEGIN
    SELECT attribute_directory.last_compacted($1.id) + max_compacting INTO last_to_compact;
    IF max_compacting = 0 OR attribute_directory.last_history_id($1.id) < last_to_compact
        THEN last_to_compact = attribute_directory.last_history_id($1.id);
    END IF;
    
    SELECT array_agg(quote_ident(name)) INTO attribute_columns
        FROM attribute_directory.attribute
        WHERE attribute_store_id = $1.id;
       
    columns_part = array_to_string(default_columns || attribute_columns, ',');
    extended_columns_part = array_to_string(extended_default_columns || attribute_columns, ',');
    EXECUTE format(
        'TRUNCATE attribute_history.%I',
        compacted_tmp_table_name
    );

    EXECUTE format(
        'INSERT INTO attribute_history.%I(%s) '
             'SELECT %s FROM attribute_history.%I '
             'JOIN attribute_history.%I '
             'ON %I.entity_id = %I.entity_id '
             'WHERE first_id <= %s;',
        compacted_tmp_table_name, columns_part,
        extended_columns_part,
        compacted_view_name, to_compact_name,
        compacted_view_name, to_compact_name,
        last_to_compact
    );

    EXECUTE format(
        'UPDATE attribute_history.%I SET modified = now()',
        compacted_tmp_table_name
    );

    GET DIAGNOSTICS row_count = ROW_COUNT;

    RAISE NOTICE 'compacted % rows', row_count;

    EXECUTE format(
        'UPDATE attribute_history.%I '
        'SET "end" = "timestamp" '
        'WHERE "end" IS NULL;',
        table_name
    );

    EXECUTE format(
        'DELETE FROM attribute_history.%I history '
        'USING attribute_history.%I tmp '
        'WHERE '
             'history.entity_id = tmp.entity_id AND '
             'history.timestamp >= tmp.timestamp AND '
             'history.timestamp <= tmp."end";',
        table_name, compacted_tmp_table_name
    );

    columns_part = array_to_string(
        ARRAY['id', 'entity_id', 'timestamp', '"end"', 'first_appearance', 'modified', 'hash'] || attribute_columns,
        ','
    );

    EXECUTE format(
        'INSERT INTO attribute_history.%I(%s) '
        'SELECT %s '
        'FROM attribute_history.%I',
        table_name, columns_part,
        columns_part,
        compacted_tmp_table_name
    );

    PERFORM attribute_directory.mark_compacted($1.id, last_to_compact);

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "attribute_directory"."compact"(attribute_directory.attribute_store, "max_compacting" integer) IS 'Remove at most max_compacting subsequent records with duplicate attribute values and update the modified of the first';


CREATE OR REPLACE FUNCTION "attribute_directory"."run_length_view_query"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format('SELECT
    min(id) AS id,
    public.first(entity_id) AS entity_id,
    min(timestamp) AS "start",
    max(timestamp) AS "end",
    min(first_appearance) AS first_appearance,
    max(modified) AS modified,
    count(*) AS run_length
FROM
(
    SELECT id, entity_id, timestamp, first_appearance, modified, sum(change) OVER w2 AS run
    FROM
    (
        SELECT id, entity_id, timestamp, first_appearance, modified, CASE WHEN hash <> lag(hash) OVER w THEN 1 ELSE 0 END AS change
        FROM attribute_history.%I
        WINDOW w AS (PARTITION BY entity_id ORDER BY timestamp asc)
    ) t
    WINDOW w2 AS (PARTITION BY entity_id ORDER BY timestamp ASC)
) runs
GROUP BY entity_id, run;', attribute_directory.to_table_name($1));
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION "attribute_directory"."curr_view_query"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'SELECT h.* FROM attribute_history.%I h JOIN attribute_history.%I c ON h.id = c.id',
    attribute_directory.to_table_name($1),
    attribute_directory.curr_ptr_table_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION "attribute_directory"."create_curr_ptr_table_sql"(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format('CREATE TABLE attribute_history.%I (
        id integer,
        PRIMARY KEY (id))',
        attribute_directory.curr_ptr_table_name($1)
    ),
    format(
        'CREATE INDEX ON attribute_history.%I (id)',
        attribute_directory.curr_ptr_table_name($1)
    ),
    format(
        'ALTER TABLE attribute_history.%I OWNER TO minerva_writer',
        attribute_directory.curr_ptr_table_name($1)
    ),
    format(
        'GRANT SELECT ON TABLE attribute_history.%I TO minerva',
        attribute_directory.curr_ptr_table_name($1)
    )
];
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION "attribute_directory"."create_curr_ptr_view_sql"(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
DECLARE
    table_name name := attribute_directory.to_table_name($1);
    view_name name := attribute_directory.curr_ptr_view_name($1);
    view_sql text;
BEGIN
    view_sql = format(
        'SELECT DISTINCT ON (entity_id) '
        'id '
        'FROM attribute_history.%I '
        'ORDER BY entity_id, timestamp DESC',
        table_name
    );

    RETURN ARRAY[
        format('CREATE VIEW attribute_history.%I AS %s', view_name, view_sql),
        format(
            'ALTER TABLE attribute_history.%I '
            'OWNER TO minerva_writer',
            view_name
        ),
        format('GRANT SELECT ON TABLE attribute_history.%I TO minerva', view_name)
    ];
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION "attribute_directory"."base_columns"()
    RETURNS text[]
AS $$
SELECT ARRAY[
    'entity_id integer NOT NULL',
    '"timestamp" timestamp with time zone NOT NULL',
    '"end" timestamp with time zone DEFAULT NULL'
];
$$ LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION "attribute_directory"."create_history_table_sql"(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE TABLE attribute_history.%I (
        id integer GENERATED BY DEFAULT AS IDENTITY,
        first_appearance timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
        modified timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
        hash character varying,
        PRIMARY KEY (id)
        ) INHERITS (attribute_base.%I)', attribute_directory.to_table_name($1), attribute_directory.to_table_name($1)
    ),
    format(
        'CREATE INDEX ON attribute_history.%I (id)',
        attribute_directory.to_table_name($1)
    ),
    format(
        'CREATE INDEX ON attribute_history.%I (first_appearance)',
        attribute_directory.to_table_name($1)
    ),
    format(
        'CREATE INDEX ON attribute_history.%I (modified)',
        attribute_directory.to_table_name($1)
    ),
    format(
        'ALTER TABLE attribute_history.%I OWNER TO minerva_writer',
        attribute_directory.to_table_name($1)
    ),
    format(
        'GRANT SELECT ON TABLE attribute_history.%I TO minerva',
        attribute_directory.to_table_name($1)
    )
];
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION "attribute_directory"."check_attribute_types"(attribute_directory.attribute_store, attribute_directory.attribute_descr[])
    RETURNS SETOF attribute_directory.attribute
AS $$
UPDATE attribute_directory.attribute SET data_type = n.data_type
FROM unnest($2) n
WHERE attribute.name = n.name
AND attribute.attribute_store_id = $1.id
AND attribute.data_type <> trend_directory.greatest_data_type(n.data_type, attribute.data_type)
RETURNING attribute.*;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION "attribute_directory"."create_compacted_tmp_table_sql"(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE UNLOGGED TABLE attribute_history.%I ('
        '    id integer,'
        '    "end" timestamp with time zone,'
        '    first_appearance timestamp with time zone,'
        '    modified timestamp with time zone,'
        '    hash text'
        ') INHERITS (attribute_base.%I)',
        attribute_directory.compacted_tmp_table_name($1),
        attribute_directory.to_table_name($1)
    ),
    format(
        'CREATE INDEX ON attribute_history.%I '
        'USING btree (entity_id, timestamp)',
        attribute_directory.compacted_tmp_table_name($1)
    ),
    format(
        'ALTER TABLE attribute_history.%I '
        'OWNER TO minerva_writer',
        attribute_directory.compacted_tmp_table_name($1)
    )
];
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION "attribute_directory"."compacted_view_query"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'SELECT %s '
    'FROM attribute_history.%I rl '
    'JOIN attribute_history.%I history ON history.entity_id = rl.entity_id AND history.timestamp = rl.start '
    'WHERE run_length > 1',
    array_to_string(
        ARRAY['rl.id', 'rl.entity_id', 'rl.start AS timestamp', 'rl."end"', 'rl.first_appearance', 'rl.modified', 'history.hash'] || array_agg(quote_ident(name)),
        ', '
    ),
    attribute_directory.run_length_view_name($1),
    attribute_directory.to_table_name($1)
)
FROM attribute_directory.attribute
WHERE attribute_store_id = $1.id;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION "attribute_directory"."requires_compacting"("attribute_store_id" integer)
    RETURNS bool
AS $$
DECLARE
  result bool;
BEGIN
  SELECT attribute_directory.last_history_id($1) > compacted
    FROM attribute_directory.attribute_store_compacted
    WHERE attribute_store_compacted.attribute_store_id = $1
  INTO result;
  RETURN COALESCE(result, attribute_directory.last_history_id($1) > 0);
END;
$$ LANGUAGE plpgsql STABLE;


CREATE OR REPLACE FUNCTION "attribute_directory"."compact"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_directory.compact($1, 0);
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "attribute_directory"."compact"(attribute_directory.attribute_store) IS 'Remove all subsequent records with duplicate attribute values and update the modified of the first';


CREATE OR REPLACE FUNCTION "attribute_directory"."materialize_curr_ptr"(attribute_directory.attribute_store)
    RETURNS integer
AS $$
DECLARE
    table_name name := attribute_directory.curr_ptr_table_name($1);
    view_name name := attribute_directory.curr_ptr_view_name($1);
    row_count integer;
BEGIN
    IF attribute_directory.requires_compacting($1) THEN
        PERFORM attribute_directory.compact($1);
    END IF;

    EXECUTE format('TRUNCATE attribute_history.%I', table_name);
    EXECUTE format(
        'INSERT INTO attribute_history.%I (id) '
        'SELECT id '
        'FROM attribute_history.%I', table_name, view_name
    );

    GET DIAGNOSTICS row_count = ROW_COUNT;

    PERFORM attribute_directory.mark_curr_materialized($1.id);

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION "attribute_directory"."create_at_func_ptr_sql"(attribute_directory.attribute_store)
    RETURNS text[]
AS $function$
SELECT ARRAY[
        format(
            'CREATE FUNCTION attribute_history.%I(timestamp with time zone)
RETURNS TABLE(id integer)
AS $$
    SELECT DISTINCT ON (entity_id)
        id
    FROM
        attribute_history.%I
    WHERE timestamp <= $1
    ORDER BY entity_id, timestamp DESC;
$$ LANGUAGE sql STABLE',
            attribute_directory.at_ptr_function_name($1),
            attribute_directory.to_table_name($1)
        ),
        format(
            'ALTER FUNCTION attribute_history.%I(timestamp with time zone) '
            'OWNER TO minerva_writer',
            attribute_directory.at_ptr_function_name($1)
        )
    ];
$function$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION "attribute_directory"."create_entity_at_func_ptr_sql"(attribute_directory.attribute_store)
    RETURNS text[]
AS $function$
SELECT ARRAY[
    format(
        'CREATE FUNCTION attribute_history.%I(entity_id integer, timestamp with time zone)
RETURNS integer
AS $$
    SELECT id
    FROM
        attribute_history.%I
    WHERE timestamp <= $2 AND entity_id = $1
    ORDER BY timestamp DESC LIMIT 1;
$$ LANGUAGE sql STABLE',
        attribute_directory.at_ptr_function_name($1),
        attribute_directory.to_table_name($1)
    ),
    format(
        'ALTER FUNCTION attribute_history.%I(entity_id integer, timestamp with time zone) '
        'OWNER TO minerva_writer',
        attribute_directory.at_ptr_function_name($1)
    )
];
$function$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION "attribute_directory"."create_at_func"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $function$
SELECT public.action(
    $1,
    format(
        'CREATE FUNCTION attribute_history.%I(timestamp with time zone)
        RETURNS SETOF attribute_history.%I
        AS $$
            SELECT a.*
            FROM
                attribute_history.%I a
            JOIN
                attribute_HISTORY.%I($1) at
            ON at.id = a.id
        $$ LANGUAGE sql STABLE;',
        attribute_directory.at_function_name($1),
        attribute_directory.to_table_name($1),
        attribute_directory.to_table_name($1),
        attribute_directory.at_ptr_function_name($1)
    )
);

SELECT public.action(
    $1,
    format(
        'ALTER FUNCTION attribute_history.%I(timestamp with time zone) '
        'OWNER TO minerva_writer',
        attribute_directory.at_function_name($1)
    )
);
$function$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION "attribute_directory"."create_entity_at_func_sql"(attribute_directory.attribute_store)
    RETURNS text[]
AS $function$
SELECT ARRAY[
        format(
            'CREATE FUNCTION attribute_history.%I(entity_id integer, timestamp with time zone)
    RETURNS attribute_history.%I
AS $$
SELECT *
FROM
    attribute_history.%I
WHERE id = attribute_history.%I($1, $2);
$$ LANGUAGE sql STABLE;',
            attribute_directory.at_function_name($1),
            attribute_directory.to_table_name($1),
            attribute_directory.to_table_name($1),
            attribute_directory.at_ptr_function_name($1)
        ),
        format(
            'ALTER FUNCTION attribute_history.%I(entity_id integer, timestamp with time zone) '
            'OWNER TO minerva_writer',
            attribute_directory.at_function_name($1)
        )
    ];
$function$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION "attribute_directory"."create_dependees"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_directory.create_hash_function($1);
SELECT attribute_directory.create_staging_new_view($1);
SELECT attribute_directory.create_staging_modified_view($1);
SELECT attribute_directory.create_curr_ptr_view($1);
SELECT attribute_directory.create_curr_view($1);
SELECT attribute_directory.create_compacted_view($1);
SELECT attribute_directory.create_to_compact_view($1);
SELECT attribute_directory.insert_into_compacted($1);
SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION "attribute_directory"."drop_dependees"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_directory.drop_to_compact_view($1);
SELECT attribute_directory.drop_compacted_view($1);
SELECT attribute_directory.drop_curr_view($1);
SELECT attribute_directory.drop_curr_ptr_view($1);
SELECT attribute_directory.drop_staging_modified_view($1);
SELECT attribute_directory.drop_staging_new_view($1);
SELECT attribute_directory.drop_hash_function($1);
SELECT attribute_directory.remove_from_compacted($1);
SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION "trigger"."create_trigger_notification_store"(name)
    RETURNS notification_directory.notification_store
AS $$
SELECT trigger.add_insert_trigger(
        notification_directory.create_notification_store($1, ARRAY[
            ('created', 'timestamp with time zone', 'time of notification creation'),
            ('rule_id', 'integer', 'source rule for this notification'),
            ('weight', 'integer', 'weight/importance of the notification'),
            ('details', 'text', 'extra information')
        ]::notification_directory.attr_def[])
);
$$ LANGUAGE sql VOLATILE;


CREATE TYPE "trend"."trend_data" AS (
  "timestamp" timestamptz,
  "entity_id" integer,
  "counters" numeric[]
);



CREATE FUNCTION "trend"."create_dynamic_source_description"("trend" text, "counter" integer, "entity" text, "granularity" interval)
    RETURNS text
AS $$
SELECT FORMAT( 'trend.%I t%s %s ', trend_directory.get_table_name_for_trend($1, $3, $4), $2, CASE $2 WHEN 1 THEN '' ELSE FORMAT('ON t%s.entity_id = t1.entity_id AND t%s.timestamp = t1.timestamp', $2, $2) END );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend"."get_dynamic_trend_data_sql"("timestamp" timestamptz, "entity_type_name" text, "granularity" interval, "counter_names" text[])
    RETURNS text
AS $$
WITH ref as (
  SELECT
    FORMAT('t%s.%I::numeric', i, c) as column_description,
    trend.create_dynamic_source_description(c, i::integer, $2, $3) as join_data             
  FROM unnest($4) WITH ORDINALITY as counters(c,i)
)
SELECT FORMAT(
    'SELECT ''%s''::timestamp, t1.entity_id, ARRAY[%s] '
    'FROM %s'
    'JOIN entity.%I ent ON ent.id = t1.entity_id '
    'WHERE t1.timestamp = ''%s'';',
  $1,
  string_agg(column_description, ', '),
  string_agg(join_data, ' JOIN '),
  $2,
  $1
  ) FROM ref;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend"."get_dynamic_trend_data"("timestamp" timestamp with time zone, "entity_type_name" text, "granularity" interval, "counter_names" text[])
    RETURNS setof trend.trend_data
AS $$
DECLARE r trend.trend_data%rowtype; BEGIN FOR r IN EXECUTE trend.get_dynamic_trend_data_sql($1, $2, $3, $4) LOOP RETURN NEXT r; END LOOP; RETURN; END;
$$ LANGUAGE plpgsql STABLE;


CREATE TRIGGER cleanup_on_materialization_delete
  BEFORE DELETE ON "trend_directory"."materialization"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."cleanup_for_materialization"();


CREATE TRIGGER cleanup_on_view_materialization_delete
  BEFORE DELETE ON "trend_directory"."view_materialization"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."cleanup_for_view_materialization"();


CREATE TRIGGER cleanup_on_function_materialization_delete
  BEFORE DELETE ON "trend_directory"."function_materialization"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."cleanup_for_function_materialization"();
