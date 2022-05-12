BEGIN;

SELECT plan(3);

SELECT directory.create_data_source('test1');

SELECT directory.create_entity_type('rename_trend_et');

SELECT trend_directory.create_trend_store(
    'test1',
    'rename_trend_et',
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
        'created',
	'job_id',
        'x'
    ]
)
FROM trend_directory.trend_store
JOIN trend_directory.trend_store_part
ON trend_store_part.trend_store_id = trend_store.id
JOIN directory.entity_type
ON trend_store.entity_type_id = entity_type.id
JOIN directory.data_source
ON trend_store.data_source_id = data_source.id
WHERE data_source.name = 'test1'
AND entity_type.name = 'rename_trend_et';

SELECT trend_directory.alter_trend_name(
    trend_store_part,
    'x',
    'y'
)
FROM trend_directory.trend_store_part;

SELECT is(table_trend.name, 'y'::name, 'trend should have new name')
FROM trend_directory.table_trend
JOIN trend_directory.trend_store_part
ON trend_store_part.id = table_trend.trend_store_part_id
JOIN trend_directory.trend_store
ON trend_store.id = trend_store_part.trend_store_id
JOIN directory.entity_type
ON trend_store.entity_type_id = entity_type.id
JOIN directory.data_source
ON trend_store.data_source_id = data_source.id
WHERE data_source.name = 'test1'
AND entity_type.name = 'rename_trend_et';

SELECT columns_are(
    'trend',
    trend_directory.base_table_name(trend_store_part),
    ARRAY[
        'entity_id',
        'timestamp',
        'created',
	'job_id',
        'y'
    ]
)
FROM trend_directory.trend_store
JOIN trend_directory.trend_store_part
ON trend_store_part.trend_store_id = trend_store.id
JOIN directory.entity_type
ON trend_store.entity_type_id = entity_type.id
JOIN directory.data_source
ON trend_store.data_source_id = data_source.id
WHERE data_source.name = 'test1'
AND entity_type.name = 'rename_trend_et';

SELECT * FROM finish();
ROLLBACK;

