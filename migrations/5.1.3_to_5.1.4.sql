

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,1,4)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION "trend_directory"."add_generated_trends_to_trend_store_part"(trend_directory.trend_store_part, trend_directory.generated_table_trend[])
    RETURNS trend_directory.trend_store_part
AS $$
SELECT public.action(
  $1,
  ARRAY[
    format(
      'ALTER TABLE %I.%I %s;',
      trend_directory.base_table_schema(),
      trend_directory.base_table_name($1),
      (SELECT string_agg(trend_directory.add_generated_column_sql_part(t), ',') FROM unnest($2) AS t)
    )
  ]
);
$$ LANGUAGE sql VOLATILE;
