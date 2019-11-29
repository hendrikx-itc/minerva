BEGIN;

SELECT plan(10);

SELECT has_schema('entity');

SELECT directory.create_entity_type('Network');

SELECT has_table('entity', 'Network', 'Entity tables should be auto-created when entity types are created');

SELECT has_function('entity'::name, 'get_Network'::name, ARRAY['text']);

SELECT has_function('entity'::name, 'create_Network'::name);

SELECT has_function('entity'::name, 'to_Network'::name);

SELECT results_eq('SELECT name FROM entity."Network"', ARRAY[]::text[], 'Entity table should be initally empty');

SELECT is(entity."get_Network"('local'), null, 'Get entity should not find non-existing items');

SELECT isnt(entity."to_Network"('local'), null, 'To entity should find non-existing items');

SELECT entity."create_Network"('global');

SELECT isnt(entity."get_Network"('global'), null, 'Get entity should find existing items');

SELECT entity."to_Network"('local');

SELECT entity."to_Network"('global');

SELECT bag_eq('SELECT name FROM entity."Network"', ARRAY['local', 'global'], 'To entity should create entity exactly once');

SELECT * FROM finish();
ROLLBACK;
