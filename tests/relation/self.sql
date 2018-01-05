BEGIN;

SELECT plan(4);

SELECT has_table('relation'::name, 'self'::name);

SELECT results_eq(
    $$SELECT source_id FROM relation.self;$$,
    ARRAY[]::integer[],
    'relation.self starts out empty'
    );

SELECT directory.dn_to_entity('Network=local,Switch=main');

SELECT results_ne(
    $$SELECT source_id FROM relation.self;$$,
    ARRAY[]::integer[],
    'relation.self not empty after creation of entity'
    );

SELECT results_eq(
    $$SELECT source_id, target_id FROM relation.self;$$,
    $$SELECT id, id FROM directory.entity;$$,
    'relation.self contains newly created entity'
    );

SELECT * FROM finish();
ROLLBACK;
