-- Existence tracking functinality specifically for trend based data with a
-- granularity of 1 day. Any table or view with the columns (entity_id integer,
-- timestamp timestamptz) can be used.

-- Create new partition:
--

-- Update example:
--
-- select gis.update_existence(existence_store, 'trend."transform-retainability_HandoverRelation_day"', '2018-09-07 00:00')
-- from gis.existence_store where existence_store::text = 'HandoverRelation';


CREATE TABLE gis.existence_store (
    id serial primary key,
    entity_type_id integer,
    epoch timestamp with time zone
);


CREATE TABLE gis.existence_store_partition (
    existence_store_id integer references gis.existence_store(id),
    index integer,
    start timestamp with time zone,
    "end" timestamp with time zone,
    UNIQUE (existence_store_id, index)
);


CREATE OR REPLACE FUNCTION gis.timestamp_to_existence_index(epoch timestamp with time zone, ts timestamp with time zone)
    RETURNS integer
    LANGUAGE sql
AS $function$
    select ts::date - epoch::date;
$function$;


CREATE OR REPLACE FUNCTION gis.timestamp_to_existence_partition_index(epoch timestamp with time zone, ts timestamp with time zone)
 RETURNS integer
 LANGUAGE sql
AS $function$
    SELECT gis.timestamp_to_existence_index($1, $2) / 64;
$function$;


CREATE OR REPLACE FUNCTION gis.timestamp_to_existence_partition_index(gis.existence_store, ts timestamp with time zone)
 RETURNS integer
 LANGUAGE sql
AS $function$
    SELECT gis.timestamp_to_existence_partition_index($1.epoch, $2);
$function$;


CREATE OR REPLACE FUNCTION gis.existence_index_to_timestamp(epoch timestamp with time zone, existence_index integer)
    RETURNS timestamp with time zone
    LANGUAGE sql
AS $function$
    select epoch + (existence_index * '1 day'::interval);
$function$;


CREATE OR REPLACE FUNCTION gis.existence_partition_index_to_timestamp(epoch timestamp with time zone, index integer)
 RETURNS timestamp with time zone
 LANGUAGE sql
AS $function$
    select gis.existence_index_to_timestamp(index * 64);
$function$;


CREATE OR REPLACE FUNCTION gis.timestamp_to_existence_bit_index(epoch timestamp with time zone, ts timestamp with time zone)
 RETURNS integer
 LANGUAGE sql
AS $function$
    select gis.timestamp_to_existence_index($1, $2) % 64;
$function$;


CREATE OR REPLACE FUNCTION gis.timestamp_to_existence_index(gis.existence_store, ts timestamp with time zone)
    RETURNS integer
    LANGUAGE sql
AS $function$
    select ts::date - $1.epoch::date;
$function$;


CREATE OR REPLACE FUNCTION gis.existence_index_to_timestamp(gis.existence_store, existence_index integer)
    RETURNS timestamp with time zone
    LANGUAGE sql
AS $function$
    select $1.epoch + (existence_index * '1 day'::interval);
$function$;


CREATE OR REPLACE FUNCTION gis.existence_index_to_timestamp(epoch timestamp with time zone, partition_index integer, index integer)
 RETURNS timestamp with time zone
 LANGUAGE sql
AS $function$
    select gis.existence_partition_index_to_timestamp(epoch, partition_index) + (index * '1 day'::interval);
$function$;


CREATE OR REPLACE FUNCTION gis.existence_store_name(gis.existence_store)
 RETURNS text
 LANGUAGE sql IMMUTABLE
AS $function$
    SELECT ('existence_' || entitytype.name)
    FROM directory.entitytype where id = $1.entity_type_id;
$function$;


CREATE CAST (gis.existence_store AS text) WITH FUNCTION gis.existence_store_name(gis.existence_store) AS IMPLICIT;


CREATE OR REPLACE FUNCTION gis.existence_table_name(gis.existence_store, index integer)
 RETURNS name
 LANGUAGE sql
AS $function$
    SELECT (gis.existence_store_name($1) || '_' || $2)::name;
$function$;


CREATE OR REPLACE FUNCTION gis.existence_table_name(gis.existence_store, timestamp with time zone)
 RETURNS name
 LANGUAGE sql
AS $function$
    SELECT gis.existence_table_name($1, gis.timestamp_to_existence_partition_index($1, $2));
$function$;


CREATE OR REPLACE FUNCTION gis.create_existence_table(gis.existence_store, index integer)
 RETURNS name
 LANGUAGE plpgsql
AS $function$
declare
    table_name name;
begin
    table_name := gis.existence_table_name($1, $2);

    execute format(
        'CREATE TABLE gis.%I(entity_id integer primary key, existence bigint)',
        table_name
    );

    execute format(
        'ALTER TABLE gis.%I OWNER TO minerva_admin',
        table_name
    );

    execute format(
        'GRANT SELECT ON TABLE gis.%I TO minerva',
        table_name
    );

    return table_name;
end;
$function$;


CREATE OR REPLACE FUNCTION gis.get_existence_partition(gis.existence_store, index integer)
 RETURNS gis.existence_store_partition
 LANGUAGE sql
AS $function$
    SELECT * FROM gis.existence_store_partition WHERE existence_store_id = $1.id AND index = $2;
