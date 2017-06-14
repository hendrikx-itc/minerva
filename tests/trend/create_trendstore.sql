BEGIN;

SELECT plan(2);

SELECT trend.create_trendstore(
	'some_datasource_name',
	'some_entitytype_name',
	'900',
	ARRAY[
		('x', 'integer', 'some column with integer values')
	]::trend.trend_descr[]
);

SELECT has_table(
	'trend',
	'some_datasource_name_some_entitytype_name_qtr',
	'trend table should exist'
);

SELECT columns_are(
    'trend',
    'some_datasource_name_some_entitytype_name_qtr',
    ARRAY[
        'entity_id',
        'timestamp',
        'modified',
        'x'
    ]
);

SELECT * FROM finish();
ROLLBACK;
