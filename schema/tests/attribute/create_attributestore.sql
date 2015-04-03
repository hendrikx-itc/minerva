BEGIN;

SELECT plan(2);

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

SELECT * FROM finish();
ROLLBACK;
