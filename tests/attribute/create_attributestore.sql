BEGIN;

SELECT plan(3);

SELECT attribute_directory.create_attribute_store(
    'some_data_source_name',
    'some_entity_type_name',
    ARRAY[
        ('x', 'integer', 'some column with integer values')
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
        'x'
    ]
);

PREPARE second_try AS SELECT attribute_directory.create_attribute_store(
    'some_other_data_source_name',
    'some_other_entity_type_name',
    ARRAY[
        ('y', 'text', 'some column with text values')
    ]::attribute_directory.attribute_descr[]
);

SELECT throws_like('second_try', '%already exists%', 'Trying to create an attribute store twice should create an error');

SELECT * FROM finish();
ROLLBACK;
