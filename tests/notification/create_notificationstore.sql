BEGIN;

SELECT plan(6);

SELECT isa_ok(
    notification_directory.create_notification_store('create_notificationstore_data_source'),
    'notification_directory.notification_store',
    'the result of create_notification_store'
);

SELECT has_table(
    'notification'::name, 'create_notificationstore_data_source'::name,
    'table with name of data_source should exist'
);

SELECT has_column(
    'notification'::name, 'create_notificationstore_data_source'::name, 'id'::name,
    'notification store table has a column id'
);

SELECT has_column(
    'notification'::name, 'create_notificationstore_data_source'::name, 'entity_id'::name,
    'notification store table has a column entity_id'
);

SELECT has_column(
    'notification'::name, 'create_notificationstore_data_source'::name, 'timestamp'::name,
    'notification store table has a column timestamp'
);

SELECT lives_ok(
    $$ INSERT INTO notification.create_notificationstore_data_source (entity_id, timestamp) VALUES (35, '2017-01-01 00:00:00'); $$,
    'notification store table can be filled'
);

SELECT * FROM finish();
ROLLBACK;
