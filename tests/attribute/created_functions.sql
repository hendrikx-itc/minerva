BEGIN;

SELECT plan(19);

CALL attribute_directory.create_attribute_store(
    'created_function_ds',
    'created_functions_et',
    ARRAY[
        ('x', 'integer', 'some column with integer values'),
	('y', 'text', 'some column with text values')
    ]::attribute_directory.attribute_descr[]
);

INSERT INTO attribute_history.created_function_ds_created_functions_et ("entity_id", "timestamp", "modified", "first_appearance", "x", "y") VALUES
    (
        1,
        '2016-01-01 00:00:00',
        '2017-07-01 00:00:00',
        '2016-01-01 00:00:00',
        17,
        'old'
    );
INSERT INTO attribute_history.created_function_ds_created_functions_et ("entity_id", "timestamp", "modified", "first_appearance", "x", "y") VALUES
    (
        1,
        '2017-01-01 00:00:00',
        '2017-01-01 00:00:00',
        '2015-01-01 00:00:00',
        42,
        'new'
    );
INSERT INTO attribute_history.created_function_ds_created_functions_et ("entity_id", "timestamp", "modified", "first_appearance", "x", "y") VALUES
    (
        2,
        '2016-02-01 00:00:00',
        '2017-07-01 00:00:00',
        '2016-01-01 00:00:00',
        3,
        'old'
    );
INSERT INTO attribute_history.created_function_ds_created_functions_et ("entity_id", "timestamp", "modified", "first_appearance", "x", "y") VALUES
    (
        2,
        '2017-02-01 00:00:00',
        '2017-01-01 00:00:00',
        '2015-01-01 00:00:00',
        5,
        'new'
    );
	
SELECT has_function(
    'attribute_history',
    'created_function_ds_created_functions_et_at_ptr',
    ARRAY[
	'timestamp with time zone'
	],
    'at ptr function should exist'
);

SELECT bag_eq(
    $$SELECT timestamp FROM attribute_history.created_function_ds_created_functions_et_at_ptr('2018-01-01 00:00:00') ptr
      JOIN attribute_history.created_function_ds_created_functions_et history ON ptr.id = history.id $$,
    ARRAY[
        '2017-01-01 00:00:00'::timestamp,
	'2017-02-01 00:00:00'::timestamp
	],
    'attribute_history.created_function_ds_created_functions_et_at_ptr should give latest timestamps if used with more recent time'
);

SELECT bag_eq(
    $$SELECT timestamp FROM attribute_history.created_function_ds_created_functions_et_at_ptr('2016-08-01 00:00:00') ptr
      JOIN attribute_history.created_function_ds_created_functions_et history ON ptr.id = history.id $$,
    ARRAY[
        '2016-01-01 00:00:00'::timestamp,
	'2016-02-01 00:00:00'::timestamp
	],
    'attribute_history.created_function_ds_created_functions_et_at_ptr should give older timestamps if used with older time'
);

SELECT bag_eq(
    $$SELECT timestamp FROM attribute_history.created_function_ds_created_functions_et_at_ptr('2015-01-01 00:00:00') ptr
      JOIN attribute_history.created_function_ds_created_functions_et history ON ptr.id = history.id $$,
    ARRAY[]::timestamp[],
    'attribute_history.created_function_ds_created_functions_et_at_ptr should give no result if used with too old timestamp'
);

SELECT has_function(
    'attribute_history',
    'created_function_ds_created_functions_et_at_ptr',
    ARRAY[
        'integer',
	'timestamp with time zone'
	],
    'at ptr function should exist'
);

SELECT results_eq('SELECT timestamp FROM attribute_history.created_function_ds_created_functions_et
                   WHERE id = attribute_history.created_function_ds_created_functions_et_at_ptr(1, ''2018-01-01 00:00:00'')::timestamp',
    '2017-01-01 00:00:00'::timestamp,
    'attribute_history.created_function_ds_created_functions_et_at_ptr should give latest timestamp if used with more recent time'
);

SELECT results_eq('SELECT timestamp FROM attribute_history.created_function_ds_created_functions_et
                   WHERE id = attribute_history.created_function_ds_created_functions_et_at_ptr(1,''2016-08-01 00:00:00'')::timestamp',
    '2016-01-01 00:00:00'::timestamp,
    'attribute_history.created_function_ds_created_functions_et_at_ptr should give older timestamp if used with older time'
);

SELECT is(attribute_history.created_function_ds_created_functions_et_at_ptr(2,'2016-01-15 00:00:00'),
    null,
    'attribute_history.created_function_ds_created_functions_et_at_ptr should give no result if used with too old timestamp'
);

SELECT has_function(
    'attribute_history',
    'created_function_ds_created_functions_et_at',
    ARRAY[
        'timestamp with time zone'
	],
    'at function should exist'
);

SELECT bag_eq(
    $$SELECT x FROM attribute_history.created_function_ds_created_functions_et_at('2018-01-01 00:00:00')$$,
    ARRAY [42,5],
    'attribute_history.created_function_ds_created_functions_et_at should give more recent value when using recent date'
);

SELECT bag_eq(
    $$SELECT x FROM attribute_history.created_function_ds_created_functions_et_at('2016-08-01 00:00:00')$$,
    ARRAY [17,3],
    'attribute_history.created_function_ds_created_functions_et_at should give older value when using older date'
);

SELECT bag_eq(
    $$SELECT x FROM attribute_history.created_function_ds_created_functions_et_at('2016-01-15 00:00:00')$$,
    ARRAY [17],
    'attribute_history.created_function_ds_created_functions_et_at should give no value when using too old date'
);

SELECT has_function(
    'attribute_history',
    'created_function_ds_created_functions_et_at',
    ARRAY[
        'integer',
        'timestamp with time zone'
	],
    'at function should exist'
);

SELECT results_eq(
    $$SELECT x FROM attribute_history.created_function_ds_created_functions_et_at(1,'2018-01-01 00:00:00')$$,
    ARRAY [42],
    'attribute_history.created_function_ds_created_functions_et_at should give more recent value when using recent date'
);

SELECT results_eq(
    $$SELECT x FROM attribute_history.created_function_ds_created_functions_et_at(1,'2016-08-01 00:00:00')$$,
    ARRAY [17],
    'attribute_history.created_function_ds_created_functions_et_at should give older value when using older date'
);

SELECT is(attribute_history.created_function_ds_created_functions_et_at(1,'2015-01-01 00:00:00'),
    null,
    'attribute_history.created_function_ds_created_functions_et_at should give no result when using too old date'
);

SELECT has_function(
    'attribute_history',
    'values_hash',
    ARRAY[
	'attribute_history.created_function_ds_created_functions_et'
	],
    'values_hash should be defined'
);

SELECT function_returns(
    'attribute_history',
    'values_hash',
    ARRAY[
	'attribute_history.created_function_ds_created_functions_et'
	],
    'text'
);

SELECT attribute_directory.delete_attribute_store(
    attribute_directory.get_attribute_store('created_function_ds', 'created_functions_et')
    );

SELECT hasnt_function(
    'attribute_history'
    'values_hash',
    ARRAY[
	'attribute_history.created_function_ds_created_functions_et'
	],
    'values_hash should be removed'
);
    

SELECT * FROM finish();
ROLLBACK;
