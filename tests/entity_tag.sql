BEGIN;

SELECT plan(3);

-- Defining the trendgroup beforehand is required
INSERT INTO directory.taggroup(name, complementary)
VALUES ('technology', true);

-- Define the tag definition as a view
SELECT entity_tag.define(
	'technology',
	'technology',
	$$SELECT * FROM (VALUES
	((directory.dn_to_entity('Cell=001')).id, 'LTE'),
	((directory.dn_to_entity('Cell=002')).id, 'UMTS')
) AS foo(entity_id, tag);$$
);

SELECT has_view('entity_tag', 'technology', 'corresponding view for tag definition should exist');

SELECT is(entity_tag.update('technology'), (2, 2, 2, 0)::entity_tag.update_result, 'update should add 2 new links');

SELECT is(entity_tag.update('technology'), (2, 0, 0, 0)::entity_tag.update_result, 'second run of update function should do nothing');

SELECT * FROM finish();
ROLLBACK;
