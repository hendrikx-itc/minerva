BEGIN;

SELECT plan(1);

SELECT attribute_directory.create_attributestore(
    'existence', 'Node',
    ARRAY[ ('exists', 'boolean', NULL) ]::attribute_directory.attribute_descr[]);

SELECT directory.dn_to_entity('Node=001');
SELECT directory.dn_to_entity('Node=002');
SELECT directory.dn_to_entity('Node=003');

INSERT INTO directory.existence_staging(dn) VALUES  ('Node=001'), ('Node=002'), ('Node=001');

SELECT directory.transfer_existence('2015-01-01');

SELECT attribute_directory.materialize_curr_ptr(attributestore)
  FROM attribute_directory.attributestore
  WHERE attributestore::text = 'existence_Node';

SELECT results_eq(
    'SELECT entity.dn::text, e.exists::boolean FROM attribute."existence_Node" e JOIN directory.entity on entity.id = e.entity_id ORDER BY entity.dn',
    $$VALUES
        ('Node=001'::text, True::boolean),
        ('Node=002'::text, True::boolean),
        ('Node=003'::text, False::boolean)
    $$,
    'Check #1');

SELECT * FROM finish();
ROLLBACK;
