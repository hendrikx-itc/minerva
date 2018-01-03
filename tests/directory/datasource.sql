BEGIN;

SELECT plan(4);

SELECT has_table('directory'::name, 'data_source'::name);

SELECT is(directory.get_data_source('datasource'), null, 'Data sources should not be auto-created');

SELECT isnt(directory.create_data_source('datasource'), null, 'Data sources can be created');

SELECT isnt(directory.get_data_source('datasource'), null, 'Data sources should exist after being created');

SELECT * FROM finish();
ROLLBACK;
