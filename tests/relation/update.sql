BEGIN;

SELECT plan(3);

SELECT relation_directory.define('A->B');

SELECT throws_like(
    'SELECT source_id, target_id FROM relation_def."A->B"',
    '%does not exist%',
    'relation has no initial view'
);

SELECT relation_directory.update(
    type,
    $$SELECT 12 source_id, 22 target_id$$
)
FROM relation_directory.type
WHERE name = 'A->B';

SELECT results_eq(
    'SELECT source_id, target_id FROM relation_def."A->B"',
    'VALUES (12, 22)',
    'initial update sets the view'
);

SELECT relation_directory.update(
    type,
    $$SELECT 13 source_id, 23 target_id$$
)
FROM relation_directory.type
WHERE name = 'A->B';

SELECT set_eq(
    'SELECT source_id, target_id FROM relation_def."A->B"',
    'VALUES (13, 23)',
    'update changes the view'
);

SELECT * FROM finish();
ROLLBACK;
