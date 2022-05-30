BEGIN;

SELECT plan(9);

SELECT switch_off_citus();

SET minerva.trigger_mark_modified TO on;

CALL attribute_directory.create_attribute_store('ds2', 'type2', ARRAY[('x','integer','some column')]::attribute_directory.attribute_descr[]);

SELECT results_eq(
    $$SELECT attribute_directory.requires_compacting(id) FROM attribute_directory.attribute_store$$,
    ARRAY[false],
    'newly created attribute store without content should not need compacting'
);

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

SELECT results_eq(
    $$SELECT attribute_directory.requires_compacting(id) FROM attribute_directory.attribute_store$$,
    ARRAY[true],
    'newly created attribute store with content should need compacting'
);

SELECT attribute_directory.compact(a)
FROM attribute_directory.attribute_store a;

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
    $$SELECT timestamp FROM attribute_history.ds2_type2 WHERE entity_id = 10 AND modified > '2018-01-01 00:00:00'::timestamp$$,
    ARRAY[
        '2017-01-01 00:00:00'::timestamp,
        '2017-01-01 02:00:00'::timestamp,
        '2017-01-01 05:00:00'::timestamp
	],    
    'compacting should change modified date of compacted data, not of unchanged data'
);

SELECT bag_eq(
    $$SELECT timestamp FROM attribute_history.ds2_type2 WHERE entity_id = 11$$,
    ARRAY[
        '2017-01-01 11:00:00'::timestamp
	],
    'compacting should not drop occurences because of results from different entities'
);

SELECT results_eq(
    $$SELECT attribute_directory.requires_compacting(id) FROM attribute_directory.attribute_store$$,
    ARRAY[false],
    'compacting should not be necessary after compacting'
);

INSERT INTO attribute_history.ds2_type2 ("entity_id", "timestamp", "modified", "x") values
    (10, '2017-01-01 11:00:00', '2017-01-01 11:30:00', 6);

SELECT results_eq(
    $$SELECT attribute_directory.requires_compacting(id) FROM attribute_directory.attribute_store$$,
    ARRAY[true],
    'compacting should be necessary after a new insertion'
);

INSERT INTO attribute_history.ds2_type2 ("entity_id", "timestamp", "modified", "x") values
    (10, '2017-01-01 12:00:00', '2017-01-01 12:00:00', 6),
    (10, '2017-01-01 13:00:00', '2017-01-01 13:00:00', 6),
    (10, '2017-01-01 14:00:00', '2017-01-01 14:00:00', 7),
    (10, '2017-01-01 15:00:00', '2017-01-01 15:00:00', 7),
    (11, '2017-01-01 12:00:00', '2017-01-01 12:00:00', 5),
    (11, '2017-01-01 13:00:00', '2017-01-01 13:00:00', 6),
    (11, '2017-01-01 14:00:00', '2017-01-01 14:00:00', 6),
    (11, '2017-01-01 15:00:00', '2017-01-01 15:00:00', 6);

SELECT attribute_directory.compact(a, 4)
FROM attribute_directory.attribute_store a;

SELECT results_eq(
    $$SELECT attribute_directory.requires_compacting(id) FROM attribute_directory.attribute_store$$,
    ARRAY[true],
    'partial compacting should not compact everything'
);

SELECT attribute_directory.compact(a, 3)
FROM attribute_directory.attribute_store a;

SELECT results_eq(
    $$SELECT attribute_directory.requires_compacting(id) FROM attribute_directory.attribute_store$$,
    ARRAY[false],
    'partial compacting that includes every uncompacted entity should compact everything'
);

SELECT * FROM finish();
ROLLBACK;
