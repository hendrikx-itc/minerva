BEGIN;

SELECT plan(4);

SELECT ok(trigger.table_exists('relation', 'base'), 'existing table is found');
SELECT ok(not trigger.table_exists('relation', 'utter_nonsense'), 'non-existing table is not found');

SELECT ok(trigger.view_exists('attribute_directory', 'dependencies'), 'existing view is found');
SELECT ok(not trigger.view_exists('no_such_directory', 'dependencies'), 'non-existing view is not found');

SELECT * FROM finish();
ROLLBACK;
