BEGIN;

SELECT plan(4);

SELECT trend_directory.create_table_trend_store(
    'test-trend-store',
    'test-source',
    'Node',
    '900',
    86400,
    ARRAY[
        ('x', 'integer', 'some column with integer values')
    ]::trend_directory.trend_descr[]
);

SELECT trend_directory.create_partition(table_trend_store, 1)
FROM trend_directory.table_trend_store
WHERE name = 'test-trend-store';

SELECT trend_directory.create_partition(table_trend_store, 2)
FROM trend_directory.table_trend_store
WHERE name = 'test-trend-store';

SELECT has_table(
    'trend',
    'test-trend-store',
    'trend store table should exist'
);

SELECT has_table(
    'trend_partition',
    'test-trend-store_1',
    'trend store partition table 1 should exist'
);

SELECT has_table(
    'trend_partition',
    'test-trend-store_2',
    'trend store partition table 2 should exist'
);

SELECT trend_directory.rename_table_trend_store(
    table_trend_store,
    'renamed-trend-store'
)
FROM trend_directory.table_trend_store
WHERE name = 'test-trend-store';


SELECT has_table(
    'trend',
    'renamed-trend-store',
    'trend store table with new name should exist'
);


SELECT * FROM finish();
ROLLBACK;
