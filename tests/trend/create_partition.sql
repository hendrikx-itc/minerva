BEGIN;

SELECT plan(1);

SELECT trend_directory.create_trend_store(
    'test',
    'Node',
    '15m'::interval,
    '1 day'::interval,
    ARRAY[
        (
            'test-trend-store',
            ARRAY[
                ('x', 'integer', 'some column with integer values', 'sum', 'sum', '{}')
            ]::trend_directory.trend_descr[],
	    ARRAY[]::trend_directory.generated_trend_descr[]
        )
    ]::trend_directory.trend_store_part_descr[]
);


SELECT
    trend_directory.create_partition(trend_store_part, 379958)
FROM trend_directory.trend_store_part
WHERE trend_store_part::text = 'test-trend-store';

SELECT has_table(
    'trend_partition',
    format('%s_379958', trend_directory.base_table_name(trend_store_part)),
    'trend partition table should exist'
)
FROM trend_directory.trend_store_part
WHERE name = 'test-trend-store';

SELECT * FROM finish();
ROLLBACK;
