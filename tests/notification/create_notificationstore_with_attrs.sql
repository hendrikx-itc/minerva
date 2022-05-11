BEGIN;

SELECT plan(12);

SELECT isa_ok(
    notification_directory.create_notification_store(
        'some_data_source_name',
        ARRAY[('NV_ALARM_ID', 'integer', '')]::notification_directory.attr_def[]
    ),
    'notification_directory.notification_store',
    'the result of create_notification_store'
);

SELECT has_table(
    'notification',
    'some_data_source_name',
    'table should be created'
);

SELECT has_column(
    'notification'::name, 'some_data_source_name'::name, 'NV_ALARM_ID'::name,
    'notification store table has a custom attribute column NV_ALARM_ID'
);

SELECT col_type_is(
    'notification'::name, 'some_data_source_name'::name, 'NV_ALARM_ID'::name,
    'integer',
    'NV_ALARM_ID is of type integer'
);

SELECT bag_eq(
    $$ SELECT name FROM directory.data_source; $$,
    ARRAY[ 'some_data_source_name' ],
    'creating notification store should create data source'
);

SELECT throws_like(
    $$ SELECT notification_directory.create_notification_store(
        'some_data_source_name',
        ARRAY[('some_other_id', 'integer', '')]::notification_directory.attr_def[]
    ); $$,
    '%unique constraint%',
    'creating a second notification store for the same data source is not possible'
);

CALL attribute_directory.create_attribute_store(
    'another_data_source_name',
    'some_entity_type_name',
    ARRAY[]::attribute_directory.attribute_descr[]
);

SELECT bag_eq(
    $$ SELECT name FROM directory.data_source; $$,
    ARRAY[ 'some_data_source_name', 'another_data_source_name' ],
    'creating notification store should create data source'
);

SELECT lives_ok(
    $$ SELECT notification_directory.create_notification_store(
        'another_data_source_name',
        ARRAY[('some_other_id', 'integer', ''),
	      ('name', 'text', '')]::notification_directory.attr_def[]
    ); $$,
    'creating a notification store for an existing data source should be possible'
);

SELECT bag_eq(
    $$ SELECT name FROM directory.data_source; $$,
    ARRAY[ 'some_data_source_name', 'another_data_source_name' ],
    'creating a notification store for an existing data source does not create a new data source'
);

SELECT has_column(
    'notification',
    'another_data_source_name',
    'some_other_id',
    'notification store table should have custom attribute some_other_id'
);

SELECT has_column(
    'notification',
    'another_data_source_name',
    'name',
    'notification store table should have custom attribute name'
);

SELECT col_type_is(
    'notification',
    'another_data_source_name',
    'name',
    'text',
    'name should be of type text'
);

SELECT * FROM finish();
ROLLBACK;
