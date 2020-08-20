BEGIN;

SELECT plan(1);


SELECT trend_directory.create_trend_view(
    'test-source', 'test-type', '15m'::interval,
    ARRAY[
        (
            'test-view-trend-store',
            ARRAY[
                ('x', 'integer', 'some column with integer values', 'sum', 'sum', '{}'),
		('y', 'double precision', 'some column with numerical values', 'max', 'max', '{}')
            ]::trend_directory.trend_descr[]
        )
    ]::trend_directory.trend_view_part_descr[]
);

/* tests not yet made because the code did not exist */

--SELECT has_view(
--    'trend',
--    'test-view-trend-store',
--    'view should be created'
--);

SELECT is(
    '''this code'''::text,
    '''testable code'''::text,
    'tests to be written when the code has been made working'
);

SELECT * FROM finish();
ROLLBACK;

/*
Old test code; to be checked when this is supposed to be working again
*/

/*
BEGIN;

SELECT plan(5);

SELECT trend_directory.create_view_trend_store(
    'test-view-trend-store', 'test-source', 'test-type', '900',
    'SELECT 1::integer x, 2.0::double precision y'
);

SELECT has_view(
    'trend',
    trend_directory.view_name(view_trend_store),
    'view should be created'
)
FROM trend_directory.view_trend_store
WHERE view_trend_store::text = 'test-view-trend-store';

SELECT col_type_is(
    'trend',
    trend_directory.view_name(view_trend_store),
    'x',
    'integer',
    'column x should be integer'
)
FROM trend_directory.view_trend_store
WHERE view_trend_store::text = 'test-view-trend-store';

SELECT col_type_is(
    'trend',
    trend_directory.view_name(view_trend_store),
    'y',
    'double precision',
    'column y should be double precision'
)
FROM trend_directory.view_trend_store
WHERE view_trend_store::text = 'test-view-trend-store';

SELECT
    is(x, 1, 'x should equal 1')
FROM trend."test-view-trend-store";

SELECT is(
    array_agg((trend.name, trend.data_type, trend.description)::trend_directory.trend_descr),
    ARRAY[
        ('x', 'integer', 'deduced from view'),
        ('y', 'double precision', 'deduced from view')
    ]::trend_directory.trend_descr[]
)
FROM trend_directory.trend
JOIN trend_directory.trend_store ON trend_store.id = trend.trend_store_id
WHERE trend_store::text = 'test-view-trend-store';

SELECT * FROM finish();
ROLLBACK;
*/
