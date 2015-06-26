BEGIN;

SELECT plan(2);

SELECT notification.create_notificationstore(
    'test-source',
    ARRAY[
        ('rule_id', 'integer'),
        ('details', 'text'),
        ('weight', 'integer'),
        ('created', 'timestamp with time zone')
    ]::notification.attr_def[]
);

SELECT trigger.create_rule(
    'simple-trigger',
$$
SELECT
    entity_id::integer,
    timestamp::timestamp with time zone,
    x::integer
FROM (VALUES
    (9,  '2015-06-21 00:00+00', 45),
    (10, '2015-06-22 00:00+00', 42)
) AS t(entity_id, timestamp, x)
$$,
ARRAY['x'],
$$
    x > threshold_x
$$);

SELECT trigger_rule."simple-trigger_set_thresholds"(42);

UPDATE trigger.rule SET notificationstore_id = (SELECT id FROM notification.notificationstore WHERE notificationstore::text = 'test-source')
WHERE name = 'simple-trigger';

SELECT is(count(*), 1::bigint)
FROM trigger_rule."simple-trigger_notification";

SELECT trigger.create_notifications('simple-trigger', '2015-06-21 00:00+00'::timestamp with time zone);

SELECT is(fingerprint, 'stub')
FROM trigger.rule_state
JOIN trigger.rule ON rule.id = rule_state.rule_id
WHERE rule.name = 'simple-trigger';

SELECT * FROM finish();
ROLLBACK;
