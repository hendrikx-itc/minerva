BEGIN;

SELECT plan(3);

SELECT is(system.version(), (4,7,0)::system.version_tuple);

SELECT ok(
    (1,0,0)::system.version_tuple < (2,0,0)::system.version_tuple
);

SELECT ok(
    (4,7,0)::system.version_tuple > (4,6,55)::system.version_tuple
);

SELECT * FROM finish();
ROLLBACK;
