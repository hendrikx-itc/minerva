BEGIN;

SELECT plan(3);

SELECT trend_directory.create_table_trend_store(
    'test-trend-store-1',
    'test1',
    'some_entity_type_name',
    '900',
    86400,
    ARRAY[
        ('x', 'integer', 'some column with integer values')
    ]::trend_directory.trend_descr[]
);

SELECT has_table(
    'trend',
    'test-trend-store-1',
    'trend_store table with one trend column should exist'
);

SELECT columns_are(
    'trend',
    'test-trend-store-1',
    ARRAY[
        'entity_id',
        'timestamp',
        'modified',
        'x'
    ]
);

SELECT trend_directory.create_table_trend_store(
    'test-trend-store-2',
    'test2',
    'some_entity_type_name',
    '900',
    86400,
    ARRAY[]::trend_directory.trend_descr[]
);

SELECT has_table(
    'trend',
    'test-trend-store-2',
    'trend_store table without trend columns should exist'
);


SELECT * FROM finish();
ROLLBACK;
