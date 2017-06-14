BEGIN;

SELECT plan(3);

SELECT notification.create_notificationstore(
    'test-source',
    ARRAY[
        ('rule_id', 'integer'),
        ('details', 'text'),
        ('weight', 'integer'),
        ('created', 'timestamp with time zone')
    ]::notification.attr_def[]
);

CREATE TYPE trigger_rule."simple-trigger_kpi_data" AS (
    entity_id integer,
    "timestamp" timestamp with time zone,
    x integer
);

CREATE FUNCTION trigger_rule."simple-trigger_kpi"(timestamp with time zone)
    RETURNS SETOF trigger_rule."simple-trigger_kpi_data"
AS $$
SELECT * FROM (
    SELECT
        entity_id::integer,
        timestamp::timestamp with time zone,
        x::integer
    FROM (VALUES
        (10, '2015-06-21 00:00+00', 44),
        (11, '2015-06-21 00:00+00', 45),
        (12, '2015-06-21 00:00+00', 46),
        (10, '2015-06-22 00:00+00', 41),
        (11, '2015-06-22 00:00+00', 42),
        (12, '2015-06-22 00:00+00', 43)
    ) AS t(entity_id, timestamp, x)
) foo WHERE timestamp = $1;
$$ LANGUAGE sql STABLE;


SELECT trigger.create_rule(
    'simple-trigger',
    ARRAY[('max_x', 'integer')]::trigger.threshold_def[]
);

SELECT trigger.set_condition(rule, 'x <= max_x') FROM trigger.rule WHERE name = 'simple-trigger';

SELECT trigger_rule."simple-trigger_set_thresholds"(42);

SELECT is(count(*), 2::bigint) FROM trigger_rule."simple-trigger_notification"('2015-06-22 00:00+00'::timestamptz);

SELECT ok(now() - trigger.fingerprint(rule, '2015-07-02 16:00')::timestamptz < interval '1 minute')
FROM trigger.rule WHERE name = 'simple-trigger';

UPDATE trigger.rule SET notificationstore_id = notificationstore.id FROM notification.notificationstore WHERE name = 'simple-trigger' AND notificationstore::text = 'test-source';

SELECT is(2, trigger.create_notifications('simple-trigger', '2015-06-22 00:00+00'::timestamptz));

SELECT * FROM finish();
ROLLBACK;

