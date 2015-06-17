BEGIN;

SELECT plan(2);

SELECT relation_directory.define(
    'A->B',
    $$SELECT 12 source_id, 22 target_id$$
);

SELECT set_eq(
    'SELECT source_id, target_id FROM relation_def."A->B"',
    'VALUES (12, 22)'
);

SELECT relation_directory.update(
    type,
    $$SELECT 13 source_id, 23 target_id$$
)
FROM relation_directory.type
WHERE name = 'A->B';

SELECT set_eq(
    'SELECT source_id, target_id FROM relation_def."A->B"',
    'VALUES (13, 23)'
);

SELECT * FROM finish();
ROLLBACK;
