

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,2,2)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION "trend_directory"."add_trends"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
  partresult text[];
BEGIN
  FOR partresult IN
    SELECT trend_directory.assure_table_trends_exist(
      trend_directory.get_or_create_trend_store_part($1.id, name),
      trends,
      generated_trends
    )
    FROM unnest($2)
  LOOP
    SELECT result || partresult INTO result;
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;

DROP VIEW "trend_directory"."trend_store_part_stats_to_update";

CREATE VIEW "trend_directory"."trend_store_part_stats_to_update" AS
SELECT tsps.trend_store_part_id,
    tsps.timestamp
  FROM trend_directory.trend_store_part_stats tsps
  JOIN trend_directory.modified m
  ON tsps.trend_store_part_id = m.trend_store_part_id
    AND tsps.timestamp = m.timestamp
  WHERE tsps.modified < m.last + interval '1 second';
