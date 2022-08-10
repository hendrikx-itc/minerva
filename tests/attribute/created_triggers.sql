BEGIN;

SELECT plan(7);

SELECT attribute_directory.create_attribute_store(
    'some_data_source_name',
    'some_entity_type_name',
    ARRAY[
        ('x', 'integer', 'some column with integer values'),
	('y', 'text', 'some column with text values')
    ]::attribute_directory.attribute_descr[]
);

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

SELECT is_empty(
    $$SELECT modified FROM attribute_directory.attribute_store_modified$$,
    'modification entry should not have been added in advance'
);

INSERT INTO attribute_history.some_data_source_name_some_entity_type_name ("entity_id", "timestamp", "modified", "hash", "first_appearance", "x", "y") VALUES
    (
        1,
        '2016-01-01 00:00:00',
        '2017-07-01 00:00:00',
	'false_hash',
        '2016-01-01 00:00:00',
        17,
        'old'
    );

SELECT set_hasnt(
    $$SELECT hash FROM attribute_history.some_data_source_name_some_entity_type_name$$,
    $$SELECT 'false_hash'::text AS hash FROM attribute_history.some_data_source_name_some_entity_type_name LIMIT 1$$,
    'hash should be added after creation'
);

UPDATE attribute_history.some_data_source_name_some_entity_type_name SET hash = 'false_hash';

SELECT set_hasnt(
    $$SELECT hash FROM attribute_history.some_data_source_name_some_entity_type_name$$,
    $$SELECT 'false_hash'::text AS hash FROM attribute_history.some_data_source_name_some_entity_type_name LIMIT 1$$,
    'hash should be changed after update'
);

SELECT isnt_empty(
    $$SELECT modified FROM attribute_directory.attribute_store_modified$$,
    'modification entry should have been added'
);

SELECT * FROM finish();
ROLLBACK;
