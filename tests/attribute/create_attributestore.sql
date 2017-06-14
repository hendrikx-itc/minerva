BEGIN;

SELECT plan(2);

SELECT attribute_directory.create_attributestore(
	'some_datasource_name',
	'some_entitytype_name',
	ARRAY[
		('x', 'integer', 'some column with integer values')
	]::attribute_directory.attribute_descr[]
);

SELECT has_table(
	'attribute_history',
	'some_datasource_name_some_entitytype_name',
	'attribute history table should exist'
);

SELECT columns_are(
    'attribute_history',
    'some_datasource_name_some_entitytype_name',
    ARRAY[
        'entity_id',
        'timestamp',
        'modified',
        'hash',
        'first_appearance',
        'x'
    ]
);

SELECT * FROM finish();
ROLLBACK;
