BEGIN;

SELECT plan(7);

SELECT has_table('directory'::name, 'entity'::name);

SELECT is(directory.get_entity_by_dn('Network=local,Switch=main'), null, 'Entities should not be auto-created');

SELECT isnt(directory.dn_to_entity('Network=local,Switch=main'), null, 'Entities should be created by dn_to_entity');

SELECT isnt(directory.get_entity_by_dn('Network=local,Switch=main'), null, 'Created entities should remain');

SELECT is(directory.get_entity_type('Network'), null, 'Non-ultimate entity type is not created when Entity is created');

SELECT isnt(directory.get_entity_type('Switch'), null, 'Last entity type is not created when Entity is created');

SELECT directory.dn_to_entity('Network=local,Switch=main');

SELECT bag_eq('SELECT name from directory.entity', ARRAY['main'], 'entities are created, only one entity is created and name is last value');

SELECT * FROM finish();
ROLLBACK;
