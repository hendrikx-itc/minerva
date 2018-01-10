BEGIN;

SELECT plan(3);

SELECT attribute_directory.create_attribute_store(
    'some_data_source_name',
    'some_entity_type_name',
    ARRAY[
        ('x', 'integer', 'some column with integer values'),
	('y', 'text', 'some column with text values')
    ]::attribute_directory.attribute_descr[]
);

--TODO: create tests regarding the effects of these triggers

SELECT has_trigger(
    'attribute_history',
    'some_data_source_name_some_entity_type_name',
    'set_hash_on_update',
    'set hash on update should exist'
);

SELECT has_trigger(
    'attribute_history',
    'some_data_source_name_some_entity_type_name',
    'set_hash_on_insert',
    'set hash on insert should exist'
);

SELECT has_trigger(
    'attribute_history',
    'some_data_source_name_some_entity_type_name',
    'mark_modified_on_update',
    'mark modified on update should exist'
);
    

SELECT * FROM finish();
ROLLBACK;
