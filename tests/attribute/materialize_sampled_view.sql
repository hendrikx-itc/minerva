BEGIN;

SELECT plan(1);

CREATE VIEW attribute.vsystem_state AS
SELECT
    999 AS entity_id,
    '2015-07-30 12:04+02'::timestamp with time zone AS timestamp,
    42 AS x,
    16 AS y;


SELECT attribute_directory.create_sampled_view_attributestore_materialization(
    'attribute.vsystem_state'::regclass,
    'system-info',
    'engine'
);


SELECT attribute_directory.materialize(svam)
FROM attribute_directory.sampled_view_attributestore_materialization svam
WHERE svam::text = 'attribute.vsystem_state -> system-info_engine';


SELECT has_table('attribute_history'::name, 'system-info_engine'::name);

SELECT * FROM finish();

ROLLBACK;

