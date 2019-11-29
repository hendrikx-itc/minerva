BEGIN;

SELECT plan(1);

SELECT directory.create_data_source('datasource');

SELECT directory.create_entity_type('entitytype');

SELECT trend_directory.create_trend_store(
    'test-data',
    'Node',
    '15m'::interval,
    '1 day'::interval,
    ARRAY[
        (
            'test-trend-store',
            ARRAY[
                ('x', 'integer', 'some column with integer values', 'max', 'max', '{}')
            ]::trend_directory.trend_descr[],
	    ARRAY[]::trend_directory.generated_trend_descr[]
        )
    ]::trend_directory.trend_store_part_descr[]
);

SELECT is(
    '''this code'''::text,
    '''testable code'''::text,
    'tests to be written when the code has been made working'
);

SELECT * FROM finish();
ROLLBACK;
