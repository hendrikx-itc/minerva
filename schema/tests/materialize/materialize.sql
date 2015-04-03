BEGIN;

SELECT plan(3);


SELECT trend_directory.create_table_trend_store(
    'test-data',
    'Node',
    '900',
    ARRAY[
        ('x', 'integer', 'some column with integer values')
    ]::trend_directory.trend_descr[]
);


INSERT INTO trend."test-data_Node_qtr_staging"(
    entity_id,
    timestamp,
    modified,
    x
)
VALUES
    (id(directory.dn_to_entity('Network=G01,Node=A001')), '2015-01-21 15:00+00', now(), 42),
    (id(directory.dn_to_entity('Network=G01,Node=A002')), '2015-01-21 15:00+00', now(), 43);


SELECT trend_directory.transfer_staged(table_trend_store)
FROM trend_directory.table_trend_store
WHERE table_trend_store::text = 'test-data_Node_qtr';


SELECT materialization.define(
    trend_directory.create_view_trend_store(
        'vtest', 'Node', '900',
        $view_def$SELECT
    entity_id,
    timestamp,
    now() as modified,
    x
FROM trend."test-data_Node_qtr"$view_def$
    )
);


SELECT has_table(
    'trend',
    'test_Node_qtr',
    'materialized trend table should exist'
);


SELECT
    is(materialization.materialize(type, '2015-01-21 15:00+00'), 2, 'should materialize 2 records')
FROM materialization.type
WHERE type::text = 'vtest_Node_qtr -> test_Node_qtr';

SELECT
    is(materialization.materialize(type, '2015-01-22 11:00+00'), 0, 'should materialize nothing')
FROM materialization.type
WHERE type::text = 'vtest_Node_qtr -> test_Node_qtr';

SELECT * FROM finish();
ROLLBACK;
