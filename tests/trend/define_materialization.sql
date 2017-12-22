BEGIN;

SELECT plan(2);


SELECT trend_directory.create_table_trend_store(
    'test-data',
    'Node',
    '900',
    86400,
    ARRAY[
        (
            'test-trend-store',
            ARRAY[
                ('x', 'integer', 'some column with integer values')
            ]::trend_directory.trend_descr[]
        )
    ]::trend_directory.table_trend_store_part_descr[]
);

SELECT isnt(
    trend_directory.define_materialization(
        trend_directory.create_view_trend_store(
            'test-view-trend-store', 'vtest', 'Node', '900',
            $view_def$SELECT
        id(directory.dn_to_entity('Network=G01,Node=A001')) entity_id,
        '2015-01-21 15:00'::timestamp with time zone AS timestamp,
        now() AS modified,
        42 AS x$view_def$
        ),
        trend_directory.create_table_trend_store('target-trend-store', 'test-materialized', 'Node', '900', 86400, ARRAY[]::trend_directory.trend_descr[])
    ),
    NULL
);

SELECT is(
    '''this code'''::text,
    '''testable code'''::text,
    'tests to be written when the code has been made working'
);

SELECT * FROM finish();
ROLLBACK;
