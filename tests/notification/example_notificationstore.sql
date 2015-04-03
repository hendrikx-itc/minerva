BEGIN;

SELECT plan(3);

SELECT isa_ok(
    notification_directory.create_notification_set_store(
        'ticket'::name,
        notification_directory.create_notification_store('state_changes')
    ),
    'notification_directory.notification_set_store',
    'the result of create_notification_set_store'
);

SELECT has_table(
    'notification'::name, 'ticket'::name,
    'table with name of notification_set_store should exist'
);

SELECT has_table(
    'notification'::name, 'ticket_link'::name,
    'link table for notification_set_store should exist'
);

SELECT * FROM finish();
ROLLBACK;
