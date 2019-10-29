
DROP OPERATOR <> (system.version_tuple, system.version_tuple);


DROP FUNCTION "system"."version_gtlt_version"(system.version_tuple, system.version_tuple);

DROP FUNCTION "system"."set_version"(system.version_tuple);

DROP FUNCTION "system"."set_version"(integer, integer, integer);

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,0,1)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend_directory"."create_trend_store_part"("trend_store_id" integer, "name" name)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT trend_directory.initialize_trend_store_part(
    trend_directory.define_trend_store_part($1, $2)
  );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."get_or_create_trend_store_part"("trend_store_id" integer, "name" name)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT COALESCE(
  trend_directory.get_trend_store_part($1, $2),
  trend_directory.create_trend_store_part($1, $2)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."add_missing_trend_store_parts"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS trend_directory.trend_store
AS $$
SELECT trend_directory.get_or_create_trend_store_part($1.id, name)
  FROM unnest($2);
SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION "trend_directory"."add_missing_trends"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS trend_directory.trend_store
AS $$
SELECT trend_directory.assure_table_trends_exist(
  trend_directory.get_or_create_trend_store_part($1.id, name), trends)
FROM unnest($2);
SELECT $1;
$$ LANGUAGE sql VOLATILE;
