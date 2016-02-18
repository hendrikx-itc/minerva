BEGIN;

SELECT plan(2);

SELECT trend_directory.create_view_trend_store(
    'test-source', 'test-type', '900',
    'SELECT 1 x, 2 y'
);

SELECT
    is(x, 1)
FROM trend."test-source_test-type_qtr";

SELECT
    trend_directory.alter_view(view_trend_store, 'SELECT 2 x, 3 y')
FROM trend_directory.view_trend_store
WHERE view_trend_store::text = 'test-source_test-type_qtr';

SELECT
    is(x, 2)
FROM trend."test-source_test-type_qtr";

SELECT * FROM finish();
ROLLBACK;
