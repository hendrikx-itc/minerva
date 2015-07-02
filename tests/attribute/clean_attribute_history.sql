BEGIN;

SELECT plan(4);

-- Set up test data
SELECT attribute_directory.create_attributestore(
	'some_datasource_name',
	'some_entitytype_name',
	ARRAY[
		('x', 'integer', 'some column with integer values'),
		('y', 'integer', 'some column with integer values'),
		('z', 'text', 'some column with text values')
	]::attribute_directory.attribute_descr[]
);

INSERT INTO attribute_staging."some_datasource_name_some_entitytype_name"(
    entity_id,
    timestamp,
    x, y, z
) VALUES
    ((directory.dn_to_entity('Node=001')).id, '2014-10-15 13:00', 40, 1, 'Test node 1a'),
    ((directory.dn_to_entity('Node=001')).id, '2014-11-17 13:00', 42, 2, 'Test node 1b'),
    ((directory.dn_to_entity('Node=001')).id, '2015-01-01 13:00', 41, 3, 'Test node 1c'),
    ((directory.dn_to_entity('Node=001')).id, '2015-02-02 13:00', 42, 4, 'Test node 1d'),
    ((directory.dn_to_entity('Node=002')).id, '2014-10-25 13:01', 10, 5, 'Test node 2a'),
    ((directory.dn_to_entity('Node=002')).id, '2014-11-17 13:01', 12, 6, 'Test node 2b'),
    ((directory.dn_to_entity('Node=002')).id, '2015-01-01 13:01', 11, 7, 'Test node 2c'),
    ((directory.dn_to_entity('Node=002')).id, '2015-02-02 13:01', 12, 8, 'Test node 2d');

SELECT attribute_directory.transfer_staged(attributestore)
  FROM attribute_directory.attributestore WHERE attributestore::text = 'some_datasource_name_some_entitytype_name';

-- Check Clean non existing records
SELECT attribute_directory.clean(attributestore, '2014-01-01 00:00')
  FROM attribute_directory.attributestore WHERE attributestore::text = 'some_datasource_name_some_entitytype_name';

SELECT results_eq(
    'SELECT timestamp, x,y,z FROM attribute_history."some_datasource_name_some_entitytype_name" ORDER BY timestamp, entity_id',
    $$VALUES
        ('2014-10-15 13:00'::timestamp with time zone, 40, 1, 'Test node 1a'),
        ('2014-10-25 13:01'::timestamp with time zone, 10, 5, 'Test node 2a'),
        ('2014-11-17 13:00'::timestamp with time zone, 42, 2, 'Test node 1b'),
        ('2014-11-17 13:01'::timestamp with time zone, 12, 6, 'Test node 2b'),
        ('2015-01-01 13:00'::timestamp with time zone, 41, 3, 'Test node 1c'),
        ('2015-01-01 13:01'::timestamp with time zone, 11, 7, 'Test node 2c'),
        ('2015-02-02 13:00'::timestamp with time zone, 42, 4, 'Test node 1d'),
        ('2015-02-02 13:01'::timestamp with time zone, 12, 8, 'Test node 2d')
    $$,
    'Check after clean with nothing to clean.');


-- First clean
SELECT attribute_directory.clean(attributestore, '2014-10-20 00:00')
  FROM attribute_directory.attributestore WHERE attributestore::text = 'some_datasource_name_some_entitytype_name';

SELECT results_eq(
    'SELECT timestamp, x,y,z FROM attribute_history."some_datasource_name_some_entitytype_name" ORDER BY timestamp, entity_id',
    $$VALUES
        ('2014-10-20 00:00'::timestamp with time zone, 40, 1, 'Test node 1a'),
        ('2014-10-25 13:01'::timestamp with time zone, 10, 5, 'Test node 2a'),
        ('2014-11-17 13:00'::timestamp with time zone, 42, 2, 'Test node 1b'),
        ('2014-11-17 13:01'::timestamp with time zone, 12, 6, 'Test node 2b'),
        ('2015-01-01 13:00'::timestamp with time zone, 41, 3, 'Test node 1c'),
        ('2015-01-01 13:01'::timestamp with time zone, 11, 7, 'Test node 2c'),
        ('2015-02-02 13:00'::timestamp with time zone, 42, 4, 'Test node 1d'),
        ('2015-02-02 13:01'::timestamp with time zone, 12, 8, 'Test node 2d')
    $$,
    'Check after first clean.');

-- Second clean
SELECT attribute_directory.clean(attributestore, '2015-01-15 00:00')
  FROM attribute_directory.attributestore WHERE attributestore::text = 'some_datasource_name_some_entitytype_name';

SELECT results_eq(
    'SELECT timestamp, x,y,z FROM attribute_history."some_datasource_name_some_entitytype_name" ORDER BY timestamp, entity_id',
    $$VALUES
        ('2015-01-15 00:00'::timestamp with time zone, 41, 3, 'Test node 1c'),
        ('2015-01-15 00:00'::timestamp with time zone, 11, 7, 'Test node 2c'),
        ('2015-02-02 13:00'::timestamp with time zone, 42, 4, 'Test node 1d'),
        ('2015-02-02 13:01'::timestamp with time zone, 12, 8, 'Test node 2d')
    $$,
    'Check after second clean.');

-- Third clean
SELECT attribute_directory.clean(attributestore, '2015-03-01 00:00')
  FROM attribute_directory.attributestore WHERE attributestore::text = 'some_datasource_name_some_entitytype_name';

SELECT results_eq(
    'SELECT timestamp, x,y,z FROM attribute_history."some_datasource_name_some_entitytype_name" ORDER BY timestamp, entity_id',
    $$VALUES
        ('2015-03-01 00:00'::timestamp with time zone, 42, 4, 'Test node 1d'),
        ('2015-03-01 00:00'::timestamp with time zone, 12, 8, 'Test node 2d')
    $$,
    'Check after third clean.');


SELECT * FROM finish();
ROLLBACK;
