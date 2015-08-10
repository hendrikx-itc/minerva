BEGIN;

SELECT plan(1);

CREATE VIEW attribute.vsystem_state AS
SELECT
    999 AS entity_id,
    '2015-07-30 12:04+02'::timestamp with time zone AS timestamp,
    42 AS x,
    16 AS y;

CREATE FUNCTION attribute.vsystem_state_source_modified()
    RETURNS SETOF attribute_directory.source_modified
AS $$
    SELECT unnest(ARRAY[
        ('test_source_a', '2015-07-30 13:11+02'),
        ('test_source_b', '2015-07-30 14:23+02')
    ]::attribute_directory.source_modified[]);
$$ LANGUAGE sql IMMUTABLE;


SELECT attribute_directory.create_sampled_view_materialization(
    'attribute.vsystem_state'::regclass::oid,
    'attribute.vsystem_state_source_modified()'::regprocedure::oid,
    'system-info',
    'engine'
);


SELECT is(attribute_directory.max_modified(svm), '2015-07-30 14:23+02'::timestamptz)
FROM attribute_directory.sampled_view_materialization svm
WHERE svm::text = 'attribute.vsystem_state -> system-info_engine';

SELECT * FROM finish();

ROLLBACK;

