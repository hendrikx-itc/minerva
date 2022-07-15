BEGIN;

SELECT plan(3);

SELECT isa_ok(
    notification_directory.create_notification_store(
        'get_column_type_ds',
        ARRAY[('NV_ALARM_ID', 'integer', ''),
	      ('some_name', 'text', '')]::notification_directory.attr_def[]
    ),
    'notification_directory.notification_store',
    'the result of create_notification_store'
);
    
SELECT alike(
    notification_directory.get_column_type_name(
        'notification'::name, 'get_column_type_ds'::name, 'NV_ALARM_ID'::name
    ),
    'int%',
    'NV_ALARM_ID should have some integer type'
);

SELECT is(
    notification_directory.get_column_type_name(
        'notification'::name, 'get_column_type_ds'::name, 'some_name'::name
    ),
    'text',
    'some_name should be of type text'
);
        

SELECT * FROM finish();
ROLLBACK;
