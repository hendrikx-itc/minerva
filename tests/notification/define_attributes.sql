BEGIN;

SELECT * FROM no_plan();

SELECT notification_directory.create_notification_store('data_source');

SELECT notification_directory.define_attributes(
    notification_directory.get_notification_store('data_source'),
    ARRAY[('x', 'integer', 'some integer attribute'),
          ('y', 'text', 'some text attribute')]::notification_directory.attr_def[]);

SELECT bag_eq(
    $$ SELECT name FROM notification_directory.attribute; $$,
    ARRAY[ 'x', 'y' ],
    'attributes should be created'
);

SELECT results_eq(
    $$ SELECT data_type FROM notification_directory.attribute WHERE name = 'x'; $$,
    ARRAY [ 'integer'::name ],
    'attribute x should have correct type'
);

SELECT * FROM finish();
ROLLBACK;
