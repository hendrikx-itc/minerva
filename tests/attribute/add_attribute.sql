BEGIN;

SELECT plan(21);

SELECT attribute_directory.create_attribute_store(
    'some_data_source_name',
    'some_entity_type_name',
    ARRAY[
        ('x', 'integer', 'some column with integer values'),
	('y', 'text', 'some column with text values')
    ]::attribute_directory.attribute_descr[]
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

SELECT attribute_directory.create_attribute(
    attribute_directory.get_attribute_store('some_data_source_name', 'some_entity_type_name'),
    'z',
    'integer',
    'a new integer column'
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
	'y',
	'z'
    ],
    'column should be added without removing any column'
);

SELECT col_type_is(
    'attribute_history',
    'some_data_source_name_some_entity_type_name',
    'z',
    'pg_catalog',
    'integer',
    'Defined column should be of correct type'
    );

SELECT columns_are(
    'attribute_base',
    'some_data_source_name_some_entity_type_name',
    ARRAY[
        'entity_id',
        'timestamp',
        'x',
	'y',
	'z'
    ],
    'base table should have column added'
);

SELECT columns_are(
    'attribute_staging',
    'some_data_source_name_some_entity_type_name',
    ARRAY[
        'entity_id',
        'timestamp',
        'x',
	'y',
	'z'
    ],
    'staging table should have column added'
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
	'y',
	'z'
    ],
    'compacted tmp table should have column added'
);

SELECT columns_are(
    'attribute_history',
    'some_data_source_name_some_entity_type_name_curr_ptr',
    ARRAY[
        'entity_id',
        'timestamp'
    ],
    'curr_ptr table should not be changed'
);

SELECT columns_are(
    'attribute_staging',
    'some_data_source_name_some_entity_type_name_new',
    ARRAY[
        'entity_id',
	'timestamp',
	'x',
	'y',
	'z'
	],
    'staging new view should have column added'
);

SELECT columns_are(
    'attribute_staging',
    'some_data_source_name_some_entity_type_name_modified',
    ARRAY[
        'entity_id',
        'timestamp',
        'x',
	'y',
	'z'
    ],
    'staging modified view should have column added'
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
	'y',
	'z'
	],
    'attribute curr view should have column added'
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
	'y',
	'z'
	],
    'attribute history compacted view should have column added'
);

PREPARE second_try AS SELECT attribute_directory.create_attribute(
    attribute_directory.get_attribute_store('some_data_source_name', 'some_entity_type_name'),
    'z',
    'text',
    'a new text column'
);

SELECT throws_like('second_try', '%unique constraint%', 'Trying to create an attribute store twice should create an error');

SELECT attribute_directory.drop_attribute(
    attribute_directory.get_attribute_store('some_data_source_name', 'some_entity_type_name'),
    'x'
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
	'y',
	'z'
    ],
    'column should be removed'
);

SELECT columns_are(
    'attribute_base',
    'some_data_source_name_some_entity_type_name',
    ARRAY[
        'entity_id',
        'timestamp',
	'y',
	'z'
    ],
    'base table should have column removed'
);

SELECT columns_are(
    'attribute_staging',
    'some_data_source_name_some_entity_type_name',
    ARRAY[
        'entity_id',
        'timestamp',
	'y',
	'z'
    ],
    'staging table should have column removed'
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
	'y',
	'z'
    ],
    'compacted tmp table should have column removed'
);

SELECT columns_are(
    'attribute_staging',
    'some_data_source_name_some_entity_type_name_new',
    ARRAY[
        'entity_id',
	'timestamp',
	'y',
	'z'
	],
    'staging new view should have column removed'
);

SELECT columns_are(
    'attribute_staging',
    'some_data_source_name_some_entity_type_name_modified',
    ARRAY[
        'entity_id',
        'timestamp',
	'y',
	'z'
    ],
    'staging modified view should have column removed'
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
	'y',
	'z'
	],
    'attribute curr view should have column removed'
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
	'y',
	'z'
	],
    'attribute history compacted view should have column removed'
);

PREPARE second_drop AS SELECT attribute_directory.drop_attribute(
    attribute_directory.get_attribute_store('some_data_source_name', 'some_entity_type_name'),
    'a'
);

SELECT throws_like('second_drop', '%does not exist%', 'non-existing attributes cannot be removed');


SELECT * FROM finish();
ROLLBACK;
