BEGIN;

SELECT plan(2);


SELECT trend_directory.create_table_trend_store(
    'test-data',
    'Node',
    '900',
    ARRAY[
        ('x', 'integer', 'some column with integer values')
    ]::trend_directory.trend_descr[]
);


SELECT materialization.define(
    trend_directory.create_view_trend_store(
        'vtest', 'Node', '900',
        $view_def$SELECT
    id(directory.dn_to_entity('Network=G01,Node=A001')) entity_id,
    '2015-01-21 15:00'::timestamp with time zone AS timestamp,
    now() AS modified,
    42 AS x$view_def$
    )
);


SELECT has_table(
    'trend',
    'test_Node_qtr',
    'materialized trend table should exist'
);


SELECT throws_matching(
    $query$
    SELECT materialization.define(
        trend_directory.create_view_trend_store(
            'test-wrong-name', 'Node', '900',
            $$SELECT
        id(directory.dn_to_entity('Network=G01,Node=A001')) entity_id,
        '2015-01-21 15:00'::timestamp with time zone AS timestamp,
        now() AS modified,
        42 AS x$$
        )
    );
    $query$,
    'does not start with a ''v'''
);

SELECT * FROM finish();
ROLLBACK;
