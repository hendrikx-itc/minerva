BEGIN;

SELECT plan(2);

SELECT trigger.create_trigger_notification_store('test');

SELECT has_table(
    'notification'::name,
    'test'::name,
    'Should have notification table'
);

SELECT has_table(
    'notification'::name,
    'test_staging'::name,
    'Should have notification staging table'
);

SELECT * FROM finish();

ROLLBACK;
