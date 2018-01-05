BEGIN;

SELECT plan(8);

SELECT is(directory.get_entity_type('Network'), null, 'Entity types are not automatically created');

SELECT isnt(directory.create_entity_type('Network'), null, 'Entity types can be created');

SELECT isnt(directory.get_entity_type('Network'), null, 'Entity types exist after being created');

SELECT isnt(directory.create_or_replace_entity_type('Operator'), null, 'Creating or replacing entity type is possible');

SELECT directory.create_or_replace_entity_type('Operator');

PREPARE types AS SELECT name FROM directory.entity_type;

SELECT bag_eq('types', ARRAY['Network', 'Operator'], 'create_or_replace_entity_type creates exactly once');

SELECT isnt(directory.name_to_entity_type('Network'), null, 'entity type can be found by name');

SELECT isnt(directory.name_to_entity_type('Name'), null, 'non-existing entity types can be found by name');

SELECT bag_eq('types', ARRAY['Network', 'Operator', 'Name'], 'name to entity type creates new entity type if and only if non-existing');

SELECT * FROM finish();
ROLLBACK;
