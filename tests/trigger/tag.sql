BEGIN;

SELECT plan(2);

CREATE OR REPLACE VIEW trend."global_sales_day" AS
SELECT * FROM (
	VALUES
	((directory.dn_to_entity('sp=4321')).id, '2014-03-06 00:00'::timestamp with time zone, 34),
	((directory.dn_to_entity('sp=4322')).id, '2014-03-06 00:00'::timestamp with time zone, 44)
) dummy_values(entity_id, timestamp, "sales");

SELECT trigger.create_rule(
	'test-rule',
$$
	SELECT entity_id, timestamp, "sales"
	FROM trend."global_sales_day"
$$,
ARRAY['sales'],
$$
    "sales" < "threshold_sales"
$$);

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
