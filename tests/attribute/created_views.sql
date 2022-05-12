BEGIN;

SELECT plan(21);

CALL attribute_directory.create_attribute_store(
    'created_views_ds',
    'created_views_et',
    ARRAY[
        ('x', 'integer', 'some column with integer values'),
	('y', 'text', 'some column with text values')
    ]::attribute_directory.attribute_descr[]
);

SELECT has_view('attribute_staging', 'created_views_ds_created_views_et_new', 'staging-new view should be created');

SELECT has_view('attribute_staging', 'created_views_ds_created_views_et_modified', 'staging-modified view should be created');

INSERT INTO attribute_history.created_views_ds_created_views_et ("entity_id", "timestamp", "modified", "first_appearance", "x", "y") VALUES
    (
        1,
        '2016-01-01 00:00:00',
        '2017-07-01 00:00:00',
        '2016-01-01 00:00:00',
        17,
        'old'
    );
INSERT INTO attribute_history.created_views_ds_created_views_et ("entity_id", "timestamp", "modified", "first_appearance", "x", "y") VALUES
    (
        1,
        '2016-12-31 23:00:00',
        '2017-01-01 00:00:00',
        '2015-01-01 00:00:00',
        42,
        'new'
    );
INSERT INTO attribute_history.created_views_ds_created_views_et ("entity_id", "timestamp", "modified", "first_appearance", "x", "y") VALUES
    (
        1,
        '2017-01-01 00:00:00',
        '2017-01-01 00:00:00',
        '2015-01-01 00:00:00',
        42,
        'new'
    );
INSERT INTO attribute_history.created_views_ds_created_views_et ("entity_id", "timestamp", "modified", "first_appearance", "x", "y") VALUES
    (
        2,
        '2016-02-01 00:00:00',
        '2017-07-01 00:00:00',
        '2016-01-01 00:00:00',
        3,
        'old'
    );
INSERT INTO attribute_history.created_views_ds_created_views_et ("entity_id", "timestamp", "modified", "first_appearance", "x", "y") VALUES
    (
        2,
        '2017-02-01 00:00:00',
        '2017-01-01 00:00:00',
        '2015-01-01 00:00:00',
        5,
        'new'
    );

SELECT bag_eq(
    $$SELECT timestamp FROM attribute_history.created_views_ds_created_views_et_changes$$,
    ARRAY [
        '2016-01-01 00:00:00'::timestamp,
	'2016-12-31 23:00:00'::timestamp,
	'2017-01-01 00:00:00'::timestamp,
	'2016-02-01 00:00:00'::timestamp,
	'2017-02-01 00:00:00'::timestamp
	],
    'attribute_history.created_views_ds_created_views_et_changes should have correct timestamps'
);

SELECT bag_eq(
    $$SELECT timestamp FROM attribute_history.created_views_ds_created_views_et_changes WHERE entity_id = 1$$,
    ARRAY [
        '2016-01-01 00:00:00'::timestamp,
	'2016-12-31 23:00:00'::timestamp,
	'2017-01-01 00:00:00'::timestamp
	],
    'attribute_history.created_views_ds_created_views_et_changes should have correct timestamps and entities'
);

SELECT bag_eq(
    $$SELECT change FROM attribute_history.created_views_ds_created_views_et_changes WHERE entity_id = 1 AND timestamp = '2016-01-01 00:00:00'$$,
    ARRAY [true],
    'attribute_history.created_views_ds_created_views_et_changes should be true for new items'
);

SELECT bag_eq(
    $$SELECT change FROM attribute_history.created_views_ds_created_views_et_changes WHERE entity_id = 1 AND timestamp = '2016-12-31 23:00:00'$$,
    ARRAY [true],
    'attribute_history.created_views_ds_created_views_et_changes should be true for changed items'
);

SELECT bag_eq(
    $$SELECT change FROM attribute_history.created_views_ds_created_views_et_changes WHERE entity_id = 1 AND timestamp = '2017-01-01 00:00:00'$$,
    ARRAY [false],
    'attribute_history.created_views_ds_created_views_et_changes should be false for unchanged items'
);

SELECT bag_eq(
    $$SELECT start FROM attribute_history.created_views_ds_created_views_et_run_length WHERE entity_id = 1$$,
    ARRAY ['2016-01-01 00:00:00'::timestamp, '2016-12-31 23:00:00'::timestamp ],
    'attribute_history.created_views_ds_created_views_et_run_length should have correct start'
);

