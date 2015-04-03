BEGIN;

SELECT plan(2);

SELECT attribute_directory.create_attribute_store(
    'some_data_source_name',
    'some_entity_type_name',
    ARRAY[
        ('x', 'integer', 'some column with integer values')
    ]::attribute_directory.attribute_descr[]
);

INSERT INTO attribute_staging."some_data_source_name_some_entity_type_name"(
    entity_id,
    timestamp,
    x
) VALUES (
    (directory.dn_to_entity('Node=001')).id,
    '2014-11-17 13:00',
    42
);

SELECT attribute_directory.transfer_staged(attribute_store)
FROM attribute_directory.attribute_store
WHERE attribute_store::text = 'some_data_source_name_some_entity_type_name';

SELECT is(
    x,
    42
)
FROM attribute_history."some_data_source_name_some_entity_type_name" a
JOIN directory.entity ON entity.id = a.entity_id
WHERE entity.dn = 'Node=001';

-- Alter attribute table

SELECT attribute_directory.check_attributes_exist(
    attribute_store,
    ARRAY[
       ('y', 'double precision', 'some column with floating point values')
    ]::attribute_directory.attribute_descr[]
)
FROM attribute_directory.attribute_store
WHERE attribute_store::text = 'some_data_source_name_some_entity_type_name';

INSERT INTO attribute_staging."some_data_source_name_some_entity_type_name"(
    entity_id,
    timestamp,
    x,
    y
) VALUES (
    (directory.dn_to_entity('Node=001')).id,
    '2014-11-17 13:00',
    42,
    43.0
);

SELECT attribute_directory.transfer_staged(attribute_store)
FROM attribute_directory.attribute_store
WHERE attribute_store::text = 'some_data_source_name_some_entity_type_name';

SELECT is(
    y,
    43.0::double precision
)
FROM attribute_history."some_data_source_name_some_entity_type_name" a
JOIN directory.entity ON entity.id = a.entity_id
WHERE entity.dn = 'Node=001';

SELECT * FROM finish();
ROLLBACK;
