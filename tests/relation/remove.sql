BEGIN;

SELECT plan(3);

SELECT relation_directory.define('A->B');

SELECT has_table('relation'::name, 'A->B'::name, 'relation table should exist');

SELECT relation_directory.remove('A->B');

SELECT hasnt_table('relation'::name, 'A->B'::name, 'relation table should no longer exist');

SELECT relation_directory.define('A->B');

SELECT has_table('relation'::name, 'A->B'::name, 'relation table should be re-created');

SELECT * FROM finish();
ROLLBACK;

