BEGIN;

SELECT * FROM no_plan();

SELECT notification_directory.create_notification_store('notification_triggers_ds');
SELECT notification_directory.create_notification_store('another_ds_name');

SELECT has_table('notification', 'notification_triggers_ds',
    'basic notification table should exist'
);

SELECT bag_eq(
    $$ SELECT ds.name FROM notification_directory.notification_store ns, directory.data_source ds WHERE ns.data_source_id = ds.id; $$,
    ARRAY['notification_triggers_ds', 'another_ds_name'],
    'created notification stores should be reported'
);

SELECT notification_directory.delete_notification_store(ns)
  FROM notification_directory.notification_store ns
  JOIN directory.data_source ds ON ns.data_source_id = ds.id
  WHERE ds.name = 'notification_triggers_ds';

SELECT bag_eq(
    $$ SELECT ds.name FROM notification_directory.notification_store ns, directory.data_source ds WHERE ns.data_source_id = ds.id; $$,
    ARRAY['another_ds_name'],
    'deleted notification stores should not be findable'
);

SELECT hasnt_table('notification', 'notification_triggers_ds',
    'table should be deleted'
);

SELECT has_table('notification', 'another_ds_name',
    'other table should not be deleted'
);

SELECT notification_directory.create_notification_store('notification_triggers_ds');

SELECT bag_eq(
    $$ SELECT 1 FROM notification_directory.notification_store; $$,
    ARRAY[ 1, 1 ],
    'notification store should have been re-created'
);

SELECT lives_ok(
    $$ DELETE FROM directory.data_source WHERE name = 'notification_triggers_ds'; $$,
    'deletion of data sources with notification store connected should be possible'
);

SELECT bag_eq(
    $$ SELECT 1 FROM notification_directory.notification_store; $$,
    ARRAY [ 1 ],
    'notification store should have been deleted when data source is deleted'
);

SELECT * FROM finish();
ROLLBACK;
