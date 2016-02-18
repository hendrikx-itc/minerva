BEGIN;

SELECT plan(1);

SELECT trend_directory.create_table_trend_store(
    'test-trend-store',
    'test',
    'Node',
    '900',
    '3600',
    ARRAY[
        ('x', 'integer', 'some column with integer values')
    ]::trend_directory.trend_descr[]
);


SELECT
    trend_directory.create_partition(table_trend_store, 379958)
FROM trend_directory.table_trend_store
WHERE table_trend_store::text = 'test-trend-store';

SELECT has_table(
    'trend_partition',
    format('%s_379958', trend_directory.base_table_name(table_trend_store)),
    'trend partition table should exist'
)
FROM trend_directory.table_trend_store
WHERE table_trend_store::text = 'test-trend-store';

SELECT * FROM finish();
ROLLBACK;
