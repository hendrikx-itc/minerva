

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,2,3)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


CREATE TYPE "trend_directory"."change_trend_store_part_result" AS (
  "added_trends" text[],
  "removed_trends" text[],
  "changed_trends" text[]
);



CREATE FUNCTION "trend_directory"."add_trends"("part" trend_directory.trend_store_part_descr)
    RETURNS text[]
AS $$
SELECT trend_directory.assure_table_trends_exist(
  trend_store_part,
  $1.trends,
  $1.generated_trends
)
FROM trend_directory.trend_store_part
WHERE name = $1.name;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."remove_extra_trends"("part" trend_directory.trend_store_part_descr)
    RETURNS text[]
AS $$
SELECT trend_directory.remove_extra_trends(
  trend_store_part,
  $1.trends
)
FROM trend_directory.trend_store_part
WHERE name = $1.name;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."trend_has_update"("trend" trend_directory.table_trend, "trend_update" trend_directory.trend_descr)
    RETURNS boolean
AS $$
SELECT
  $1.data_type != $2.data_type
  OR
  $1.time_aggregation != $2.time_aggregation
  OR
  $1.entity_aggregation != $2.entity_aggregation;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trend_data_upward"("part" trend_directory.trend_store_part_descr)
    RETURNS text[]
AS $$
SELECT array_agg(trend_directory.change_table_trend_data_safe(
  table_trend,
  t.data_type,
  t.entity_aggregation,
  t.time_aggregation
))
FROM trend_directory.trend_store_part
JOIN trend_directory.table_trend ON table_trend.trend_store_part_id = trend_store_part.id
JOIN UNNEST($1.trends) AS t ON t.name = table_trend.name
WHERE trend_store_part.name = $1.name AND trend_directory.trend_has_update(table_trend, t);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trend_store_part_weak"("part" trend_directory.trend_store_part_descr)
    RETURNS trend_directory.change_trend_store_part_result
AS $$
DECLARE
  result trend_directory.change_trend_store_part_result;
BEGIN
  SELECT trend_directory.add_trends($1) INTO result.added_trends;

  SELECT trend_directory.remove_extra_trends($1) INTO result.removed_trends;

  SELECT trend_directory.change_trend_data_upward($1) INTO result.changed_trends;

  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION "trend_directory"."change_table_trend_data_unsafe"(trend_directory.table_trend, "data_type" text, "entity_aggregation" text, "time_aggregation" text)
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
    SELECT $1.name INTO result;
  END IF;

  IF $1.data_type <> $2
  THEN
    EXECUTE format('ALTER TABLE trend.%I ALTER %I TYPE %s USING CAST(%I AS %s)',
      trend_directory.trend_store_part_name_for_trend($1),
      $1.name,
      $2,
      $1.name,
      $2);
  END IF;

  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION "trend_directory"."data_type_order"("data_type" text)
    RETURNS integer
AS $$
BEGIN
    CASE data_type
        WHEN 'smallint' THEN
            RETURN 1;
        WHEN 'integer' THEN
            RETURN 2;
        WHEN 'bigint' THEN
            RETURN 3;
        WHEN 'real' THEN
            RETURN 4;
        WHEN 'double precision' THEN
            RETURN 5;
        WHEN 'numeric' THEN
            RETURN 6;
        WHEN 'timestamp without time zone' THEN
            RETURN 7;
        WHEN 'smallint[]' THEN
            RETURN 8;
        WHEN 'integer[]' THEN
            RETURN 9;
        WHEN 'numeric[]' THEN
            RETURN 10;
        WHEN 'text[]' THEN
            RETURN 11;
        WHEN 'text' THEN
            RETURN 12;
        WHEN NULL THEN
            RETURN NULL;
        ELSE
            RAISE EXCEPTION 'Unsupported data type: %', data_type;
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;
