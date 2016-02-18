BEGIN;

SELECT plan(3);

SELECT trend_directory.create_table_trend_store(
    'test-trend-store',
    'test1',
    'some_entity_type_name',
    '900',
    86400,
    ARRAY[
        ('x', 'integer', 'some column with integer values')
    ]::trend_directory.trend_descr[]
);

SELECT columns_are(
    'trend',
    trend_directory.base_table_name(table_trend_store),
    ARRAY[
        'entity_id',
        'timestamp',
        'modified',
        'x'
    ]
)
FROM trend_directory.table_trend_store
WHERE table_trend_store::text = 'test-trend-store';

SELECT trend_directory.alter_trend_name(
    table_trend_store,
    'x',
    'y'
)
FROM trend_directory.table_trend_store;

SELECT is(table_trend.name, 'y'::name, 'trend should have new name')
FROM trend_directory.table_trend
JOIN trend_directory.table_trend_store ON table_trend_store.id = table_trend.trend_store_id
WHERE table_trend_store::name = 'test-trend-store';

SELECT columns_are(
    'trend',
    trend_directory.base_table_name(table_trend_store),
    ARRAY[
        'entity_id',
        'timestamp',
        'modified',
        'y'
    ]
)
FROM trend_directory.table_trend_store
WHERE table_trend_store::text = 'test-trend-store';

SELECT * FROM finish();
ROLLBACK;

