BEGIN;

SELECT plan(8);

INSERT INTO directory.data_source VALUES
    (1, 'ds', 'some datasource');

INSERT INTO directory.entity_type VALUES
    (1, 'type1', 'some type'),
    (2, 'type2', 'some type'),
    (3, 'type3', 'some type'),
    (4, 'type4', 'some type');

INSERT INTO attribute_directory.attribute_store VALUES
    (1, 1, 1),
    (2, 1, 2),
    (3, 1, 3),
    (4, 1, 4);

INSERT INTO attribute_directory.attribute_store_modified VALUES
    (1, '2018-01-01 00:00:00'),
    (2, '2018-01-01 00:00:00'),
    (3, '2018-01-01 00:00:00');

INSERT INTO attribute_directory.attribute_store_compacted VALUES
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

SELECT attribute_directory.create_attribute_store('ds2', 'type2', ARRAY[('x','integer','some column')]::attribute_directory.attribute_descr[]);

INSERT INTO attribute_history.ds2_type2 ("entity_id", "timestamp", "modified", "x") values
    (10, '2017-01-01 00:00:00', '2017-01-01 00:00:00', 1),
    (10, '2017-01-01 01:00:00', '2017-01-01 01:00:00', 1),
    (10, '2017-01-01 02:00:00', '2017-01-01 02:00:00', 2),
    (10, '2017-01-01 03:00:00', '2017-01-01 03:00:00', 2),
    (12, '2017-01-01 03:30:00', '2017-01-01 03:30:00', 18),
    (10, '2017-01-01 04:00:00', '2017-01-01 04:00:00', 2),
    (10, '2017-01-01 05:00:00', '2017-01-01 05:00:00', 1),
    (10, '2017-01-01 06:00:00', '2017-01-01 06:00:00', 1),
    (10, '2017-01-01 07:00:00', '2017-01-01 07:00:00', 3),
    (10, '2017-01-01 08:00:00', '2017-01-01 08:00:00', 1),
    (10, '2017-01-01 09:00:00', '2017-01-01 09:00:00', 4),
    (10, '2017-01-01 10:00:00', '2017-01-01 10:00:00', 5),
    (11, '2017-01-01 11:00:00', '2017-01-01 11:00:00', 5);


PREPARE compact_needed AS SELECT attribute_directory.requires_compacting(a.id) FROM directory.data_source ds, attribute_directory.attribute_store a WHERE ds.name = 'ds2' AND a.data_source_id = ds.id AND a.entity_type_id = 2;

SELECT results_eq(
    'compact_needed',
    ARRAY[true],
    'newly created attribute store with content should need compacting'
);

SELECT attribute_directory.compact(a)
FROM directory.data_source ds, attribute_directory.attribute_store a
WHERE ds.name = 'ds2' AND a.data_source_id = ds.id AND a.entity_type_id = 2;

SELECT bag_eq(
    $$SELECT timestamp FROM attribute_history.ds2_type2 WHERE entity_id = 10$$,
    ARRAY[
        '2017-01-01 00:00:00'::timestamp,
        '2017-01-01 02:00:00'::timestamp,
        '2017-01-01 05:00:00'::timestamp,
        '2017-01-01 07:00:00'::timestamp,
        '2017-01-01 08:00:00'::timestamp,
        '2017-01-01 09:00:00'::timestamp,
        '2017-01-01 10:00:00'::timestamp
	],
    'compacting should leave only first occurence of each series of equal occurences'
);

SELECT bag_eq(
    $$SELECT timestamp FROM attribute_history.ds2_type2 WHERE entity_id = 11$$,
    ARRAY[
        '2017-01-01 11:00:00'::timestamp
	],
    'compacting should not drop occurences because of results from different entities'
);

SELECT results_eq(
    'compact_needed',
    ARRAY[false],
    'compacting should not be necessary after compacting'
);

SELECT * FROM finish();
ROLLBACK;
