BEGIN;

SELECT plan(5);

-- Define plain relation

SELECT relation_directory.define(
    'A->B'
);

SELECT has_table('relation'::name, 'A->B'::name, 'relation table should exist');
SELECT hasnt_view('relation_def'::name, 'A->B'::name, 'relation view should not exist');

-- Define relation with view definition

SELECT relation_directory.define(
    'X->Y',
    $$SELECT 12 source_id, 22 target_id$$
);

SELECT has_table('relation'::name, 'X->Y'::name, 'relation table should exist');
SELECT has_view('relation_def'::name, 'X->Y'::name, 'relation view should exist');

-- Do not allow same relation to be defined twice
SELECT throws_like($$SELECT relation_directory.define('A->B');$$, '%unique constraint%');

SELECT * FROM finish();
ROLLBACK;