SELECT bag_eq(
    $$SELECT "end" FROM attribute_history.created_views_ds_created_views_et_run_length WHERE entity_id = 1$$,
    ARRAY ['2016-01-01 00:00:00'::timestamp, '2017-01-01 00:00:00'::timestamp ],
    'attribute_history.created_views_ds_created_views_et_run_length should have correct end'
);

SELECT bag_eq(
    $$SELECT run_length FROM attribute_history.created_views_ds_created_views_et_run_length WHERE entity_id = 1$$,
    ARRAY [1,2],
    'attribute_history.created_views_ds_created_views_et_run_length should have correct run_length'
);

SELECT bag_eq(
    $$SELECT run_length FROM attribute_history.created_views_ds_created_views_et_run_length WHERE entity_id = 2$$,
    ARRAY [1,1],
    'attribute_history.created_views_ds_created_views_et_run_length should have correct run_length (second test)'
);

INSERT INTO attribute_staging.created_views_ds_created_views_et ("entity_id", "timestamp", "x", "y") VALUES
    (
        1,
        '2016-01-01 00:00:00',
        9,
        'wrong'
    );

INSERT INTO attribute_staging.created_views_ds_created_views_et ("entity_id", "timestamp", "x", "y") VALUES
    (
        1,
        '2016-02-01 00:00:00',
        3,
        'old'
    );
INSERT INTO attribute_staging.created_views_ds_created_views_et ("entity_id", "timestamp", "x", "y") VALUES
    (
        1,
        '2017-01-01 00:00:00',
        42,
        'new'
    );

SELECT bag_eq(
    $$SELECT x FROM attribute_staging.created_views_ds_created_views_et_new$$,
    ARRAY [3],
    'staging-new should only contain timestamps where no data have been included yet'
);

SELECT bag_eq(
    $$SELECT x FROM attribute_staging.created_views_ds_created_views_et_modified$$,
    ARRAY [9,42],
    'staging-modified should only contain timestamps where data has already been included, whether changed or unchanged'
);

INSERT INTO attribute_history.created_views_ds_created_views_et_curr_ptr ("entity_id", "timestamp") VALUES
    (1, '2017-01-01 00:00:00');
INSERT INTO attribute_history.created_views_ds_created_views_et_curr_ptr ("entity_id", "timestamp") VALUES
    (2, '2016-02-01 00:00:00');


SELECT bag_eq(
    $$SELECT x FROM attribute.created_views_ds_created_views_et WHERE entity_id = 1$$,
    ARRAY[42],
    'current attribute view should follow curr_ptr'
);

SELECT bag_eq(
    $$SELECT x FROM attribute.created_views_ds_created_views_et WHERE entity_id = 2$$,
    ARRAY[3],
    'current attribute view should follow curr_ptr even if it does not have most recent value'
);

UPDATE attribute_history.created_views_ds_created_views_et_curr_ptr SET timestamp = '2018-01-01 00:00:00'::timestamp WHERE entity_id = 1;

SELECT bag_eq(
    $$SELECT x FROM attribute.created_views_ds_created_views_et WHERE entity_id = 1$$,
    ARRAY[]::integer[],
    'current attribute view should give no data when curr_ptr points to time without data'
);

SELECT bag_eq(
    $$SELECT entity_id FROM attribute_history.created_views_ds_created_views_et_compacted$$,
    ARRAY[1],
    'compacted history only contains runs of length > 1'
);

SELECT bag_eq(
    $$SELECT timestamp FROM attribute_history.created_views_ds_created_views_et_compacted$$,
    ARRAY['2016-12-31 23:00:00'::timestamp],
    'compacted history uses start date as date'
);

SELECT bag_eq(
    $$SELECT timestamp FROM attribute_history.created_views_ds_created_views_et_curr_selection$$,
    ARRAY[
        '2017-01-01 00:00:00'::timestamp,
	'2017-02-01 00:00:00'::timestamp
	],
    'curr_selection should give last date for each entity'
);

SELECT attribute_directory.delete_attribute_store(
    attribute_directory.get_attribute_store('created_views_ds', 'created_views_et'));

SELECT hasnt_view('attribute_staging', 'created_views_ds_created_views_et_new', 'staging-new view should be removed');

SELECT hasnt_view('attribute_staging', 'created_views_ds_created_views_et_modified', 'staging-modified view should be removed');

SELECT * FROM finish();
ROLLBACK;
