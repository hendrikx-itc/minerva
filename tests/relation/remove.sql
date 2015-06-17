BEGIN;

SELECT plan(2);

SELECT relation_directory.define('A->B');

SELECT has_table('relation'::name, 'A->B'::name, 'relation table should exist');

SELECT relation_directory.remove('A->B');

SELECT hasnt_table('relation'::name, 'A->B'::name, 'relation table should no longer exist');

SELECT * FROM finish();
ROLLBACK;

