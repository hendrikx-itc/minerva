BEGIN;

SELECT plan(6);

SELECT trend_directory.define_trend_store(
    directory.name_to_data_source('test1'),
    directory.name_to_entity_type('define_trendstore_et'),
    '300 seconds'::interval,
    '1 day'::interval
);

SELECT is(
    trend_store.partition_size,
    '86400'::interval,
    'table trend store with partition_size 86400 should be defined'
)
FROM trend_directory.trend_store
JOIN directory.data_source ON data_source.id = trend_store.data_source_id
JOIN directory.entity_type ON entity_type.id = trend_store.entity_type_id
WHERE data_source.name = 'test1' AND entity_type.name = 'define_trendstore_et';


SELECT bag_eq(
    $$SELECT name from trend_directory.trend_store_part;$$,
    ARRAY[]::text[],
    'no table trend store part should be created'
    );

SELECT bag_eq(
    $$SELECT name from trend_directory.table_trend;$$,
    ARRAY[]::text[],
    'no table trend should be created'
    );

SELECT trend_directory.define_trend_store(
    'test2',
    'define_trendstore_et',
    '300 seconds'::interval,
    '1 day'::interval
    );

SELECT trend_directory.define_trend_store_part(
    (trend_directory.get_trend_store('test2', 'define_trendstore_et', '300 seconds'::interval)).id,
    'test-trend-store-1_part1',
    ARRAY[
            ('x', 'integer', '', 'average', 'average', '{}')
         ]::trend_directory.trend_descr[],
    ARRAY[]::trend_directory.generated_trend_descr[]
);

SELECT is(
    trend_store.partition_size,
    '86400'::interval,
    'table trend store with partition_size 86400 should be defined'
)
FROM trend_directory.trend_store
JOIN directory.data_source ON data_source.id = trend_store.data_source_id
JOIN directory.entity_type ON entity_type.id = trend_store.entity_type_id
WHERE data_source.name = 'test2' AND entity_type.name = 'define_trendstore_et';

SELECT bag_eq(
    $$SELECT name from trend_directory.trend_store_part;$$,
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
