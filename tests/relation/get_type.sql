BEGIN;

SELECT plan(7);

SELECT has_schema('relation');

SELECT tables_are('relation', ARRAY[]::text[], 'relation schema is initially empty');

SELECT is(relation_directory.get_type('X->Y'::name), null, 'get_type has no default (other than null)');

SELECT relation_directory.register_type('X->Y'::name);

SELECT isnt(relation_directory.get_type('X->Y'::name), null, 'get_type is not null when the type exists');

SELECT isnt(relation_directory.name_to_type('Y->Z'::name), null, 'name_to_type creates type if necessary');

SELECT isnt(relation_directory.get_type('Y->Z'::name), null, 'get_type is not null when name_to_type has run');

SELECT is(relation_directory.get_type('X->Y'::name), relation_directory.name_to_type('X->Y'), 'get_type and name_to_type deliver same vallue on existing names');

SELECT * FROM finish();
ROLLBACK;
