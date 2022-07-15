BEGIN;

SELECT plan(6);

SELECT directory.create_data_source('test2');

SELECT directory.create_entity_type('delete_trendstore_et');

SELECT trend_directory.create_trend_store(
    'test2',
    'delete_trendstore_et',
    '300 seconds'::interval,
    '1 day'::interval,
    ARRAY[
        (
            'test-trend-store-1_part1',
            ARRAY[
                ('x', 'integer', '', 'max', 'max', '{}')
            ]::trend_directory.trend_descr[],
	    ARRAY[]::trend_directory.generated_trend_descr[]
        )
    ]::trend_directory.trend_store_part_descr[]
);

SELECT results_ne(
    $$SELECT id from trend_directory.trend_store;$$,
    ARRAY[]::integer[],
    'table trend store should be created'
    );

SELECT results_eq(
    $$SELECT name from trend_directory.trend_store_part;$$,
    ARRAY['test-trend-store-1_part1'::name],
    'table trend store part should be created'
    );

SELECT results_eq(
    $$SELECT name from trend_directory.table_trend;$$,
    ARRAY['x'::name],
    'table trend should be created'
    );

SELECT trend_directory.delete_trend_store('test2', 'delete_trendstore_et', '300 seconds'::interval);

SELECT results_eq(
    $$SELECT id from trend_directory.trend_store_part;$$,
    ARRAY[]::integer[],
    'table trend store should be deleted'
    );
    
SELECT results_eq(
    $$SELECT name from trend_directory.trend_store_part;$$,
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
