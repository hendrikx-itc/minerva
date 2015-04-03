BEGIN;

SELECT plan(1);

SELECT trend_directory.create_table_trend_store(
    'test',
    'Node',
    '900',
    ARRAY[
        ('x', 'integer', 'some column with integer values')
    ]::trend_directory.trend_descr[],
    '3600'
);


SELECT
    trend_directory.create_partition(table_trend_store, 379958)
FROM trend_directory.table_trend_store
WHERE table_trend_store::text = 'test_Node_qtr';

SELECT has_table(
    'trend_partition',
    'test_Node_qtr_379958',
    'trend partition table should exist'
);

SELECT * FROM finish();
ROLLBACK;
