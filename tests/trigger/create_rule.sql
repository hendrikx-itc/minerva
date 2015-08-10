BEGIN;

SELECT plan(2);

CREATE FUNCTION trigger_rule."simple-trigger_kpi"(timestamp with time zone)
    RETURNS TABLE(entity_id integer, "timestamp" timestamp with time zone, x integer)
AS $$
    SELECT
        entity_id::integer,
        timestamp::timestamp with time zone,
        x::integer
    FROM (VALUES
        (9,  '2015-06-21 00:00+00', 45),
        (10, '2015-06-22 00:00+00', 42)
    ) AS t(entity_id, timestamp, x)
$$ LANGUAGE sql STABLE;

SELECT trigger.create_rule(
    'simple-trigger',
    ARRAY[('x', 'integer')]::trigger.kpi_def[],
    ARRAY[]::trigger.threshold_def[]
);

SELECT has_function('trigger_rule', 'simple-trigger_runnable', ARRAY['timestamp with time zone']);
SELECT has_function('trigger_rule', 'simple-trigger_fingerprint', ARRAY['timestamp with time zone']);

SELECT * FROM finish();
ROLLBACK;
