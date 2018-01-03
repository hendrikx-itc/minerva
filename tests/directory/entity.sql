BEGIN;

SELECT plan(6);

SELECT has_table('directory'::name, 'entity'::name);

SELECT is(directory.get_entity_by_dn('Network=local,Switch=main'), null, 'Entities should not be auto-created');

SELECT isnt(directory.dn_to_entity('Network=local,Switch=main'), null, 'Entities should be created by dn_to_entity');

SELECT isnt(directory.get_entity_by_dn('Network=local,Switch=main'), null, 'Created entities should remain');

SELECT is(directory.get_entity_type('Network'), null, 'Non-ultimate entity type is not created when Entity is created');

SELECT isnt(directory.get_entity_type('Switch'), null, 'Last entity type is not created when Entity is created');

SELECT * FROM finish();
ROLLBACK;
