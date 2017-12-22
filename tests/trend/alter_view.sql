BEGIN;

/* Code not yet written */

SELECT plan(2);

SELECT trend_directory.create_view_trend_store(
    'test-source', 'test-type', '900',
    ARRAY[
        (
            'test-view-trend-store',
            ARRAY[
                ('x', 'integer', 'some column with integer values')
            ]::trend_directory.trend_descr[]
        )
    ]::trend_directory.view_trend_store_part_descr[]
);

SELECT
    is(x, 1)
FROM trend."test-view-trend-store";

SELECT
    trend_directory.alter_view(view_trend_store, 'SELECT 2 x, 3 y')
FROM trend_directory.view_trend_store
WHERE view_trend_store.name = 'test-view-trend-store';

SELECT
    is(x, 2)
FROM trend."test-view-trend-store";

SELECT * FROM finish();
ROLLBACK;
