BEGIN;

SELECT plan(27);

SELECT attribute_directory.create_attribute_store(
    'some_data_source_name',
    'some_entity_type_name',
    ARRAY[
        ('x', 'integer', 'some column with integer values'),
	('y', 'text', 'some column with text values')
    ]::attribute_directory.attribute_descr[]
);

SELECT has_table(
    'attribute_history',
    'some_data_source_name_some_entity_type_name',
    'attribute history table should exist'
);

SELECT columns_are(
    'attribute_history',
    'some_data_source_name_some_entity_type_name',
    ARRAY[
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
    'some_data_source_name_some_entity_type_name',
    'x',
    'pg_catalog',
    'integer',
    'Defined column should be of correct type'
    );

SELECT col_type_is(
    'attribute_history',
    'some_data_source_name_some_entity_type_name',
    'y',
    'pg_catalog',
    'text',
    'Second defined column should be of correct type'
    );

SELECT has_table(
    'attribute_base',
    'some_data_source_name_some_entity_type_name',
    'attribute base table should exist'
    );

SELECT columns_are(
    'attribute_base',
    'some_data_source_name_some_entity_type_name',
    ARRAY[
        'entity_id',
        'timestamp',
        'x',
	'y'
    ]
);

SELECT has_table(
    'attribute_staging',
    'some_data_source_name_some_entity_type_name',
    'attribute staging table should exist'
    );

SELECT columns_are(
    'attribute_staging',
    'some_data_source_name_some_entity_type_name',
    ARRAY[
        'entity_id',
        'timestamp',
        'x',
	'y'
    ]
);

SELECT has_table(
    'attribute_history',
    'some_data_source_name_some_entity_type_name_compacted_tmp',
    'temporary compacted table should exist'
    );

SELECT columns_are(
    'attribute_history',
    'some_data_source_name_some_entity_type_name_compacted_tmp',
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
    'some_data_source_name_some_entity_type_name_curr_ptr',
    'current pointer table should exist'
    );

SELECT columns_are(
    'attribute_history',
    'some_data_source_name_some_entity_type_name_curr_ptr',
    ARRAY[
        'entity_id',
        'timestamp'
    ]
);

SELECT has_view(
    'attribute_history',
    'some_data_source_name_some_entity_type_name_changes',
    'changes view should exist'
);

SELECT columns_are(
    'attribute_history',
    'some_data_source_name_some_entity_type_name_changes',
    ARRAY[
	'entity_id',
	'timestamp',
	'change'
	]
);

SELECT has_view(
    'attribute_history',
    'some_data_source_name_some_entity_type_name_run_length',
    'run length view should exist'
);

SELECT columns_are(
    'attribute_history',
    'some_data_source_name_some_entity_type_name_run_length',
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
    'some_data_source_name_some_entity_type_name_new',
    'staging new view should exist'
);

SELECT columns_are(
    'attribute_staging',
    'some_data_source_name_some_entity_type_name_new',
    ARRAY[
        'entity_id',
	'timestamp',
	'x',
	'y'
	]
);

SELECT has_view(
    'attribute_staging',
    'some_data_source_name_some_entity_type_name_modified',
    'staging modified view should exist'
);

SELECT columns_are(
    'attribute_staging',
    'some_data_source_name_some_entity_type_name_modified',
    ARRAY[
        'entity_id',
        'timestamp',
        'x',
	'y'
    ]
);

SELECT has_view(
    'attribute',
    'some_data_source_name_some_entity_type_name',
    'attribute curr view should exist'
);

SELECT columns_are(
    'attribute',
    'some_data_source_name_some_entity_type_name',
    ARRAY[
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
    'some_data_source_name_some_entity_type_name_compacted',
    'attribute history compacted view should exist'
);

SELECT columns_are(
    'attribute_history',
    'some_data_source_name_some_entity_type_name_compacted',
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
    'some_data_source_name_some_entity_type_name_curr_selection',
    'attribute history curr selection view should exist'
);

SELECT columns_are(
    'attribute_history',
    'some_data_source_name_some_entity_type_name_curr_selection',
    ARRAY[
        'entity_id',
	'timestamp'
	]
);

PREPARE second_try AS SELECT attribute_directory.create_attribute_store(
    'some_other_data_source_name',
    'some_other_entity_type_name',
    ARRAY[
        ('z', 'text', 'some column with text values')
    ]::attribute_directory.attribute_descr[]
);

SELECT throws_like('second_try', '%already exists%', 'Trying to create an attribute store twice should create an error');

SELECT * FROM finish();
ROLLBACK;
