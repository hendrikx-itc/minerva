BEGIN;

SELECT plan(1);

SELECT trend_directory.create_table_trend_store(
    'test1',
    'some_entity_type_name',
    '900',
    86400,
    ARRAY[
        ('test-trend-store',
        ARRAY[
            ('x', 'integer', 'some column with integer values')
        ]::trend_directory.trend_descr[])
    ]::trend_directory.table_trend_store_part_descr[]
);

SELECT columns_are(
    'trend',
    trend_directory.base_table_name(table_trend_store_part),
    ARRAY[
        'entity_id',
        'timestamp',
        'modified',
        'x'
    ]
)
FROM trend_directory.table_trend_store
JOIN trend_directory.table_trend_store_part
ON table_trend_store_part.trend_store_id = table_trend_store.id
WHERE table_trend_store::text = 'test-trend-store';

SELECT trend_directory.alter_trend_name(
    table_trend_store_part,
    'x',
    'y'
)
FROM trend_directory.table_trend_store_part;

SELECT is(table_trend.name, 'y'::name, 'trend should have new name')
FROM trend_directory.table_trend
JOIN trend_directory.table_trend_store_part
ON table_trend_store_part.id = table_trend.trend_store_part_id
JOIN trend_directory.table_trend_store
ON table_trend_store.id = table_trend_store_part.trend_store_id
WHERE table_trend_store::name = 'test-trend-store';

SELECT columns_are(
    'trend',
    trend_directory.base_table_name(table_trend_store_part),
    ARRAY[
        'entity_id',
        'timestamp',
        'modified',
        'y'
    ]
)
FROM trend_directory.table_trend_store_part
JOIN trend_directory.table_trend_store
ON table_trend_store.id = table_trend_store_part.trend_store_id
WHERE table_trend_store::text = 'test-trend-store';

SELECT * FROM finish();
ROLLBACK;

