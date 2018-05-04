BEGIN;

SELECT plan(5);

SET minerva.trigger_mark_modified TO on;

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

SELECT * FROM finish();
ROLLBACK;
