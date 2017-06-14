BEGIN;

SELECT plan(3);

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
    ARRAY[('max_x', 'integer')]::trigger.threshold_def[]
);

--    x > threshold_x

SELECT trigger_rule."simple-trigger_set_thresholds"(42);

-- By default the fingerprint function should return a string with the current
-- timestamp
SELECT ok(now() - trigger.fingerprint(rule, '2015-07-02 16:00')::timestamptz < interval '1 minute')
FROM trigger.rule WHERE name = 'simple-trigger';

-- Set new fingerprint function
SELECT trigger.set_fingerprint(rule, $$SELECT 'custom_fingerprint'::text;$$)
FROM trigger.rule WHERE name = 'simple-trigger';

-- Check if fingerprint function returns new fingerprint 'custom_fingerprint'
SELECT is(trigger.fingerprint(rule, now()), 'custom_fingerprint')
FROM trigger.rule WHERE name = 'simple-trigger';

-- Set fingerprint function using convenience function
SELECT trigger.set_fingerprint('simple-trigger'::name, $$SELECT 'new_custom_fingerprint'::text;$$);

-- Check if fingerprint function returns new fingerprint 'new_custom_fingerprint'
SELECT is(trigger.fingerprint(rule, now()), 'new_custom_fingerprint')
FROM trigger.rule WHERE name = 'simple-trigger';

SELECT * FROM finish();
ROLLBACK;

