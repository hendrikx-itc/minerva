BEGIN;

SELECT plan(1);

SELECT directory.create_data_source('test-data');

SELECT directory.create_entity_type('Node');

SELECT trend_directory.create_trend_store(
    'test-data',
    'Node',
    '900'::interval,
    '1 day'::interval,
    ARRAY[
        ('test-trend-store-main', ARRAY [
	     ('x', 'integer', 'some column with integer values', 'sum', 'sum', '{}')
        ]::trend_directory.trend_descr[],
	ARRAY[]::trend_directory.generated_trend_descr[])
    ]::trend_directory.trend_store_part_descr[]
);

SELECT trend_directory.create_partition(
    trend_directory.get_trend_store_part(
      (trend_directory.get_trend_store('test-data', 'Node', '900'::interval)).id,
      'test-trend-store-main'
    ),
    '2015-01-21 15:00+00'::timestamp);

SELECT has_table('trend', 'test-trend-store-main_staging', 'staging table should exist');

INSERT INTO trend."test-trend-store-main_staging"(
    entity_id,
    timestamp,
    created,
    job_id,
    x
)
VALUES
    (id(entity."to_Node"('A001')), '2015-01-21 15:00+00', now(), 1, 42),
    (id(entity."to_Node"('A002')), '2015-01-21 15:00+00', now(), 1, 43);

SELECT trend_directory.transfer_staged(trend_store_part)
FROM trend_directory.trend_store_part
WHERE trend_store_part::text = 'test-trend-store-main';

SELECT trend_directory.define_materialization(
    trend_directory.get_trend_store_part_id(trend_directory.get_trend_store_part(
        trend_directory.get_trend_store_id(trend_directory.get_trend_store('test-data', 'Node', '900'::interval)),
        'test-trend-store-main')),
    '900'::interval, '86400'::interval, '86400'::interval);

/*
Old test code - this piece of code does not seem to be working yet

SELECT has_table(
    'trend',
    'target-trend-store-main',
    'materialized trend table should exist'
);

SELECT
    is(trend_directory.materialize(materialization, '2015-01-21 15:00+00'), 2, 'should materialize 2 records')
FROM trend_directory.materialization
WHERE materialization::text = 'target-trend-store';

SELECT
    is(trend_directory.materialize(materialization, '2015-01-22 11:00+00'), 0, 'should materialize nothing')
FROM trend_directory.materialization
WHERE materialization::text = 'target-trend-store';
*/

SELECT * FROM finish();
ROLLBACK;

