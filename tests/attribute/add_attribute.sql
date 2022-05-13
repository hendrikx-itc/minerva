BEGIN;

SELECT plan(21);

CALL attribute_directory.create_attribute_store(
    'add_attribute_ds',
    'add_attribute_et',
    ARRAY[
        ('x', 'integer', 'some column with integer values'),
	('y', 'text', 'some column with text values')
    ]::attribute_directory.attribute_descr[]
);

SELECT columns_are(
    'attribute_history',
    'add_attribute_ds_add_attribute_et',
    ARRAY[
        'id',
        'entity_id',
        'timestamp',
	'end',
        'modified',
        'hash',
        'first_appearance',
        'x',
	'y'
    ]
);

SELECT attribute_directory.create_attribute(
    attribute_directory.get_attribute_store('add_attribute_ds', 'add_attribute_et'),
    'z',
    'integer',
    'a new integer column'
);

SELECT columns_are(
    'attribute_history',
    'add_attribute_ds_add_attribute_et',
    ARRAY[
        'id',
        'entity_id',
        'timestamp',
        'modified',
        'hash',
        'first_appearance',
        'x',
	'y',
	'z'
    ],
    'column should be added without removing any column'
);

SELECT col_type_is(
    'attribute_history',
    'add_attribute_ds_add_attribute_et',
    'z',
    'pg_catalog',
    'integer',
    'Defined column should be of correct type'
    );

SELECT columns_are(
    'attribute_base',
    'add_attribute_ds_add_attribute_et',
    ARRAY[
        'entity_id',
        'timestamp',
	'end',
        'x',
	'y',
	'z'
    ],
    'base table should have column added'
);

SELECT columns_are(
    'attribute_staging',
    'add_attribute_ds_add_attribute_et',
    ARRAY[
        'entity_id',
        'timestamp',
	'end',
        'x',
	'y',
	'z'
    ],
    'staging table should have column added'
);

SELECT columns_are(
    'attribute_history',
    'add_attribute_ds_add_attribute_et_compacted_tmp',
    ARRAY[
        'id',
        'entity_id',
        'timestamp',
	'end',
	'modified',
	'first_appearance',
	'hash',
        'x',
	'y',
	'z'
    ],
    'compacted tmp table should have column added'
);

SELECT columns_are(
    'attribute_history',
    'add_attribute_ds_add_attribute_et_curr_ptr',
    ARRAY[
        'id'
    ],
    'curr_ptr table should not be changed'
);

SELECT columns_are(
    'attribute_staging',
    'add_attribute_ds_add_attribute_et_new',
    ARRAY[
        'entity_id',
	'timestamp',
	'end',
	'x',
	'y',
	'z'
	],
    'staging new view should have column added'
);

SELECT columns_are(
    'attribute_staging',
    'add_attribute_ds_add_attribute_et_modified',
    ARRAY[
        'entity_id',
        'timestamp',
	'end',
        'x',
	'y',
	'z'
    ],
    'staging modified view should have column added'
);

SELECT columns_are(
    'attribute',
    'add_attribute_ds_add_attribute_et',
    ARRAY[
        'id',
        'entity_id',
	'timestamp',
        'modified',
        'hash',
        'first_appearance',
	'end',
	'x',
	'y',
	'z'
	],
    'attribute curr view should have column added'
);

SELECT columns_are(
    'attribute_history',
    'add_attribute_ds_add_attribute_et_compacted',
    ARRAY[
        'id',
        'entity_id',
	'timestamp',
	'first_appearance',
	'end',
        'modified',
        'hash',
	'x',
	'y',
	'z'
	],
    'attribute history compacted view should have column added'
);

PREPARE second_try AS SELECT attribute_directory.create_attribute(
    attribute_directory.get_attribute_store('add_attribute_ds', 'add_attribute_et'),
    'z',
    'text',
    'a new text column'
);

SELECT throws_like('second_try', '%duplicate key value%', 'Trying to create an attribute store twice should create an error');

SELECT attribute_directory.drop_attribute(
    attribute_directory.get_attribute_store('add_attribute_ds', 'add_attribute_et'),
    'x'
);

SELECT columns_are(
    'attribute_history',
    'add_attribute_ds_add_attribute_et',
    ARRAY[
        'id',
        'entity_id',
        'timestamp',
        'modified',
        'hash',
        'first_appearance',
	'end',
	'y',
	'z'
    ],
    'column should be removed'
);

SELECT columns_are(
    'attribute_base',
    'add_attribute_ds_add_attribute_et',
    ARRAY[
        'entity_id',
        'timestamp',
	'end',
	'y',
	'z'
    ],
    'base table should have column removed'
);

SELECT columns_are(
    'attribute_staging',
    'add_attribute_ds_add_attribute_et',
    ARRAY[
        'entity_id',
        'timestamp',
	'end',
	'y',
	'z'
    ],
    'staging table should have column removed'
);

SELECT columns_are(
    'attribute_history',
    'add_attribute_ds_add_attribute_et_compacted_tmp',
    ARRAY[
        'id',
        'entity_id',
        'timestamp',
	'end',
	'modified',
	'first_appearance',
	'hash',
	'y',
	'z'
    ],
    'compacted tmp table should have column removed'
);

SELECT columns_are(
    'attribute_staging',
    'add_attribute_ds_add_attribute_et_new',
    ARRAY[
        'entity_id',
	'timestamp',
	'end',
	'y',
	'z'
	],
    'staging new view should have column removed'
);

SELECT columns_are(
    'attribute_staging',
    'add_attribute_ds_add_attribute_et_modified',
    ARRAY[
        'entity_id',
        'timestamp',
	'end',
	'y',
	'z'
    ],
    'staging modified view should have column removed'
);

SELECT columns_are(
    'attribute',
    'add_attribute_ds_add_attribute_et',
    ARRAY[
        'id',
        'entity_id',
	'timestamp',
        'modified',
        'hash',
        'first_appearance',
	'end',
	'y',
	'z'
	],
    'attribute curr view should have column removed'
);

SELECT columns_are(
    'attribute_history',
    'add_attribute_ds_add_attribute_et_compacted',
    ARRAY[
        'id',
        'entity_id',
	'timestamp',
	'end',
        'modified',
	'first_appearance',
        'hash',
	'y',
	'z'
	],
    'attribute history compacted view should have column removed'
);

PREPARE second_drop AS SELECT attribute_directory.drop_attribute(
    attribute_directory.get_attribute_store('add_attribute_ds', 'add_attribute_et'),
    'a'
);

SELECT throws_like('second_drop', '%does not exist%', 'non-existing attributes cannot be removed');


SELECT * FROM finish();
ROLLBACK;
