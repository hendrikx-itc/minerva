BEGIN;

SELECT plan(4);

SELECT attribute_directory.create_attribute_store(
    'test',
    'Node',
    ARRAY[
        ('x', 'integer', 'some column with integer values')
    ]::attribute_directory.attribute_descr[]
);

SELECT directory.create_entity_type('network');
SELECT entity.create_network('A');

INSERT INTO attribute_staging."test_Node"(entity_id, timestamp, x)
VALUES
    ((entity.get_network('A')).id, '2015-01-02 10:00', 42),
    ((entity.get_network('A')).id, '2015-01-02 11:00', 43);

SELECT attribute_directory.transfer_staged(attribute_store)
FROM attribute_directory.attribute_store
WHERE attribute_store::text = 'test_Node';

SELECT is(
    (attribute_history."test_Node_at"((entity.get_network('A')).id, '2015-01-02 11:00')).x,
    43,
    'value should be found for the exact timestamp'
);

SELECT is(
    (attribute_history."test_Node_at"((entity.get_network('A')).id, '2015-01-02 10:01')).x,
    42,
    'value should be found for a timestamp after the attribute change'
);

SELECT is(
    (attribute_history."test_Node_at"((entity.get_network('A')).id, '2015-01-02 09:59')).x,
    null,
    'value should not be found for a timestamp before the attribute change'
);

SELECT
    is(name, 'A', 'at-function should be usable in a where-clause')
FROM
    entity.network
WHERE (attribute_history."test_Node_at"((entity.get_network('A')).id, '2015-01-02 10:01')).x = 42;

SELECT * FROM finish();
ROLLBACK;
