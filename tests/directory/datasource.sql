BEGIN;

SELECT plan(7);

SELECT has_table('directory'::name, 'data_source'::name);

SELECT is(directory.get_data_source('datasource'), null, 'Data sources should not be auto-created');

SELECT isnt(directory.create_data_source('datasource'), null, 'Data sources can be created');

SELECT isnt(directory.get_data_source('datasource'), null, 'Data sources should exist after being created');

SELECT isnt(directory.name_to_data_source('datasource'), null, 'Data sources can be found by name');

SELECT isnt(directory.name_to_data_source('othersource'), null, 'Data sources by name are created if necessary');

SELECT bag_eq('SELECT name from directory.data_source', ARRAY['datasource', 'othersource'], 'data sources are created but not unnecessarily');

SELECT * FROM finish();
ROLLBACK;
