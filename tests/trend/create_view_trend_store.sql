BEGIN;

SELECT plan(5);

SELECT trend_directory.create_view_trend_store(
    'test-source', 'test-type', '900',
    'SELECT 1::integer x, 2.0::double precision y'
);

SELECT has_view('trend', 'test-source_test-type_qtr', 'view should be created');

SELECT col_type_is('trend', 'test-source_test-type_qtr', 'x', 'integer', 'column x should be integer');

SELECT col_type_is('trend', 'test-source_test-type_qtr', 'y', 'double precision', 'column y should be double precision');

SELECT
    is(x, 1, 'x should equal 1')
FROM trend."test-source_test-type_qtr";

SELECT is(
    array_agg((trend.name, trend.data_type, trend.description)::trend_directory.trend_descr),
    ARRAY[
        ('x', 'integer', 'deduced from view'),
        ('y', 'double precision', 'deduced from view')
    ]::trend_directory.trend_descr[]
)
FROM trend_directory.trend
JOIN trend_directory.trend_store ON trend_store.id = trend.trend_store_id
WHERE trend_store::text = 'test-source_test-type_qtr';

SELECT * FROM finish();
ROLLBACK;
