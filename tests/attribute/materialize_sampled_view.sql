BEGIN;

SELECT plan(1);

CREATE VIEW attribute.vsystem_state AS
SELECT
    999 AS entity_id,
    '2015-07-30 12:04+02'::timestamp with time zone AS timestamp,
    42 AS x,
    16 AS y;

CREATE FUNCTION attribute.vsystem_state_fingerprint()
    RETURNS text
AS $$
    SELECT 'static_fingerprint'::text
$$ LANGUAGE sql IMMUTABLE;


SELECT attribute_directory.create_sampled_view_materialization(
    'attribute.vsystem_state'::regclass::oid,
    'attribute.vsystem_state_fingerprint()'::regprocedure::oid,
    'system-info',
    'engine'
);


SELECT attribute_directory.materialize(svam)
FROM attribute_directory.sampled_view_materialization svam
WHERE svam::text = 'attribute.vsystem_state -> system-info_engine';


SELECT has_table('attribute_history'::name, 'system-info_engine'::name);

SELECT * FROM finish();

ROLLBACK;

