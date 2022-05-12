BEGIN;

SELECT plan(27);

CALL attribute_directory.create_attribute_store(
    'create_attributestore_data_source',
    'create_attributestore_entity_type',
    ARRAY[
        ('x', 'integer', 'some column with integer values'),
	('y', 'text', 'some column with text values')
    ]::attribute_directory.attribute_descr[]
);

SELECT has_table(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type',
    'attribute history table should exist'
);

SELECT columns_are(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type',
    ARRAY[
        'id',
        'entity_id',
        'timestamp',
        'modified',
        'hash',
        'first_appearance',
        'x',
	'y'
    ]
);

SELECT col_type_is(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type',
    'x',
    'pg_catalog',
    'integer',
    'Defined column should be of correct type'
    );

SELECT col_type_is(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type',
    'y',
    'pg_catalog',
    'text',
    'Second defined column should be of correct type'
    );

SELECT has_table(
    'attribute_base',
    'create_attributestore_data_source_create_attributestore_entity_type',
    'attribute base table should exist'
    );

SELECT columns_are(
    'attribute_base',
    'create_attributestore_data_source_create_attributestore_entity_type',
    ARRAY[
        'entity_id',
        'timestamp',
        'x',
	'y'
    ]
);

SELECT has_table(
    'attribute_staging',
    'create_attributestore_data_source_create_attributestore_entity_type',
    'attribute staging table should exist'
    );

SELECT columns_are(
    'attribute_staging',
    'create_attributestore_data_source_create_attributestore_entity_type',
    ARRAY[
        'entity_id',
        'timestamp',
        'x',
	'y'
    ]
);

SELECT has_table(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type_compacted_tmp',
    'temporary compacted table should exist'
    );

SELECT columns_are(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type_compacted_tmp',
    ARRAY[
        'entity_id',
        'timestamp',
	'end',
	'modified',
	'hash',
        'x',
	'y'
    ]
);

SELECT has_table(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type_curr_ptr',
    'current pointer table should exist'
    );

SELECT columns_are(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type_curr_ptr',
    ARRAY[
        'id'
    ]
);

SELECT has_view(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type_changes',
    'changes view should exist'
);

SELECT columns_are(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type_changes',
    ARRAY[
        'entity_id',
	'timestamp',
	'change'
	]
);

SELECT has_view(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type_run_length',
    'run length view should exist'
);

SELECT columns_are(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type_run_length',
    ARRAY[
	'entity_id',
	'start',
	'end',
	'first_appearance',
	'modified',
	'run_length'
	]
);

SELECT has_view(
    'attribute_staging',
    'create_attributestore_data_source_create_attributestore_entity_type_new',
    'staging new view should exist'
);

SELECT columns_are(
    'attribute_staging',
    'create_attributestore_data_source_create_attributestore_entity_type_new',
    ARRAY[
        'entity_id',
	'timestamp',
	'x',
	'y'
	]
);

SELECT has_view(
    'attribute_staging',
    'create_attributestore_data_source_create_attributestore_entity_type_modified',
    'staging modified view should exist'
);

SELECT columns_are(
    'attribute_staging',
    'create_attributestore_data_source_create_attributestore_entity_type_modified',
    ARRAY[
        'entity_id',
        'timestamp',
        'x',
	'y'
    ]
);

SELECT has_view(
    'attribute',
    'create_attributestore_data_source_create_attributestore_entity_type',
    'attribute curr view should exist'
);

SELECT columns_are(
    'attribute',
    'create_attributestore_data_source_create_attributestore_entity_type',
    ARRAY[
        'id',
        'entity_id',
	'timestamp',
        'modified',
        'hash',
        'first_appearance',
	'x',
	'y'
	]
);

SELECT has_view(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type_compacted',
    'attribute history compacted view should exist'
);

SELECT columns_are(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type_compacted',
    ARRAY[
        'entity_id',
	'timestamp',
	'end',
        'modified',
        'hash',
	'x',
	'y'
	]
);

SELECT has_view(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type_curr_selection',
    'attribute history curr selection view should exist'
);

SELECT columns_are(
    'attribute_history',
    'create_attributestore_data_source_create_attributestore_entity_type_curr_selection',
    ARRAY[
         'id'
         ]
);

PREPARE second_try AS CALL attribute_directory.create_attribute_store(
    'some_other_data_source_name',
    'some_other_entity_type_name',
    ARRAY[
        ('z', 'text', 'some column with text values')
    ]::attribute_directory.attribute_descr[]
);

SELECT throws_like('second_try', '%already exists%', 'Trying to create an attribute store twice should create an error');

SELECT * FROM finish();
ROLLBACK;
