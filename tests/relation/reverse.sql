BEGIN;

SELECT plan(5);

SELECT relation_directory.create_type(
    'A->B',
    $$SELECT 5 source_id, 3 target_id$$
);

SELECT hasnt_table('relation'::name, 'B->A'::name, 'reverse table should not exist');

SELECT relation_directory.create_reverse('B->A','A->B');
SELECT has_table('relation'::name, 'B->A'::name, 'reverse table should exist');
SELECT has_view('relation_def'::name, 'B->A'::name, 'reverse table view should exist');
SELECT results_eq(
   $$SELECT source_id, target_id FROM relation_def."B->A"$$,
   'VALUES (3, 5)',
   'reverse table has source and target reversed'
);

SELECT throws_like($$SELECT relation_directory.create_reverse('B->C','C->B');$$, '%does not exist%', 'reverse table from non-existing table cannot be created');


SELECT * FROM finish();
ROLLBACK;
