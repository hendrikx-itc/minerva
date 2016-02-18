BEGIN;

SELECT plan(1);

SELECT trigger.create_trigger_notification_store('test');

SELECT has_table(
    'notification'::name,
    'test'::name,
    'Should have notification table'
);

SELECT * FROM finish();

ROLLBACK;
