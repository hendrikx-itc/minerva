BEGIN;

SELECT plan(3);


SELECT trend_directory.create_table_trend_store(
    'test-data',
    'Node',
    '900',
    86400,
    ARRAY[
        ('x', 'integer', 'some column with integer values')
    ]::trend_directory.trend_descr[]
);


DO LANGUAGE plpgsql
$QUERY$
BEGIN
EXECUTE format(
    $$
    INSERT INTO trend.%I(
        entity_id,
        timestamp,
        modified,
        x
    )
    VALUES
        (id(directory.dn_to_entity('Network=G01,Node=A001')), '2015-01-21 15:00+00', now(), 42),
        (id(directory.dn_to_entity('Network=G01,Node=A002')), '2015-01-21 15:00+00', now(), 43);
    $$,
    (
        SELECT trend_directory.staging_table_name(table_trend_store)
        FROM trend_directory.table_trend_store
        WHERE table_trend_store::text = 'test-data_Node_qtr'
    )
);
END;
$QUERY$;


SELECT trend_directory.transfer_staged(table_trend_store)
FROM trend_directory.table_trend_store
WHERE table_trend_store::text = 'test-data_Node_qtr';


SELECT trend_directory.define_materialization(
    vts,
    trend_directory.create_table_trend_store('test-kpi', 'Node', '900', 86400, vts)
)
FROM trend_directory.create_view_trend_store(
        'vtest', 'Node', '900',
        $view_def$SELECT
    entity_id,
    timestamp,
    now() as modified,
    x
FROM trend."test-data_Node_qtr"$view_def$
) AS vts;


SELECT has_table(
    'trend',
    'test-kpi_Node_qtr',
    'materialized trend table should exist'
);


SELECT
    is(trend_directory.materialize(materialization, '2015-01-21 15:00+00'), 2, 'should materialize 2 records')
FROM trend_directory.materialization
WHERE materialization::text = 'test-kpi_Node_qtr';

SELECT
    is(trend_directory.materialize(materialization, '2015-01-22 11:00+00'), 0, 'should materialize nothing')
FROM trend_directory.materialization
WHERE materialization::text = 'test-kpi_Node_qtr';

SELECT * FROM finish();
ROLLBACK;

