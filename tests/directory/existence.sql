BEGIN;

SELECT plan(7);

CREATE FUNCTION timestamp_1()
    RETURNS timestamp with time zone
AS $$
SELECT '2014-12-30 13:00'::timestamp with time zone;
$$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION timestamp_2()
    RETURNS timestamp with time zone
AS $$
SELECT '2014-12-30 14:00'::timestamp with time zone;
$$ LANGUAGE sql IMMUTABLE;

SELECT directory.dns_to_entity_ids(ARRAY[
	'Network=001,Cell=a001',
	'Network=001,Cell=a002',
	'Network=001,Cell=a003'
]);

-------------------------
-- First existence update
-------------------------
INSERT INTO directory.existence_staging(dn)
VALUES ('Network=001,Cell=a002');

SELECT is(count(*), 1::bigint)
FROM directory.existing_staging(timestamp_1());

SELECT is(count(*), 2::bigint)
FROM directory.non_existing_staging(timestamp_1());

SELECT is(count(*), 3::bigint)
FROM directory.existence_staging_state(timestamp_1());

SELECT directory.transfer_existence(timestamp_1());

--------------------------
-- Second existence update
--------------------------
INSERT INTO directory.existence_staging(dn)
VALUES ('Network=001,Cell=a001');

SELECT is(count(*), 1::bigint)
FROM directory.existing_staging(timestamp_1());

SELECT is(count(*), 2::bigint)
FROM directory.non_existing_staging(timestamp_1());

SELECT is(count(*), 3::bigint)
FROM directory.existence_staging_state(timestamp_1());

SELECT directory.transfer_existence(timestamp_2());

--------------------
-- Final state check
--------------------

SELECT is(count(*), 5::bigint)
FROM directory.existence;

SELECT entity.dn, existence_at.timestamp
FROM directory.existence_at(timestamp_2()) existence_at
JOIN directory.entity ON entity.id = existence_at.entity_id;

SELECT * FROM finish();
ROLLBACK;
