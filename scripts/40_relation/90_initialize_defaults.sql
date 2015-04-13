INSERT INTO relation."type" (name) VALUES ('self');

-- Dummy relations to satisfy geospatial requirements
SELECT relation.define_reverse(
    'HandoverRelation->Cell',
    relation.define(
        'Cell->HandoverRelation',
        $$SELECT 0 as source_id, 0 as target_id WHERE false;$$
    )
);

SELECT relation.define(
    'real_handover',
    $$SELECT 0 as source_id, 0 as target_id WHERE false;$$
);


SELECT relation.define(
    'self',
    $$SELECT id as source_id, id as target_id FROM directory.entity;$$
);
