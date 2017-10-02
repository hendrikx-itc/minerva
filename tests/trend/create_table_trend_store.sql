BEGIN;

SELECT plan(3);

SELECT trend_directory.create_table_trend_store(
    'test1',
    'some_entity_type_name',
    '900',
    86400,
    ARRAY[
        ('test-trend-store-1_part1', ARRAY[]::trend_directory.trend_descr[])
    ]::trend_directory.table_trend_store_part_descr[]
);

SELECT has_table(
    'trend',
    'test-trend-store-1_part1',
    'trend_store table without trend columns should exist'
);

SELECT trend_directory.create_table_trend_store(
    'test2',
    'some_entity_type_name',
    '900',
    86400,
    ARRAY[
        (
            'test-trend-store-2_part1',
            ARRAY[
                ('x', 'integer', '')
            ]::trend_directory.trend_descr[])
    ]::trend_directory.table_trend_store_part_descr[]
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
        'modified',
        'x'
    ]
);



SELECT * FROM finish();
ROLLBACK;
