BEGIN;

SELECT plan(1);

CREATE TYPE trigger_rule."simple-trigger_kpi_data" AS (
    entity_id integer,
    "timestamp" timestamp with time zone,
    x integer
);

CREATE FUNCTION trigger_rule."simple-trigger_kpi"(timestamp with time zone)
    RETURNS SETOF trigger_rule."simple-trigger_kpi_data"
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
    ARRAY[('threshold_x', 'integer')]::trigger.threshold_def[]
);

SELECT trigger.set_condition(
    'simple-trigger',
    'x > threshold_x'
);

SELECT trigger_rule."simple-trigger_set_thresholds"(42);

SELECT ok(now() - trigger.fingerprint(rule, now())::timestamptz < interval '1 minute')
FROM trigger.rule WHERE name = 'simple-trigger';

SELECT * FROM finish();
ROLLBACK;
