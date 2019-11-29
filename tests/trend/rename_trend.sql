BEGIN;

SELECT plan(1);

SELECT directory.create_data_source('test1');

SELECT directory.create_entity_type('some_entity_type_name');

SELECT trend_directory.create_trend_store(
    'test1',
    'some_entity_type_name',
    '900'::interval,
    '86400'::interval,
    ARRAY[
        ('test-trend-store',
        ARRAY[
            ('x', 'integer', 'some column with integer values', 'max', 'max', '{}')
        ]::trend_directory.trend_descr[],
	ARRAY[]::trend_directory.generated_trend_descr[])
    ]::trend_directory.trend_store_part_descr[]
);

SELECT columns_are(
    'trend',
    trend_directory.base_table_name(trend_store_part),
    ARRAY[
        'entity_id',
        'timestamp',
        'modified',
        'x'
    ]
)
FROM trend_directory.trend_store
JOIN trend_directory.trend_store_part
ON trend_store_part.trend_store_id = trend_store.id
WHERE trend_store::text = 'test-trend-store';

SELECT trend_directory.alter_trend_name(
    trend_store_part,
    'x',
    'y'
)
FROM trend_directory.trend_store_part;

SELECT is(trend.name, 'y'::name, 'trend should have new name')
FROM trend_directory.trend
JOIN trend_directory.trend_store_part
ON trend_store_part.id = trend.trend_store_part_id
JOIN trend_directory.trend_store
ON trend_store.id = trend_store_part.trend_store_id
WHERE trend_store::name = 'test-trend-store';

SELECT columns_are(
    'trend',
    trend_directory.base_table_name(trend_store_part),
    ARRAY[
        'entity_id',
        'timestamp',
        'modified',
        'y'
    ]
)
FROM trend_directory.trend_store_part
JOIN trend_directory.trend_store
ON trend_store.id = trend_store_part.trend_store_id
WHERE trend_store::text = 'test-trend-store';

SELECT * FROM finish();
ROLLBACK;

