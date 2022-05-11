BEGIN;

SELECT plan(2);

CALL attribute_directory.create_attribute_store(
    'source',
    'network',
    ARRAY[
        ('x', 'integer', 'some column with integer values')
    ]::attribute_directory.attribute_descr[]
);

SELECT entity.create_network('A');

INSERT INTO attribute_staging."source_network"(
    entity_id,
    timestamp,
    x
) VALUES (
    (entity.get_network('A')).id,
    '2014-11-17 13:00',
    42
);

SELECT attribute_directory.transfer_staged(attribute_store)
FROM attribute_directory.attribute_store
WHERE attribute_store::text = 'source_network';

SELECT results_eq(
    $$ SELECT x FROM attribute_history."source_network" a
       JOIN entity.network entity ON entity.id = a.entity_id
       WHERE entity.name = 'A'$$,
    ARRAY[42]
);

-- Alter attribute table

SELECT attribute_directory.check_attributes_exist(
    "attribute_store",
    ARRAY[
       ('y', 'double precision', 'some column with floating point values')
    ]::attribute_directory.attribute_descr[]
)
FROM attribute_directory.attribute_store
WHERE attribute_store::text = 'source_network';

INSERT INTO attribute_staging."source_network"(
    entity_id,
    timestamp,
    x,
    y
) VALUES (
    (entity.get_network('A')).id,
    '2014-11-17 13:00',
    42,
    43.0
);

SELECT attribute_directory.transfer_staged(attribute_store)
FROM attribute_directory.attribute_store
WHERE attribute_store::text = 'source_network';

SELECT is(
    y,
    43.0::double precision
)
FROM attribute_history."source_network" a
JOIN entity.network entity ON entity.id = a.entity_id
WHERE entity.name = 'A';

SELECT * FROM finish();
ROLLBACK;
