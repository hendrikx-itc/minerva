BEGIN;

SELECT plan(2);

SELECT attribute_directory.create_attributestore(
    'existence', 'Node',
    ARRAY[ ('exists', 'boolean', NULL) ]::attribute_directory.attribute_descr[]);

SELECT directory.dn_to_entity('Node=001');
SELECT directory.dn_to_entity('Node=002');
SELECT directory.dn_to_entity('Node=003');
SELECT directory.dn_to_entity('Node=004');
SELECT directory.dn_to_entity('Node=005');

INSERT INTO directory.existence_staging(dn) VALUES  ('Node=001'), ('Node=002'), ('Node=003'), ('Node=004');

SELECT directory.transfer_existence('2015-01-01');

SELECT attribute_directory.materialize_curr_ptr(attributestore)
  FROM attribute_directory.attributestore
  WHERE attributestore::text = 'existence_Node';

SELECT entity.dn, e.exists FROM attribute."existence_Node" e JOIN directory.entity on entity.id = e.entity_id ORDER BY entity.dn;

SELECT results_eq(
    'SELECT entity.dn::text, e.exists::boolean FROM attribute."existence_Node" e JOIN directory.entity on entity.id = e.entity_id ORDER BY entity.dn',
    $$VALUES
        ('Node=001'::text, True::boolean),
        ('Node=002'::text, True::boolean),
        ('Node=003'::text, True::boolean),
        ('Node=004'::text, True::boolean),
        ('Node=005'::text, False::boolean)
    $$,
    'Check #1');

INSERT INTO directory.existence_staging(dn) VALUES ('Node=001'), ('Node=002'), ('Node=003');

SELECT directory.transfer_existence('2015-02-01');

SELECT attribute_directory.materialize_curr_ptr(attributestore)
  FROM attribute_directory.attributestore
  WHERE attributestore::text = 'existence_Node';

SELECT results_eq(
    'SELECT entity.dn::text, e.exists::boolean FROM attribute."existence_Node" e JOIN directory.entity on entity.id = e.entity_id ORDER BY entity.dn',
    $$VALUES
        ('Node=001'::text, True::boolean),
        ('Node=002'::text, True::boolean),
        ('Node=003'::text, True::boolean),
        ('Node=004'::text, False::boolean),
        ('Node=005'::text, False::boolean)
    $$,
    'Check #2.');


SELECT * FROM finish();
ROLLBACK;
