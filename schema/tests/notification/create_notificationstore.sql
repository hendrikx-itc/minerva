BEGIN;

SELECT plan(5);

SELECT isa_ok(
    notification_directory.create_notification_store('some_data_source_name'),
    'notification_directory.notification_store',
    'the result of create_notification_store'
);

SELECT has_table(
    'notification'::name, 'some_data_source_name'::name,
    'table with name of data_source should exist'
);

SELECT has_column(
    'notification'::name, 'some_data_source_name'::name, 'id'::name,
    'notification store table has a column id'
);

SELECT has_column(
    'notification'::name, 'some_data_source_name'::name, 'entity_id'::name,
    'notification store table has a column entity_id'
);

SELECT has_column(
    'notification'::name, 'some_data_source_name'::name, 'timestamp'::name,
    'notification store table has a column timestamp'
);

SELECT * FROM finish();
ROLLBACK;
