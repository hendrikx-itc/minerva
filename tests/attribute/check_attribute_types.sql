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
-- Test if the column type is updated correctly
--
SELECT attribute_directory.check_attribute_types(
    ARRAY[
       (NULL, attributestore.id, 'some column with integer values', 'x', 'double precision')
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
        'x'
    ]
);

CREATE VIEW trend.uses_attribute AS
SELECT * FROM attribute_history."test_Node";

--
-- Test if the column type is updated correctly when there is a dependent view
--
SELECT attribute_directory.check_attribute_types(
    ARRAY[
       (NULL, attributestore.id, 'some column with text values', 'x', 'text')
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
        'x'
    ]
);

SELECT * FROM finish();
ROLLBACK;
