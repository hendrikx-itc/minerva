BEGIN;

SELECT plan(3);


SELECT trend_directory.create_table_trend_store(
    'test-data',
    'Node',
    '900'::interval,
    86400,
    ARRAY[
        ('test-trend-store-main', ARRAY [
	     ('x', 'integer', 'some column with integer values')
        ]::trend_directory.trend_descr[] )
    ]::trend_directory.table_trend_store_part_descr[]
);


INSERT INTO trend."test-trend-store-main"(
    entity_id,
    timestamp,
    modified,
    created,
    x
)
VALUES
    (id(directory.dn_to_entity('Network=G01,Node=A001')), '2015-01-21 15:00+00', now(), now(), 42),
    (id(directory.dn_to_entity('Network=G01,Node=A002')), '2015-01-21 15:00+00', now(), now(), 43);


SELECT trend_directory.transfer_staged(table_trend_store)
FROM trend_directory.table_trend_store
WHERE table_trend_store::text = 'test-trend-store-main';


SELECT trend_directory.define_materialization(
    vts,
    trend_directory.create_table_trend_store('target-trend-store', 'test-kpi', 'Node', '900', 86400, vts)
)
FROM trend_directory.create_view_trend_store(
        'view-trend-store',
        'vtest', 'Node', '900',
        $view_def$SELECT
    entity_id,
    timestamp,
    now() as modified,
    x
FROM trend."test-trend-store"$view_def$
) AS vts;


SELECT has_table(
    'trend',
    'target-trend-store',
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

SELECT * FROM finish();
ROLLBACK;

