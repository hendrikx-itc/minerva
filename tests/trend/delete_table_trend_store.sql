BEGIN;

SELECT plan(6);

SELECT trend_directory.define_table_trend_store(
    'test2',
    'some_entity_type_name',
    '300 seconds',
    86400,
    ARRAY[
        (
            'test-trend-store-1_part1',
            ARRAY[
                ('x', 'integer', '')
            ]::trend_directory.trend_descr[]
        )
    ]::trend_directory.table_trend_store_part_descr[]
);

SELECT results_ne(
    $$SELECT id from trend_directory.table_trend_store;$$,
    ARRAY[]::integer[],
    'table trend store should be created'
    );

SELECT results_eq(
    $$SELECT name from trend_directory.table_trend_store_part;$$,
    ARRAY['test-trend-store-1_part1'::name],
    'table trend store part should be created'
    );

SELECT results_eq(
    $$SELECT name from trend_directory.table_trend;$$,
    ARRAY['x'::name],
    'table trend should be created'
    );

SELECT trend_directory.delete_table_trend_store('test2');

SELECT results_eq(
    $$SELECT id from trend_directory.table_trend_store_part;$$,
    ARRAY[]::integer[],
    'table trend store should be deleted'
    );
    
SELECT results_eq(
    $$SELECT name from trend_directory.table_trend_store_part;$$,
    ARRAY[]::name[],
    'table trend store part should be deleted'
    );

SELECT results_eq(
    $$SELECT name from trend_directory.table_trend;$$,
    ARRAY[]::name[],
    'table trend should be deleted'
    );

SELECT * FROM finish();
ROLLBACK;
