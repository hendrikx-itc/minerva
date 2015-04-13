BEGIN;

SELECT plan(2);

SELECT ok(directory.dn_to_entity('Network=local,Switch=main') IS NOT NULL);

SELECT EXISTS(SELECT 1 FROM directory.entity WHERE dn = 'Network=local');

SELECT has_table('directory'::name, 'entity'::name);

SELECT * FROM finish();
ROLLBACK;
