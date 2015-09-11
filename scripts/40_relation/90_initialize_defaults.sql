INSERT INTO relation."type" (name) VALUES ('self');

SELECT relation.define(
    'self',
    $$SELECT id as source_id, id as target_id FROM directory.entity;$$
);
