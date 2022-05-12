BEGIN;

SELECT plan(9);

SELECT notification_directory.create_notification_store(
        'create_notificationsetstore_data_source',
        ARRAY[('NV_ALARM_ID', 'integer', '')]::notification_directory.attr_def[]
);

SELECT bag_eq(
    $$ SELECT name from notification_directory.notification_set_store; $$,
    ARRAY[]::name[],
    'No notification set store should exist without explicit creation'
);

SELECT notification_directory.create_notification_set_store('some_name', store)
FROM notification_directory.notification_store store, directory.data_source ds
WHERE store.data_source_id = ds.id AND ds.name = 'create_notificationsetstore_data_source';

SELECT bag_eq(
    $$ SELECT name from notification_directory.notification_set_store; $$,
    ARRAY['some_name']::name[],
    'Notification set store should be created'
);

SELECT has_table(
    'notification',
    'some_name',
    'notification table should be created'
);

SELECT columns_are(
    'notification',
    'some_name',
    ARRAY[ 'id' ],
    'notification table only has an id'
);

SELECT has_table(
    'notification',
    'some_name_link',
    'link table should be created'
);

SELECT columns_are(
    'notification',
    'some_name_link',
    ARRAY[ 'notification_id', 'set_id' ],
    'link table should have correct columns'
);

INSERT INTO notification.create_notificationsetstore_data_source (id, entity_id, timestamp) VALUES (35, 40, '2017-01-01 00:00:00');
INSERT INTO notification.some_name VALUES (30);

SELECT throws_like(
    $$ INSERT INTO notification.some_name_link VALUES (50, 30); $$,
    '%foreign key constraint%',
    'notification link should be impossible with non-existing data source'
);

SELECT throws_like(
    $$ INSERT INTO notification.some_name_link VALUES (35, 50); $$,
    '%foreign key constraint%',
    'notification link should be impossible with non-existing notification'
);

SELECT lives_ok(
    $$ INSERT INTO notification.some_name_link VALUES (35, 30); $$,
    'notification link should be possible with existing values'
);

SELECT * FROM finish();
ROLLBACK;
