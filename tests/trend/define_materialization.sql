BEGIN;

SELECT plan(5);

SELECT results_eq('SELECT COUNT(*)::integer FROM trend_directory.materialization', ARRAY[0], 'No materialization should be predefined');

SELECT directory.create_data_source('datasource');

SELECT directory.create_entity_type('entitytype');

SELECT trend_directory.create_trend_store(
    'test-data',
    'Node',
    '15m'::interval,
    '1 day'::interval,
    ARRAY[
        (
            'test-trend-store',
            ARRAY[
                ('x', 'integer', 'some column with integer values', 'max', 'max', '{}')
            ]::trend_directory.trend_descr[],
	    ARRAY[]::trend_directory.generated_trend_descr[]
        )
    ]::trend_directory.trend_store_part_descr[]
);

SELECT trend_directory.create_trend_store_part(
    trend_directory.get_trend_store_id(trend_directory.get_trend_store('test-data', 'Node', '15m'::interval)),
    'Part');

SELECT results_eq('SELECT COUNT(*)::integer FROM trend_directory.materialization', ARRAY[0], 'No materialization should be automatically created');

SELECT results_eq('SELECT COUNT(*)::integer FROM trend_directory.materialization_metrics', ARRAY[0], 'No materialization metrics should be created without materialization');

SELECT trend_directory.define_materialization(
    trend_directory.get_trend_store_part_id(trend_directory.get_trend_store_part(trend_directory.get_trend_store_id(trend_directory.get_trend_store('test-data', 'Node', '15m'::interval)), 'Part')),
    '15m'::interval,
    '1h'::interval,
    '15m'::interval);

SELECT results_eq('SELECT COUNT(*)::integer FROM trend_directory.materialization', ARRAY[1], 'Define_materialization should create a single materialization');

SELECT bag_eq('SELECT id FROM trend_directory.materialization', 'SELECT materialization_id FROM trend_directory.materialization_metrics', 'defining a materialization should define its metrics');

SELECT * FROM finish();
ROLLBACK;
