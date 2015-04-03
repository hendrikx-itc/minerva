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

SELECT has_table(
    'trend',
    'test1_some_entity_type_name_qtr',
    'trend_store table with one trend column should exist'
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

SELECT trend_directory.create_table_trend_store(
    'test2',
    'some_entity_type_name',
    '900',
    ARRAY[]::trend_directory.trend_descr[]
);

SELECT has_table(
    'trend',
    'test2_some_entity_type_name_qtr',
    'trend_store table without trend columns should exist'
);


SELECT * FROM finish();
ROLLBACK;
