BEGIN;

SELECT plan(2);

SELECT directory.create_entity_type('Cell');

SELECT directory.create_data_source('default_ds');

SELECT notification_directory.create_notification_store('default_ds');

CREATE OR REPLACE VIEW trend."global_sales_day" AS
SELECT * FROM (
	VALUES
	((entity."to_Cell"('4321')).id, '2014-03-06 00:00'::timestamp with time zone, 34),
	((entity."to_Cell"('4322')).id, '2014-03-06 00:00'::timestamp with time zone, 44)
) dummy_values(entity_id, timestamp, "sales");

CREATE TYPE trigger_rule."test-rule_kpi" AS (
   entity_id integer,
   timestamp timestamp with time zone,
   sales numeric
);

CREATE FUNCTION trigger_rule."test-rule_kpi"(timestamp with time zone)
  RETURNS SETOF trigger_rule."test-rule_kpi"
  AS $$
    SELECT entity_id, timestamp, "sales"::numeric
      FROM trend."global_sales_day";
  $$ LANGUAGE sql STABLE;

SELECT trigger.create_rule(
       'test-rule',
       ARRAY[('threshold_sales', 'numeric')]::trigger.threshold_def[]
);

UPDATE trigger.rule
  SET notification_store_id = notification_store.id,
    granularity = '1 hour'
  FROM notification_directory.notification_store
    JOIN directory.data_source
    ON data_source.id = notification_store.data_source_id
    WHERE rule.name = 'test-rule' AND data_source.name = 'default_ds';

SELECT trigger.set_weight('test-rule', '100');

SELECT trigger_rule."test-rule_set_thresholds"(100);

SELECT trigger.set_condition(rule, '"sales" < "threshold_sales"') FROM trigger.rule WHERE name = 'test-rule';

SELECT trigger.define_notification_message('test-rule', '''test-rule fired''');

--SELECT trigger.create_rule(
--	'test-rule',
--$$
--	SELECT entity_id, timestamp, "sales"
--	FROM trend."global_sales_day"
--$$,
--ARRAY['sales'],
--$$
--    "sales" < "threshold_sales"
--$$);

INSERT INTO directory.tag_group(name, complementary) VALUES ('default', false);

INSERT INTO directory.tag(name, tag_group_id)
SELECT 'LTE', id FROM directory.tag_group WHERE name = 'default';

SELECT trigger.tag('LTE', id)
FROM trigger.rule
WHERE name = 'test-rule';

SELECT is(tag.name, 'LTE', 'rule should have tag LTE')
FROM trigger.rule
JOIN trigger.rule_tag_link ON rule_tag_link.rule_id = rule.id
JOIN directory.tag ON tag.id = rule_tag_link.tag_id
WHERE rule.name = 'test-rule';

PREPARE my_thrower AS
SELECT trigger.tag('LTE', id)
FROM trigger.rule
WHERE name = 'test-rule';

SELECT throws_ok(
    'my_thrower',
    '23505',
    'duplicate key value violates unique constraint "rule_tag_link_pkey"',
    'We should get a unique violation for a duplicate PK'
);

SELECT * FROM finish();
ROLLBACK;


