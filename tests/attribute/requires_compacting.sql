BEGIN;

SELECT plan(4);

INSERT INTO directory.data_source (id, name, description) VALUES
    (1, 'ds', 'some datasource');

INSERT INTO directory.entity_type (id, name, description) VALUES
    (1, 'type1', 'some type'),
    (2, 'type2', 'some type'),
    (3, 'type3', 'some type'),
    (4, 'type4', 'some type');

INSERT INTO attribute_directory.attribute_store (id, data_source_id, entity_type_id) VALUES
    (1, 1, 1),
    (2, 1, 2),
    (3, 1, 3),
    (4, 1, 4);

INSERT INTO attribute_directory.attribute_store_modified (attribute_store_id, modified) VALUES
    (1, '2018-01-01 00:00:00'),
    (2, '2018-01-01 00:00:00'),
    (3, '2018-01-01 00:00:00');

INSERT INTO attribute_directory.attribute_store_compacted (attribute_store_id, compacted) VALUES
    (1, '2018-01-01 00:00:00'),
    (2, '2017-01-01 00:00:00');

SELECT is(
    attribute_directory.requires_compacting(1),
    false,
    'recently compacted attribute_store should not need compacting'
);

SELECT is(
    attribute_directory.requires_compacting(2),
    true,
    'attribute_store that is modified after compacting should need compacting'
);

SELECT is(
    attribute_directory.requires_compacting(3),
    true,
    'attribute_store that was never compacted should need compacting'
);

SELECT isnt(
    attribute_directory.requires_compacting(4),
    true,
    'attribute_store that was never modified should not need compacting'
);

SELECT * FROM finish();
ROLLBACK;
