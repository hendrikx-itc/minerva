BEGIN;

SELECT plan(4);

SELECT trend_directory.create_trend_store(
    'test-source',
    'Node',
    '900'::interval,
    '86400'::interval,
    ARRAY[
        (
            'test-trend-store',
            ARRAY[
                ('x', 'integer', 'some column with integer values', 'max', 'max', '{}')
            ]::trend_directory.trend_descr[],
	    ARRAY[]::trend_directory.generated_trend_descr[]
        )
    ]::trend_directory.trend_store_part_descr[]
);

SELECT trend_directory.create_partition(trend_store_part, 1)
FROM trend_directory.trend_store_part
WHERE name = 'test-trend-store';

SELECT trend_directory.create_partition(trend_store_part, 2)
FROM trend_directory.trend_store_part
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

SELECT trend_directory.rename_trend_store_part(
    trend_store_part,
    'renamed-trend-store'
)
FROM trend_directory.trend_store_part
WHERE name = 'test-trend-store';


SELECT has_table(
    'trend',
    'renamed-trend-store',
    'trend store part table with new name should exist'
);


SELECT * FROM finish();
ROLLBACK;
