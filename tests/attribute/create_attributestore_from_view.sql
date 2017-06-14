BEGIN;

SELECT plan(3);

CREATE VIEW attribute.vsystem_state AS
SELECT
    999 AS entity_id,
    '2015-07-30 12:04+02'::timestamp with time zone AS timestamp,
    42 AS x,
    16 AS y;


SELECT attribute_directory.create_attributestore_from_view(
    'attribute.vsystem_state'::regclass,
    'system-info',
    'engine'
);

SELECT has_table('attribute_history'::name, 'system-info_engine'::name);
SELECT has_column('attribute_history'::name, 'system-info_engine'::name, 'x'::name, 'column x should be deduced from view');
SELECT has_column('attribute_history'::name, 'system-info_engine'::name, 'y'::name, 'column y should be deduced from view');

SELECT * FROM finish();

ROLLBACK;

