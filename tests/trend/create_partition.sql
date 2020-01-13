BEGIN;

SELECT plan(7);

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
    trend_directory.create_partition(trend_store_part, 13795)
FROM trend_directory.trend_store_part
WHERE trend_store_part::text = 'test-trend-store';

SELECT has_table(
    'trend_partition',
    format('%s_13795', trend_directory.base_table_name(trend_store_part)),
    'trend partition table should exist'
)
FROM trend_directory.trend_store_part
WHERE name = 'test-trend-store';

SELECT bag_eq(
    'SELECT index FROM trend_directory.partition WHERE name = ''test-trend-store_13795''',
    ARRAY[13795],
    'partition should have correct index'
    );

SELECT bag_eq(
    'SELECT partition.from FROM trend_directory.partition WHERE name = ''test-trend-store_13795''',
    ARRAY['2007-10-09 00:00:00+00']::timestamp[],
    'partition should have correct start time'
    );

SELECT bag_eq(
    'SELECT partition.to FROM trend_directory.partition WHERE name = ''test-trend-store_13795''',
    ARRAY['2007-10-10 00:00:00+00']::timestamp[],
    'partition should have correct end time'
    );

SELECT throws_like(
   $$SELECT
     trend_directory.create_partition(trend_store_part, 13795)
     FROM trend_directory.trend_store_part
     WHERE trend_store_part::text = 'test-trend-store'$$,
   '%already exists%',
   'same partition should not be created twice'
   );

SELECT hasnt_table(
    'trend_partition',
    format('%s_13797', trend_directory.base_table_name(trend_store_part)),
    'other trend partition table should not exist'
)
FROM trend_directory.trend_store_part
WHERE name = 'test-trend-store';

SELECT trend_directory.create_partition(
   trend_store_part, '2007-10-11 00:00:00+00'::timestamp)
FROM trend_directory.trend_store_part
WHERE trend_store_part::text = 'test-trend-store';

SELECT has_table(
    'trend_partition',
    format('%s_13795', trend_directory.base_table_name(trend_store_part)),
    'trend partition table should be created from timestamp'
)
FROM trend_directory.trend_store_part
WHERE name = 'test-trend-store';

SELECT * FROM finish();
ROLLBACK;
