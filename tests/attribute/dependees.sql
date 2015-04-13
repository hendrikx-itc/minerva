BEGIN;

SELECT plan(1);

SELECT attribute_directory.create_attributestore(
	'test',
	'Node',
	ARRAY[
		('x', 'integer', 'some column with integer values')
	]::attribute_directory.attribute_descr[]
);

SELECT results_eq(
    $$SELECT dependee FROM (
    SELECT d::text dependee
    FROM (
        SELECT unnest(attribute_directory.dependees(attributestore)) d
        FROM attribute_directory.attributestore
    ) foo
) bar$$,
    ARRAY[
        'attribute_history."test_Node_at"(pg_catalog.timestamptz)',
        'attribute_history."test_Node_at"(pg_catalog.int4, pg_catalog.timestamptz)',
        'attribute_history.values_hash(attribute_history."test_Node")',
        'attribute_staging."test_Node_new"',
        'attribute_staging."test_Node_modified"',
        'attribute_history."test_Node_changes"',
        'attribute_history."test_Node_run_length"',
        'attribute_history."test_Node_compacted"',
        'attribute_history."test_Node_curr_selection"',
        'attribute."test_Node"'
    ]::text[]
);

SELECT * FROM finish();
ROLLBACK;
