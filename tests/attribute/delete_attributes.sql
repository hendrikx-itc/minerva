BEGIN;

SELECT plan(37);

CALL attribute_directory.create_attribute_store(
    'ds1',
    'type1',
    ARRAY[
        ('x', 'integer', 'some column with integer values'),
	('y', 'integer', 'another column with integer values')
    ]::attribute_directory.attribute_descr[]
);

CALL attribute_directory.create_attribute_store(
    'ds2',
    'type2',
    ARRAY[
        ('x', 'integer', 'some column with integer values'),
	('y', 'integer', 'another column with integer values')
    ]::attribute_directory.attribute_descr[]
);

SELECT bag_eq(
    $$ SELECT name FROM directory.data_source $$,
    ARRAY['ds1','ds2'],
    'Creating attribute stores should create the associated data source'
);

SELECT bag_eq(
    $$ SELECT name FROM directory.entity_type $$,
    ARRAY['type1','type2'],
    'Creating attribute stores should create the associated data source'
);

SELECT directory.delete_data_source('ds2');

SELECT bag_eq(
    $$ SELECT e.name FROM attribute_directory.attribute_store atts, directory.entity_type e WHERE atts.entity_type_id = e.id $$,
    ARRAY ['type1'],
    'Deletion of data sources should cause deletion of the connected attribute store'
);

SELECT bag_eq(
    $$ SELECT name FROM directory.entity_type $$,
    ARRAY ['type1', 'type2'],
    'Deletion of data sources should not cause deletion of entity types'
);

SELECT columns_are(
    'attribute_base',
    'ds1_type1',
    ARRAY[
        'entity_id',
	'timestamp',
	'x',
	'y'
    ],
    'attribute base columns should be as defined'
);

SELECT attribute_directory.drop_attribute(
    attribute_directory.get_attribute_store('ds1', 'type1'), 'x');

SELECT bag_eq(
    $$ SELECT name FROM attribute_directory.attribute; $$,
    ARRAY['y'],
    'Attribute deletion should delete attribute, but no others'
);

SELECT columns_are(
    'attribute_base',
    'ds1_type1',
    ARRAY[
        'entity_id',
	'timestamp',
	'y'
    ],
    'column should be deleted from attribute base'
);

SELECT columns_are(
    'attribute_staging',
    'ds1_type1_new',
    ARRAY[
        'entity_id',
	'timestamp',
	'y'
    ],
    'column should be deleted from staging new view'
);

SELECT columns_are(
    'attribute_staging',
    'ds1_type1_new',
    ARRAY[
        'entity_id',
	'timestamp',
	'y'
    ],
    'column should be deleted from staging modified view'
);

SELECT columns_are(
    'attribute',
    'ds1_type1',
    ARRAY[
        'entity_id',
	'timestamp',
	'modified',
	'hash',
	'first_appearance',
	'y'
    ],
    'column should be deleted from attribute view'
);

SELECT columns_are(
    'attribute_history',
    'ds1_type1_compacted',
    ARRAY[
        'entity_id',
	'timestamp',
	'end',
	'modified',
	'hash',
	'y'
    ],
    'column should be deleted from compacted view'
);

SELECT has_table('attribute_base', 'ds1_type1', 'base table should exist');
SELECT has_function('attribute_history', 'ds1_type1_at_ptr', 'pointer function should exist');
SELECT has_table('attribute_history', 'ds1_type1_curr_ptr', 'pointer table should exist');
SELECT has_view('attribute_staging', 'ds1_type1_new', 'staging new view should exist');
SELECT has_view('attribute_staging', 'ds1_type1_modified', 'staging modified view should exist');
SELECT has_view('attribute_history', 'ds1_type1_curr_selection', 'curr selection view should exist');
SELECT has_view('attribute', 'ds1_type1', 'curr view should exist');
SELECT has_view('attribute_history', 'ds1_type1_compacted', 'compacted view should exist');

SELECT hasnt_table('attribute_base', 'ds2_type2', 'base table should have been deleted');
SELECT hasnt_function('attribute_history', 'ds2_type2_at_ptr', 'pointer function should have been deleted');
SELECT hasnt_table('attribute_history', 'ds2_type2_curr_ptr', 'pointer table should have been deleted');
SELECT hasnt_view('attribute_staging', 'ds2_type2_new', 'staging new view should have been deleted');
SELECT hasnt_view('attribute_staging', 'ds2_type2_modified', 'staging modified view should have been deleted');
SELECT hasnt_view('attribute_history', 'ds2_type2_curr_selection', 'curr selection view should have been deleted');
SELECT hasnt_view('attribute', 'ds2_type2', 'curr view should have been deleted');
SELECT hasnt_view('attribute_history', 'ds2_type2_compacted', 'compacted view should have been deleted');

SELECT lives_ok(
    $$ DELETE FROM attribute_directory.attribute_store; $$,
    'Deletion of attribute stores should be possible'
);

SELECT hasnt_table('attribute_base', 'ds1_type1', 'base table should have been deleted');
SELECT hasnt_function('attribute_history', 'ds1_type1_at_ptr', 'pointer function should have been deleted');
SELECT hasnt_table('attribute_history', 'ds1_type1_curr_ptr', 'pointer table should have been deleted');
SELECT hasnt_view('attribute_staging', 'ds1_type1_new', 'staging new view should have been deleted');
SELECT hasnt_view('attribute_staging', 'ds1_type1_modified', 'staging modified view should have been deleted');
SELECT hasnt_view('attribute_history', 'ds1_type1_curr_selection', 'curr selection view should have been deleted');
SELECT hasnt_view('attribute', 'ds1_type1', 'curr view should have been deleted');
SELECT hasnt_view('attribute_history', 'ds1_type1_compacted', 'compacted view should have been deleted');

SELECT bag_eq(
    $$ SELECT name FROM attribute_directory.attribute; $$,
    ARRAY[]::text[],
    'Attributes should be deleted together with attribute stores'
);

SELECT * FROM finish();
ROLLBACK;
