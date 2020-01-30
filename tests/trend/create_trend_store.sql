BEGIN;

SELECT plan(5);

SELECT trend_directory.create_trend_store(
    'test1',
    'some_entity_type_name',
    '15m'::interval,
    '1 day'::interval,
    ARRAY[
        ('test-trend-store-1_part1',
	 ARRAY[]::trend_directory.trend_descr[],
	 ARRAY[]::trend_directory.generated_trend_descr[])
    ]::trend_directory.trend_store_part_descr[]
);

SELECT has_table(
    'trend',
    'test-trend-store-1_part1',
    'trend_store table without trend columns should exist'
);

SELECT trend_directory.create_trend_store(
    'test2',
    'some_entity_type_name', 
    '15m'::interval,
    '1 day'::interval,
    ARRAY[
        (
            'test-trend-store-2_part1',
            ARRAY[
                ('x', 'integer', '', 'sum', 'sum', '{}')
            ]::trend_directory.trend_descr[],
	    ARRAY[]::trend_directory.generated_trend_descr[])
    ]::trend_directory.trend_store_part_descr[]
);


SELECT has_table(
    'trend',
    'test-trend-store-2_part1',
    'trend_store table with one trend column should exist'
);

SELECT columns_are(
    'trend',
    'test-trend-store-2_part1',
    ARRAY[
        'entity_id',
        'timestamp',
	'created',
        'job_id',
        'x'
    ]
);

SELECT col_type_is( 'trend', 'test-trend-store-2_part1', 'x', 'integer', 'x should be an integer');

PREPARE repeat AS SELECT trend_directory.create_trend_store(
    'test1',
    'some_entity_type_name',
    '15m'::interval,
    '1 day'::interval,
    ARRAY[
        ('test-trend-store-1_part1',
	 ARRAY[]::trend_directory.trend_descr[],
	 ARRAY[]::trend_directory.generated_trend_descr[])
    ]::trend_directory.trend_store_part_descr[]
);

SELECT throws_like('repeat', '%unique constraint%', 'Same trend_store cannot be created twice');

SELECT * FROM finish();
ROLLBACK;
