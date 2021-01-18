

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,1,7)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend_directory"."rename_partitions"(trend_directory.trend_store_part, "new_name" name)
    RETURNS trend_directory.trend_store_part
AS $$
DECLARE
  partition trend_directory.partition;
BEGIN
  FOR partition in SELECT * FROM trend_directory.partition WHERE trend_store_part_id = $1.id
  LOOP
    EXECUTE format(
        'ALTER TABLE trend_partition.%I RENAME TO %I',
        partition.name,
        $2 || '_' || partition.index
    );
    EXECUTE format(
        'UPDATE trend_directory.partition SET name = ''%s'' WHERE id = %s',
        $2 || '_' || partition.index,
        partition.id
    );
  END LOOP;
  RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."rename_trend_store_part_full"(trend_directory.trend_store_part, name)
    RETURNS trend_directory.trend_store_part
AS $$
DECLARE
  old_name text;
  new_name text;
BEGIN
  SELECT trend_directory.to_char($1) INTO old_name;
  SELECT $2::text INTO new_name;
  PERFORM trend_directory.rename_trend_store_part($1, $2);
  EXECUTE format(
      'ALTER TABLE %I.%I RENAME TO %I',
      trend_directory.staging_table_schema(),
      old_name || '_staging',
      new_name || '_staging'
  );
  PERFORM trend_directory.rename_partitions($1, $2);
  EXECUTE format(
      'UPDATE trend_directory.view_materialization '
      'SET src_view = ''%s'' '
      'WHERE src_view = ''%s''',
      'trend."_' || new_name || '"',
      'trend."_' || old_name || '"'
  );
  EXECUTE format(
      'UPDATE trend_directory.function_materialization '
      'SET src_function = ''%s'' '
      'WHERE src_function = ''%s''',
      'trend."' || new_name || '"',
      'trend."' || old_name || '"'
  );
  RETURN $1;
END
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION "trend_directory"."remove_table_trend"("trend" trend_directory.table_trend)
    RETURNS trend_directory.table_trend
AS $$
BEGIN
  EXECUTE FORMAT('ALTER TABLE trend.%I DROP COLUMN %I',
    trend_directory.trend_store_part_name_for_trend(trend), trend.name);
  EXECUTE FORMAT('ALTER TABLE trend.%I DROP COLUMN %I',
    trend_directory.trend_store_part_name_for_trend(trend)::text || '_staging', trend.name);
  DELETE FROM trend_directory.table_trend WHERE id = trend.id;
  RETURN t FROM trend_directory.table_trend t WHERE 0=1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION "trend"."get_dynamic_trend_data"("timestamp" timestamp with time zone, "entity_type_name" text, "granularity" interval, "counter_names" text[])
    RETURNS setof trend.trend_data
AS $$
DECLARE r trend.trend_data%rowtype; BEGIN IF $4 = ARRAY[]::text[] THEN FOR r IN EXECUTE FORMAT('SELECT ''%s''::timestamptz, e.id, ARRAY[]::numeric[] from entity.%I e', $1, $2) LOOP RETURN NEXT r; END LOOP; ELSE FOR r IN EXECUTE trend.get_dynamic_trend_data_sql($1, $2, $3, $4) LOOP RETURN NEXT r; END LOOP; END IF; RETURN; END;
$$ LANGUAGE plpgsql STABLE;
