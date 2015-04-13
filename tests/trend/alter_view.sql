BEGIN;

SELECT plan(2);

SELECT trend.create_view(
    trend.define_view(
        trend.attributes_to_view_trendstore('test-source', 'test-type', '900'),
        'SELECT 1 x, 2 y'
    )
);

SELECT
    is(x, 1)
FROM trend."test-source_test-type_qtr";

SELECT
    trend.alter_view(view, 'SELECT 2 x, 3 y')
FROM trend.view
WHERE view::text = 'test-source_test-type_qtr';

SELECT
    is(x, 2)
FROM trend."test-source_test-type_qtr";

SELECT * FROM finish();
ROLLBACK;
