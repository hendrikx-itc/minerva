BEGIN;

SELECT plan(2);

SELECT attribute_directory.create_attributestore(
	'some_datasource_name',
	'some_entitytype_name',
	ARRAY[
		('x', 'integer', 'some column with integer values')
	]::attribute_directory.attribute_descr[]
);

INSERT INTO attribute_staging."some_datasource_name_some_entitytype_name"(
    entity_id,
    timestamp,
    x
) VALUES (
    (directory.dn_to_entity('Node=001')).id,
    '2014-11-17 13:00',
    42
);

SELECT attribute_directory.transfer_staged(attributestore)
FROM attribute_directory.attributestore
WHERE attributestore::text = 'some_datasource_name_some_entitytype_name';

SELECT is(
    x,
    42
)
FROM attribute_history."some_datasource_name_some_entitytype_name" a
JOIN directory.entity ON entity.id = a.entity_id
WHERE entity.dn = 'Node=001';

-- Alter attribute table

SELECT attribute_directory.check_attributes_exist(
    ARRAY[
       (NULL, attributestore.id, 'some column with floating point values', 'y', 'double precision') 
    ]::attribute_directory.attribute[]
)
FROM attribute_directory.attributestore
WHERE attributestore::text = 'some_datasource_name_some_entitytype_name';

INSERT INTO attribute_staging."some_datasource_name_some_entitytype_name"(
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

SELECT attribute_directory.transfer_staged(attributestore)
FROM attribute_directory.attributestore
WHERE attributestore::text = 'some_datasource_name_some_entitytype_name';

SELECT is(
    y,
    43.0::double precision
)
FROM attribute_history."some_datasource_name_some_entitytype_name" a
JOIN directory.entity ON entity.id = a.entity_id
WHERE entity.dn = 'Node=001';

SELECT * FROM finish();
ROLLBACK;
