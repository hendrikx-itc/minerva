BEGIN;

SELECT plan(3);

SELECT trend_directory.create_table_trend_store(
    'test1',
    'some_entity_type_name',
    '900',
    ARRAY[
        ('x', 'integer', 'some column with integer values')
    ]::trend_directory.trend_descr[]
);

SELECT columns_are(
    'trend',
    'test1_some_entity_type_name_qtr',
    ARRAY[
        'entity_id',
        'timestamp',
        'modified',
        'x'
    ]
);

SELECT trend_directory.alter_trend_name(
    table_trend_store,
    'x',
    'y'
)
FROM trend_directory.table_trend_store;

SELECT is(name, 'y'::name, 'trend should have new name')
FROM trend_directory.table_trend
JOIN trend_directory.table_trend_store ON table_trend_store.id = table_trend.trend_store_id
WHERE table_trend_store::name = 'test1_some_entity_type_name_qtr';

SELECT columns_are(
    'trend',
    'test1_some_entity_type_name_qtr',
    ARRAY[
        'entity_id',
        'timestamp',
        'modified',
        'y'
    ]
);

SELECT * FROM finish();
ROLLBACK;

