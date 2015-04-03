BEGIN;

SELECT plan(2);

SELECT isa_ok(
    notification_directory.create_notification_store(
        'some_data_source_name',
        ARRAY[('NV_ALARM_ID', 'integer', '')]::notification_directory.attr_def[]
    ),
    'notification_directory.notification_store',
    'the result of create_notification_store'
);

SELECT has_column(
    'notification'::name, 'some_data_source_name'::name, 'NV_ALARM_ID'::name,
    'notification store table has a custom attribute column NV_ALARM_ID'
);

SELECT * FROM finish();
ROLLBACK;
