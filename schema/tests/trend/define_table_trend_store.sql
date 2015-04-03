BEGIN;

SELECT plan(1);


SELECT trend_directory.define_table_trend_store(
    'test1',
    'some_entity_type_name',
    '300 seconds',
    86400
);

SELECT is(
    table_trend_store::text,
    'test1_some_entity_type_name_5m',
    'table trend store with name test1_some_entity_type_name_300 should be defined'
)
FROM trend_directory.table_trend_store
JOIN directory.data_source ON data_source.id = table_trend_store.data_source_id
JOIN directory.entity_type ON entity_type.id = table_trend_store.entity_type_id
WHERE data_source.name = 'test1' AND entity_type.name = 'some_entity_type_name';

SELECT * FROM finish();
ROLLBACK;
