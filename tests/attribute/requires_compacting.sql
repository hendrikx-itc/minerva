BEGIN;

SELECT plan(4);

CALL attribute_directory.create_attribute_store('ds', 'type1');
CALL attribute_directory.create_attribute_store('ds', 'type2');
CALL attribute_directory.create_attribute_store('ds', 'type3');
CALL attribute_directory.create_attribute_store('ds', 'type4');

INSERT INTO attribute_history.ds_type1(entity_id, timestamp) VALUES
    ((entity.to_type1('entity1')).id, now());
INSERT INTO attribute_history.ds_type1(entity_id, timestamp) VALUES
    ((entity.to_type1('entity2')).id, now());
INSERT INTO attribute_history.ds_type1(entity_id, timestamp) VALUES
    ((entity.to_type1('entity3')).id, now());

SELECT attribute_directory.compact(attribute_directory.get_attribute_store('ds', 'type1'), 0);
SELECT attribute_directory.compact(attribute_directory.get_attribute_store('ds', 'type2'), 0);


INSERT INTO attribute_history.ds_type1(entity_id, timestamp) VALUES
    ((entity.to_type1('entity1')).id, now());
INSERT INTO attribute_history.ds_type1(entity_id, timestamp) VALUES
    ((entity.to_type1('entity2')).id, now());

SELECT attribute_directory.compact(attribute_directory.get_attribute_store('ds', 'type1'), 0);

SELECT is(
    attribute_directory.requires_compacting(attribute_directory.get_attribute_store('ds', 'type1')),
    false,
    'recently compacted attribute_store should not need compacting'
);

SELECT is(
    attribute_directory.requires_compacting(attribute_directory.get_attribute_store('ds', 'type2')),
    true,
    'attribute_store that is modified after compacting should need compacting'
);

SELECT is(
    attribute_directory.requires_compacting(attribute_directory.get_attribute_store('ds', 'type3')),
    true,
    'attribute_store that was never compacted should need compacting'
);

SELECT isnt(
    attribute_directory.requires_compacting(attribute_directory.get_attribute_store('ds', 'type4')),
    true,
    'attribute_store that was never modified should not need compacting'
);

SELECT * FROM finish();
ROLLBACK;
