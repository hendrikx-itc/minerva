BEGIN;

SELECT plan(3);

SELECT attribute_directory.create_attributestore(
	'test',
	'Node',
	ARRAY[
		('x', 'integer', 'some column with integer values')
	]::attribute_directory.attribute_descr[]
);

--
-- Test if the attribute store is created
--
SELECT columns_are(
    'attribute_history',
    'test_Node',
    ARRAY[
        'entity_id',
        'timestamp',
        'modified',
        'hash',
        'first_appearance',
        'x'
    ]
);

--
-- Test if the new column is correctly added
--
SELECT attribute_directory.check_attributes_exist(
    ARRAY[
       (NULL, attributestore.id, 'some column with floating point values', 'y', 'double precision') 
    ]::attribute_directory.attribute[]
)
FROM attribute_directory.attributestore
WHERE attributestore::text = 'test_Node';

SELECT columns_are(
    'attribute_history',
    'test_Node',
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

CREATE VIEW trend.uses_attribute AS
SELECT * FROM attribute_history."test_Node";

--
-- Test if the new column is correctly added when there is a dependent view
--
SELECT attribute_directory.check_attributes_exist(
    ARRAY[
       (NULL, attributestore.id, 'some column with text values', 'z', 'text')
    ]::attribute_directory.attribute[]
)
FROM attribute_directory.attributestore
WHERE attributestore::text = 'test_Node';

SELECT columns_are(
    'attribute_history',
    'test_Node',
    ARRAY[
        'entity_id',
        'timestamp',
        'modified',
        'hash',
        'first_appearance',
        'x',
        'y',
        'z'
    ]
);

SELECT * FROM finish();
ROLLBACK;
