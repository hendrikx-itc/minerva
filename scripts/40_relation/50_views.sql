INSERT INTO relation.type(name) VALUES ('self');

CREATE VIEW relation.self AS
SELECT
    id AS source_id,
    id AS target_id
FROM directory.entity;


CREATE VIEW relation.all AS
SELECT source_id, target_id FROM relation.all_tables
UNION ALL
SELECT source_id, target_id FROM relation.self;

