BEGIN;

SELECT plan(6);

SELECT trend_directory.define_table_trend_store(
    'test1',
    'some_entity_type_name',
    '300 seconds',
    86400,
    ARRAY[]::trend_directory.table_trend_store_part_descr[]
);

SELECT is(
    table_trend_store.partition_size,
    86400,
    'table trend store with partition_size 86400 should be defined'
)
FROM trend_directory.table_trend_store
JOIN directory.data_source ON data_source.id = table_trend_store.data_source_id
JOIN directory.entity_type ON entity_type.id = table_trend_store.entity_type_id
WHERE data_source.name = 'test1' AND entity_type.name = 'some_entity_type_name';


SELECT bag_eq(
    $$SELECT name from trend_directory.table_trend_store_part;$$,
    ARRAY[]::text[],
    'no table trend store part should be created'
    );

SELECT bag_eq(
    $$SELECT name from trend_directory.table_trend;$$,
    ARRAY[]::text[],
    'no table trend should be created'
    );

SELECT trend_directory.define_table_trend_store(
    'test2',
    'some_entity_type_name',
    '300 seconds',
    86400,
    ARRAY[
        (
            'test-trend-store-1_part1',
            ARRAY[
                ('x', 'integer', '')
            ]::trend_directory.trend_descr[]
        )
    ]::trend_directory.table_trend_store_part_descr[]
);

SELECT is(
    table_trend_store.partition_size,
    86400,
    'table trend store with partition_size 86400 should be defined'
)
FROM trend_directory.table_trend_store
JOIN directory.data_source ON data_source.id = table_trend_store.data_source_id
JOIN directory.entity_type ON entity_type.id = table_trend_store.entity_type_id
WHERE data_source.name = 'test2' AND entity_type.name = 'some_entity_type_name';

SELECT bag_eq(
    $$SELECT name from trend_directory.table_trend_store_part;$$,
    ARRAY['test-trend-store-1_part1'],
    'table trend store part should be created'
    );

SELECT bag_eq(
    $$SELECT name from trend_directory.table_trend;$$,
    ARRAY['x'],
    'table trend should be created'
    );

SELECT * FROM finish();
ROLLBACK;
