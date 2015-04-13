BEGIN;

SELECT plan(3);

SELECT attribute_directory.create_attributestore(
	'test',
	'Node',
	ARRAY[
		('x', 'integer', 'some column with integer values')
	]::attribute_directory.attribute_descr[]
);


INSERT INTO attribute_staging."test_Node"(entity_id, timestamp, x)
VALUES
    (id(directory.dn_to_entity('Network=A,Node=001')), '2015-01-02 10:00', 42),
    (id(directory.dn_to_entity('Network=A,Node=001')), '2015-01-02 11:00', 43);

SELECT attribute_directory.transfer_staged(attributestore)
FROM attribute_directory.attributestore
WHERE attributestore::text = 'test_Node';

SELECT is(
    (attribute_history."test_Node_at"(id(directory.dn_to_entity('Network=A,Node=001')), '2015-01-02 11:00')).x,
    43,
    'value should be found for the exact timestamp'
);

SELECT is(
    (attribute_history."test_Node_at"(id(directory.dn_to_entity('Network=A,Node=001')), '2015-01-02 10:01')).x,
    42,
    'value should be found for a timestamp after the attribute change'
);

SELECT
    is(entity.dn, 'Network=A,Node=001', 'at-function should be usable in a where-clause')
FROM
    directory.entity
WHERE (attribute_history."test_Node_at"(entity.id, '2015-01-02 10:01')).x = 42;

SELECT * FROM finish();
ROLLBACK;
