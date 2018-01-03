BEGIN;

SELECT plan(3);

SELECT is(directory.get_entity_type('Network'), null, 'Entity types are not automatically created');

SELECT isnt(directory.create_entity_type('Network'), null, 'Entity types can be created');

SELECT isnt(directory.get_entity_type('Network'), null, 'Entity types exist after being created');

SELECT * FROM finish();
ROLLBACK;
