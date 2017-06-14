BEGIN;

SELECT plan(4);

SELECT attribute_directory.create_attributestore('existence', 'Node', ARRAY[ ('exists', 'boolean', NULL) ]::attribute_directory.attribute_descr[]);
SELECT attribute_directory.create_attributestore('existence', 'Cell', ARRAY[ ('exists', 'boolean', NULL) ]::attribute_directory.attribute_descr[]);

SELECT directory.dn_to_entity('Node=001');
SELECT directory.dn_to_entity('Node=002');
SELECT directory.dn_to_entity('Node=003');
SELECT directory.dn_to_entity('Cell=001');
SELECT directory.dn_to_entity('Cell=002');
SELECT directory.dn_to_entity('Cell=003');

INSERT INTO directory.existence_staging(dn) VALUES  ('Cell=001'), ('Node=001'), ('Node=003'), ('Cell=002');

SELECT directory.transfer_existence('2015-01-01');

SELECT attribute_directory.materialize_curr_ptr(attributestore)
  FROM attribute_directory.attributestore
  WHERE attributestore::text = 'existence_Node';

SELECT attribute_directory.materialize_curr_ptr(attributestore)
  FROM attribute_directory.attributestore
  WHERE attributestore::text = 'existence_Cell';

SELECT entity.dn, e.exists FROM attribute."existence_Node" e JOIN directory.entity on entity.id = e.entity_id ORDER BY entity.dn;

SELECT results_eq(
    'SELECT entity.dn::text, e.exists::boolean FROM attribute."existence_Node" e JOIN directory.entity on entity.id = e.entity_id ORDER BY entity.dn',
    $$VALUES
        ('Node=001'::text, True::boolean),
        ('Node=002'::text, False::boolean),
        ('Node=003'::text, True::boolean)
    $$,
    'Check #1 Node');

SELECT results_eq(
    'SELECT entity.dn::text, e.exists::boolean FROM attribute."existence_Cell" e JOIN directory.entity on entity.id = e.entity_id ORDER BY entity.dn',
    $$VALUES
        ('Cell=001'::text, True::boolean),
        ('Cell=002'::text, True::boolean),
        ('Cell=003'::text, False::boolean)
    $$,
    'Check #1 Cell');

INSERT INTO directory.existence_staging(dn) VALUES ('Cell=003'), ('Node=002'), ('Node=003'), ('Cell=001');

SELECT directory.transfer_existence('2015-02-01');

SELECT attribute_directory.materialize_curr_ptr(attributestore)
  FROM attribute_directory.attributestore
  WHERE attributestore::text = 'existence_Node';

SELECT attribute_directory.materialize_curr_ptr(attributestore)
  FROM attribute_directory.attributestore
  WHERE attributestore::text = 'existence_Cell';

SELECT results_eq(
    'SELECT entity.dn::text, e.exists::boolean FROM attribute."existence_Node" e JOIN directory.entity on entity.id = e.entity_id ORDER BY entity.dn',
    $$VALUES
        ('Node=001'::text, False::boolean),
        ('Node=002'::text, True::boolean),
        ('Node=003'::text, True::boolean)
    $$,
    'Check #2 Node');

SELECT results_eq(
    'SELECT entity.dn::text, e.exists::boolean FROM attribute."existence_Cell" e JOIN directory.entity on entity.id = e.entity_id ORDER BY entity.dn',
    $$VALUES
        ('Cell=001'::text, True::boolean),
        ('Cell=002'::text, False::boolean),
        ('Cell=003'::text, True::boolean)
    $$,
    'Check #2 Cell');


SELECT * FROM finish();
ROLLBACK;
