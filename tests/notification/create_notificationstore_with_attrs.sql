BEGIN;

SELECT plan(12);

SELECT isa_ok(
    notification_directory.create_notification_store(
        'notificationstore_attrs_ds',
        ARRAY[('NV_ALARM_ID', 'integer', '')]::notification_directory.attr_def[]
    ),
    'notification_directory.notification_store',
    'the result of create_notification_store'
);

SELECT has_table(
    'notification',
    'notificationstore_attrs_ds',
    'table should be created'
);

SELECT has_column(
    'notification'::name, 'notificationstore_attrs_ds'::name, 'NV_ALARM_ID'::name,
    'notification store table has a custom attribute column NV_ALARM_ID'
);

SELECT col_type_is(
    'notification'::name, 'notificationstore_attrs_ds'::name, 'NV_ALARM_ID'::name,
    'integer',
    'NV_ALARM_ID is of type integer'
);

SELECT bag_eq(
    $$ SELECT name FROM directory.data_source; $$,
    ARRAY[ 'notificationstore_attrs_ds' ],
    'creating notification store should create data source'
);

SELECT throws_like(
    $$ SELECT notification_directory.create_notification_store(
        'notificationstore_attrs_ds',
        ARRAY[('some_other_id', 'integer', '')]::notification_directory.attr_def[]
    ); $$,
    '%unique constraint%',
    'creating a second notification store for the same data source is not possible'
);

CALL attribute_directory.create_attribute_store(
    'another_ds_name',
    'notificationstore_attrs_et',
    ARRAY[]::attribute_directory.attribute_descr[]
);

SELECT bag_eq(
    $$ SELECT name FROM directory.data_source; $$,
    ARRAY[ 'notificationstore_attrs_ds', 'another_ds_name' ],
    'creating notification store should create data source'
);

SELECT lives_ok(
    $$ SELECT notification_directory.create_notification_store(
        'another_ds_name',
        ARRAY[('some_other_id', 'integer', ''),
	      ('name', 'text', '')]::notification_directory.attr_def[]
    ); $$,
    'creating a notification store for an existing data source should be possible'
);

SELECT bag_eq(
    $$ SELECT name FROM directory.data_source; $$,
    ARRAY[ 'notificationstore_attrs_ds', 'another_ds_name' ],
    'creating a notification store for an existing data source does not create a new data source'
);

SELECT has_column(
    'notification',
    'another_ds_name',
    'some_other_id',
    'notification store table should have custom attribute some_other_id'
);

SELECT has_column(
    'notification',
    'another_ds_name',
    'name',
    'notification store table should have custom attribute name'
);

SELECT col_type_is(
    'notification',
    'another_ds_name',
    'name',
    'text',
    'name should be of type text'
);

SELECT * FROM finish();
ROLLBACK;