$function$;


CREATE OR REPLACE FUNCTION gis.create_existence_partition(gis.existence_store, index integer)
 RETURNS gis.existence_store_partition
 LANGUAGE sql
AS $function$
    SELECT gis.create_existence_table($1, $2);

    INSERT INTO gis.existence_store_partition(existence_store_id, index, start, "end") (
      SELECT $1.id, $2, gis.existence_partition_index_to_timestamp($1.epoch, $2), gis.existence_partition_index_to_timestamp($1.epoch, $2 + 1)
    ) RETURNING *;
$function$;


CREATE OR REPLACE FUNCTION gis.ensure_existence_partition(gis.existence_store, index integer)
 RETURNS gis.existence_store_partition
 LANGUAGE sql
AS $function$
    SELECT coalesce(gis.get_existence_partition($1, $2), gis.create_existence_partition($1, $2));
$function$;


CREATE OR REPLACE FUNCTION gis.drop_existence_table(gis.existence_store, index integer)
 RETURNS name
 LANGUAGE plpgsql
AS $function$
declare
    table_name name;
begin
    table_name := gis.existence_table_name($1, $2);

    execute format(
        'DROP TABLE gis.%I',
        table_name
    );

    return table_name;
end;
$function$;


CREATE OR REPLACE FUNCTION gis.delete_existence_partition(gis.existence_store_partition)
 RETURNS name
 LANGUAGE sql
AS $function$
    DELETE FROM gis.existence_store_partition
    WHERE existence_store_id = $1.existence_store_id AND index = $1.index;

    SELECT gis.drop_existence_table(existence_store, $1.index)
    FROM gis.existence_store WHERE id = $1.existence_store_id;
$function$;


CREATE OR REPLACE FUNCTION gis.init_existence_table(gis.existence_store, index integer)
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


CREATE OR REPLACE FUNCTION gis.init_existence_partition(gis.existence_store_partition)
 RETURNS bigint
 LANGUAGE sql
AS $function$
    SELECT gis.init_existence_table(existence_store, $1.index)
    FROM gis.existence_store WHERE id = $1.existence_store_id;
$function$;


CREATE TYPE gis.update_existence_result AS (
    updated bigint,
    added bigint
);


CREATE OR REPLACE FUNCTION gis._update_existence(gis.existence_store, regclass, timestamp with time zone)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
declare
    update_count bigint;
begin
    execute format(
        'UPDATE gis.%I AS e SET existence = (e.existence | (1::bigint << %s))
        FROM %s AS t
        WHERE t.timestamp = $1 AND t.entity_id = e.entity_id',
        gis.existence_table_name($1, $3),
        63 - gis.timestamp_to_existence_bit_index($1.epoch, $3 - '1 day'::interval),
        $2
    ) using $3;

    GET DIAGNOSTICS update_count = ROW_COUNT;

    return update_count;
end;
$function$;


CREATE OR REPLACE FUNCTION gis._insert_existence(gis.existence_store, regclass, timestamp with time zone)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
declare
    insert_count bigint;
begin
    execute format(
        'INSERT INTO gis.%I (entity_id, existence) (
            SELECT t.entity_id, (1::bigint << %s)
            FROM %s AS t LEFT JOIN gis.%I AS e ON e.entity_id = t.entity_id
            WHERE t.timestamp = $1 AND e.entity_id IS NULL
        )',
        gis.existence_table_name($1, $3),
        63 - gis.timestamp_to_existence_bit_index($1.epoch, $3 - '1 day'::interval),
        $2,
        gis.existence_table_name($1, $3)
    ) using $3;

    GET DIAGNOSTICS insert_count = ROW_COUNT;

    return insert_count;
end;
$function$;


CREATE OR REPLACE FUNCTION gis.update_existence(gis.existence_store, regclass, timestamp with time zone)
 RETURNS gis.update_existence_result
 LANGUAGE sql
AS $function$
    select (
        gis._update_existence($1, $2, $3),
        gis._insert_existence($1, $2, $3)
    )::gis.update_existence_result;
$function$;


CREATE TYPE gis.existence_point AS (
    "timestamp" timestamp with time zone,
    exists boolean
);


CREATE OR REPLACE FUNCTION gis.bigint_to_booleans(bigint)
    RETURNS SETOF boolean
    LANGUAGE sql IMMUTABLE
AS $function$
    select ($1 & (1::bigint << i)) = (1::bigint << i) from generate_series(63, 0, -1) i
$function$;


CREATE OR REPLACE FUNCTION gis.partition_timestamps(partition_start timestamp with time zone)
    RETURNS SETOF timestamp with time zone
    LANGUAGE sql IMMUTABLE
AS $function$
    select generate_series($1, $1 + (63 * '1 day'::interval), '1 day'::interval) t
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


CREATE OR REPLACE FUNCTION gis.existence_to_legacy_array(partition_start timestamp with time zone, bigint)
    RETURNS text[]
    LANGUAGE sql
AS $function$
    with pts as (
        select
          generate_series(63, 0, -1) i,
          generate_series($1, $1 + (63 * '1 day'::interval), '1 day'::interval) t
    )
    select array_agg((($2 & (1::bigint << i)) = (1::bigint << i)) || ',' || date_part('epoch', t))
    from pts;
$function$;

