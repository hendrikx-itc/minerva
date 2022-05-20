BEGIN;

SELECT plan(27);

CALL attribute_directory.create_attribute_store(
    'create_attributestore_ds',
    'create_attributestore_et',
    ARRAY[
        ('x', 'integer', 'some column with integer values'),
	('y', 'text', 'some column with text values')
    ]::attribute_directory.attribute_descr[]
);

SELECT has_table(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et',
    'attribute history table should exist'
);

SELECT columns_are(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et',
    ARRAY[
        'id',
        'entity_id',
        'timestamp',
        'modified',
        'hash',
        'first_appearance',
	'end',
        'x',
	'y'
    ]
);

SELECT col_type_is(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et',
    'x',
    'pg_catalog',
    'integer',
    'Defined column should be of correct type'
    );

SELECT col_type_is(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et',
    'y',
    'pg_catalog',
    'text',
    'Second defined column should be of correct type'
    );

SELECT has_table(
    'attribute_base',
    'create_attributestore_ds_create_attributestore_et',
    'attribute base table should exist'
    );

SELECT columns_are(
    'attribute_base',
    'create_attributestore_ds_create_attributestore_et',
    ARRAY[
        'entity_id',
        'timestamp',
	'end',
        'x',
	'y'
    ]
);

SELECT has_table(
    'attribute_staging',
    'create_attributestore_ds_create_attributestore_et',
    'attribute staging table should exist'
    );

SELECT columns_are(
    'attribute_staging',
    'create_attributestore_ds_create_attributestore_et',
    ARRAY[
        'entity_id',
        'timestamp',
	'end',
        'x',
	'y'
    ]
);

SELECT has_table(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et_compacted_tmp',
    'temporary compacted table should exist'
    );

SELECT columns_are(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et_compacted_tmp',
    ARRAY[
        'id', 
        'entity_id',
        'timestamp',
	'first_appearance',
	'end',
	'modified',
	'hash',
        'x',
	'y'
    ]
);

SELECT has_table(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et_curr_ptr',
    'current pointer table should exist'
    );

SELECT columns_are(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et_curr_ptr',
    ARRAY[
        'id'
    ]
);

SELECT has_view(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et_changes',
    'changes view should exist'
);

SELECT columns_are(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et_changes',
    ARRAY[
        'entity_id',
	'timestamp',
	'change'
	]
);

SELECT has_view(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et_run_length',
    'run length view should exist'
);

SELECT columns_are(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et_run_length',
    ARRAY[
        'id',
	'entity_id',
	'start',
	'end',
	'first_appearance',
	'end',
	'modified',
	'run_length'
	]
);

SELECT has_view(
    'attribute_staging',
    'create_attributestore_ds_create_attributestore_et_new',
    'staging new view should exist'
);

SELECT columns_are(
    'attribute_staging',
    'create_attributestore_ds_create_attributestore_et_new',
    ARRAY[
        'entity_id',
	'timestamp',
	'end',
	'x',
	'y'
	]
);

SELECT has_view(
    'attribute_staging',
    'create_attributestore_ds_create_attributestore_et_modified',
    'staging modified view should exist'
);

SELECT columns_are(
    'attribute_staging',
    'create_attributestore_ds_create_attributestore_et_modified',
    ARRAY[
        'entity_id',
        'timestamp',
        'x',
	'y'
    ]
);

SELECT has_view(
    'attribute',
    'create_attributestore_ds_create_attributestore_et',
    'attribute curr view should exist'
);

SELECT columns_are(
    'attribute',
    'create_attributestore_ds_create_attributestore_et',
    ARRAY[
        'id',
        'entity_id',
	'timestamp',
        'modified',
        'hash',
        'first_appearance',
	'end',
	'x',
	'y'
	]
);

SELECT has_view(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et_compacted',
    'attribute history compacted view should exist'
);

SELECT columns_are(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et_compacted',
    ARRAY[
        'id',
        'entity_id',
	'timestamp',
	'first_appearance',
	'end',
        'modified',
        'hash',
	'x',
	'y'
	]
);

SELECT has_view(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et_curr_selection',
    'attribute history curr selection view should exist'
);

SELECT columns_are(
    'attribute_history',
    'create_attributestore_ds_create_attributestore_et_curr_selection',
    ARRAY[
         'id'
         ]
);

CREATE FUNCTION "attribute_directory"."create_attribute_store_prep"("data_source_name" text, "entity_type_name" text, "attributes" attribute_directory.attribute_descr[])
    RETURNS void
AS $$
    CALL attribute_directory.create_attribute_store($1, $2, $3);
$$ LANGUAGE sql VOLATILE;


PREPARE second_try AS SELECT attribute_directory.create_attribute_store_prep(
    'some_other_ds_name',
    'some_other_et_name',
    ARRAY[
        ('z', 'text', 'some column with text values')
    ]::attribute_directory.attribute_descr[]
);

SELECT throws_like('second_try', '%already exists%', 'Trying to create an attribute store twice should create an error');

SELECT * FROM finish();
ROLLBACK;
