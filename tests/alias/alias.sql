BEGIN;

-- Checks whether aliases are correctly included and whether items can be found by alias

SELECT plan(13);

SELECT alias_directory.create_alias_type('alias');

SELECT alias_directory.create_alias_type('otheralias');

SELECT directory.create_entity_type('type');

SELECT directory.create_entity_type('othertype');

SELECT is(alias_directory.get_entity_by_alias('alias', 'foo'), NULL, 'get_entity_by_alias should default to NULL');

SELECT alias_directory.get_or_create_entity('alias', 'foo', 'type');

SELECT isnt(alias_directory.get_entity_by_alias('alias', 'foo'), NULL, 'get_or_create_entity should create an entity if necessary');

SELECT is(alias_directory.get_or_create_entity('alias', 'foo', 'type'), alias_directory.get_entity_by_alias('alias', 'foo'), 'get_or_create_entity should be idempotent');

SELECT alias_directory.get_or_create_entity('alias', 'bar', 'type');

SELECT isnt(alias_directory.get_entity_by_alias('alias', 'foo'), alias_directory.get_entity_by_alias('alias', 'bar'), 'new aliases should not be given to existing items');

SELECT bag_eq(
    $$ SELECT alias_directory.aliases_to_entity_ids('alias', ARRAY['foo', 'bar'], 'type'); $$,
    $$ SELECT id FROM directory.entity; $$,
    'aliases_to_entity_ids should be able to find entities'
);

SELECT alias_directory.aliases_to_entity_ids('alias', ARRAY['foo', 'nonsense'], 'type');

SELECT row_eq($$ SELECT COUNT(*) FROM directory.entity; $$, ROW(3::bigint), 'aliases_to_entity_ids should create entities, but only when needed');

SELECT is(alias_directory.get_alias(directory.entity_id(alias_directory.get_entity_by_alias('alias', 'foo')), 'alias'), 'foo', 'getting an existing alias should work');

SELECT is(alias_directory.get_alias(directory.entity_id(alias_directory.get_entity_by_alias('alias', 'foo')), 'otheralias'), NULL, 'getting a non-existing alias should result in NULL');

SELECT alias_directory.create_alias(alias_directory.get_entity_by_alias('alias', 'foo'), 'otheralias', 'bar');

SELECT is(alias_directory.get_alias(directory.entity_id(alias_directory.get_entity_by_alias('alias', 'foo')), 'otheralias'), 'bar', 'the correct alias value should be found after creation');

SELECT is(alias_directory.get_alias(directory.entity_id(alias_directory.get_entity_by_alias('alias', 'foo')), 'alias'), 'foo', 'creating a new alias should not change or remove existing aliases');

SELECT is(alias_directory.get_entity_by_alias('alias', 'foo'), alias_directory.get_entity_by_alias('otheralias', 'bar'), 'it should be possible to get the same item through different aliases');

SELECT alias_directory.delete_alias_type(alias_directory.get_alias_type('otheralias'));

SELECT throws_like($$ SELECT alias_directory.get_alias(directory.entity_id(alias_directory.get_entity_by_alias('alias', 'foo')), 'otheralias') $$, '% does not exist%', 'it should not be possible to get aliases from a deleted alias type');

SELECT throws_like($$ SELECT alias_directory.get_entity_by_alias('otheralias', 'bar') $$, '% does not exist%', 'it should not be possible to find something through an alias of a deleted type');

SELECT * FROM finish();
ROLLBACK;
