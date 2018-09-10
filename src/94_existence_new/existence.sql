-- Existence tracking functinality specifically for trend based data with a granularity of 1 day.

-- Calling example:
--
-- select gis.update_existence(existence_store, trendstore, '2018-09-07 00:00')
-- from gis.existence_store, trend.trendstore
-- where existence_store.entity_type_id = 305
-- and trendstore::text = 'transform-retainability_HandoverRelation_day';

CREATE TABLE gis.existence_store (
    entity_type_id integer primary key,
    epoch timestamp with time zone
);


CREATE FUNCTION gis.timestamp_to_existence_partition_index(epoch timestamp with time zone, ts timestamp with time zone)
 RETURNS integer
 LANGUAGE sql
AS $function$
    select (ts::date - epoch::date) / 64;
$function$;


CREATE FUNCTION gis.timestamp_to_existence_partition_index(gis.existence_store, ts timestamp with time zone)
 RETURNS integer
 LANGUAGE sql
AS $function$
    SELECT gis.timestamp_to_existence_partition_index($1.epoch, $2);
$function$;


CREATE FUNCTION gis.existence_partition_index_to_timestamp(epoch timestamp with time zone, index integer)
 RETURNS timestamp with time zone
 LANGUAGE sql
AS $function$
    select epoch + (index * 64 * '1 day'::interval);
$function$;


CREATE FUNCTION gis.timestamp_to_existence_bit_index(epoch timestamp with time zone, ts timestamp with time zone)
 RETURNS integer
 LANGUAGE sql
AS $function$
    select (ts::date - epoch::date) % 64;
$function$;


CREATE FUNCTION gis.timestamp_to_existence_index(epoch timestamp with time zone, ts timestamp with time zone)
    RETURNS integer
    LANGUAGE sql
AS $function$
    select ts::date - epoch::date;
$function$;


CREATE FUNCTION gis.timestamp_to_existence_index(gis.existence_store, ts timestamp with time zone)
    RETURNS integer
    LANGUAGE sql
AS $function$
    select ts::date - $1.epoch::date;
$function$;


CREATE FUNCTION gis.existence_index_to_timestamp(epoch timestamp with time zone, existence_index integer)
    RETURNS timestamp with time zone
    LANGUAGE sql
AS $function$
    select epoch + (existence_index * '1 day'::interval);
$function$;


CREATE FUNCTION gis.existence_index_to_timestamp(gis.existence_store, existence_index integer)
    RETURNS timestamp with time zone
    LANGUAGE sql
AS $function$
    select $1.epoch + (existence_index * '1 day'::interval);
$function$;


CREATE FUNCTION gis.existence_index_to_timestamp(epoch timestamp with time zone, partition_index integer, index integer)
 RETURNS timestamp with time zone
 LANGUAGE sql
AS $function$
    select gis.existence_partition_index_to_timestamp(epoch, partition_index) + (index * '1 day'::interval);
$function$;


CREATE FUNCTION gis.existence_table_name(gis.existence_store, index integer)
 RETURNS name
 LANGUAGE sql
AS $function$
    SELECT ('existence_' || entitytype.name || '_' || $2)::name
    FROM directory.entitytype where id = $1.entity_type_id;
$function$;


CREATE FUNCTION gis.existence_table_name(gis.existence_store, timestamp with time zone)
 RETURNS name
 LANGUAGE sql
AS $function$
    SELECT gis.existence_table_name($1, gis.timestamp_to_existence_partition_index($1, $2));
$function$;


CREATE FUNCTION gis.create_existence_table(entity_type text, index integer)
 RETURNS name
 LANGUAGE plpgsql
AS $function$
declare
    table_name name;
begin
    table_name := 'existence_' || $1 || '_' || $2;

    execute format(
        'CREATE TABLE gis.%I(entity_id integer primary key, existence bigint)',
        table_name
    );

    return table_name;
end;
$function$;


CREATE FUNCTION gis.create_existence_table(gis.existence_store, timestamp with time zone)
 RETURNS name
 LANGUAGE sql
AS $function$
    select gis.create_existence_table(
        entitytype.name,
        gis.timestamp_to_existence_partition_index($1.epoch, $2)
    ) from directory.entitytype where entitytype.id = $1.entity_type_id;
$function$;


CREATE or replace FUNCTION gis.init_existence_table(gis.existence_store, index integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
declare
    insert_count bigint;
begin
    execute format(
        'insert into gis.%I(entity_id, existence) select entity.id, 0 from directory.entity where entitytype_id = $1',
        gis.existence_table_name($1, $2)

    ) using $1.entity_type_id;

    GET DIAGNOSTICS insert_count = ROW_COUNT;

    return insert_count;
end;
$function$;


CREATE or replace FUNCTION gis.update_existence(gis.existence_store, trend.trendstore, timestamp with time zone)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
declare
    update_count bigint;
    source_table_name name;
begin
    source_table_name := $2::text::name;

    execute format(
        'update gis.%I e set existence = (e.existence | (1 << %s)) from trend.%I t where t.entity_id = e.entity_id and t.timestamp = $1',
        gis.existence_table_name($1, $3),
        gis.timestamp_to_existence_index($1.epoch, $3),
        source_table_name

    ) using $3;

    GET DIAGNOSTICS update_count = ROW_COUNT;

    return update_count;
end;
$function$;


CREATE TYPE gis.existence_point AS (
    "timestamp" timestamp with time zone,
    exists boolean
);


CREATE or replace FUNCTION gis.existence_json(gis.existence_store, index integer, entity_id integer)
    RETURNS TABLE(
        doc json
    )
 LANGUAGE plpgsql
AS $function$
declare
    partition_start timestamp with time zone;
begin
    partition_start := gis.existence_partition_index_to_timestamp($1.epoch, $2);

    RETURN QUERY EXECUTE format(
        'select ''{}''::json from gis.%I where entity_id = $1',
        gis.existence_table_name($1, $2)
    ) USING $3;
end;
$function$;


CREATE OR REPLACE FUNCTION gis.existence_to_array(partition_start timestamp with time zone, bigint)
    RETURNS gis.existence_point[]
    LANGUAGE sql
AS $function$
    with pts as (
        select
          generate_series(63, 0, -1) i,
          generate_series($1, $1 + (63 * '1 day'::interval), '1 day'::interval) t
    )
    select array_agg((t, ($2 & (1::bigint << i)) = (1::bigint << i))::gis.existence_point)
    from pts;
$function$;
