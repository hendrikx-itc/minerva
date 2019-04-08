BEGIN;

SELECT plan(8);

SELECT bag_eq('SELECT name FROM alias_directory.alias_type', ARRAY['dn'], 'dn should be the only known alias initially');

SELECT tables_are('alias', ARRAY['dn'], 'dn should be the only existing alias initially');

SELECT alias_directory.create_alias_type('sample');

SELECT tables_are('alias', ARRAY['dn', 'sample'], 'alias table should have been created');

SELECT set_eq('SELECT name FROM alias_directory.alias_type', ARRAY['dn', 'sample'], 'alias should have been added to directory');

SELECT bag_eq($$ SELECT name FROM alias_directory.get_alias_type('sample') $$, ARRAY['sample'], 'alias should be found when defined');

SELECT throws_like($$ SELECT alias_directory.create_alias_type('sample') $$, '%duplicate key value%', 'creating an alias type twice should not be possible');

SELECT alias_directory.delete_alias_type(alias_directory.get_alias_type('sample'));

SELECT bag_eq('SELECT name FROM alias_directory.alias_type', ARRAY['dn'], 'deleting alias type should remove it from the directory');

SELECT tables_are('alias', ARRAY['dn'], 'alias table should be deleted when alias type is deleted');


SELECT * FROM finish();
ROLLBACK;
