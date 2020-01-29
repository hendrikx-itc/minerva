BEGIN;

SELECT plan(3);

SELECT relation_directory.register_type('A->B');

SELECT bag_eq($$SELECT name FROM relation_directory.type;$$, ARRAY['A->B']);

SELECT relation_directory.remove('A->B');

SELECT bag_eq($$SELECT name FROM relation_directory.type;$$, ARRAY[]::text[]);

SELECT relation_directory.name_to_type('A->B');

SELECT bag_eq($$SELECT name FROM relation_directory.type;$$, ARRAY['A->B']);

SELECT * FROM finish();
ROLLBACK;

