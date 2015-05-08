BEGIN;

SELECT plan(2);

SELECT relation_directory.define(
    'A->B',
    $$SELECT 12 source_id, 22 target_id$$
);

SELECT has_table('relation'::name, 'A->B'::name, 'relation table should exist');
SELECT has_view('relation_def'::name, 'A->B'::name, 'relation view should exist');

SELECT * FROM finish();
ROLLBACK;
