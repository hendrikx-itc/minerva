BEGIN;

SELECT plan(8);

SELECT is(directory.get_entity_type('Network'), null, 'Entity types are not automatically created');

SELECT isnt(directory.create_entity_type('Network'), null, 'Entity types can be created');

SELECT isnt(directory.get_entity_type('Network'), null, 'Entity types exist after being created');

SELECT has_table('entity', 'Network', 'Entity tables should be auto-created when entity types are created');

SELECT isnt(directory.name_to_entity_type('Network'), null, 'entity type can be found by name');

SELECT isnt(directory.name_to_entity_type('Operator'), null, 'non-existing entity types can be found by name');

SELECT has_table('entity', 'Operator', 'created entity-types through name_to_entity_type should create entity table');

SELECT bag_eq('SELECT name FROM directory.entity_type', ARRAY['Network', 'Operator'], 'name to entity type creates new entity type if and only if non-existing');

SELECT * FROM finish();
ROLLBACK;
