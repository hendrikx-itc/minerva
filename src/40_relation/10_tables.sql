------------------------------
-- Schema 'relation_directory'
------------------------------

CREATE SCHEMA relation_directory;

COMMENT ON SCHEMA relation_directory IS
'Stores directional relations between entities.';

GRANT ALL ON SCHEMA relation_directory TO minerva_writer;
GRANT USAGE ON SCHEMA relation_directory TO minerva;

-- Table 'relation_directory.type'

CREATE TYPE relation_directory.type_cardinality_enum AS ENUM (
    'one-to-one',
    'one-to-many',
    'many-to-one'
);

CREATE TABLE relation_directory."type" (
    id serial,
    name name NOT NULL,
    cardinality relation_directory.type_cardinality_enum DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE(name)
);

GRANT SELECT ON TABLE relation_directory."type" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE relation_directory."type" TO minerva_writer;

------------------------
-- Schema 'relation_def'
------------------------

CREATE SCHEMA relation_def;

GRANT ALL ON SCHEMA relation_def TO minerva_writer;
GRANT USAGE ON SCHEMA relation_def TO minerva;

COMMENT ON SCHEMA relation_def IS
'Stores definitions of relations in the form of views. These views are used to
populate the corresponding tables in the relation schema';

------------------------------
-- Schema 'relation'
------------------------------

CREATE SCHEMA relation;

COMMENT ON SCHEMA relation IS
'Stores the actual relations between entities in dynamically created tables.';

GRANT ALL ON SCHEMA relation TO minerva_writer;
GRANT USAGE ON SCHEMA relation TO minerva;


-- Table 'relation.base'

CREATE TABLE relation."base" (
    source_id integer NOT NULL,
    target_id integer NOT NULL
);

COMMENT ON TABLE relation."base" IS
'This table is used as the parent/base table for all relation tables and
therefore can be queried to include all relations of all types.';

GRANT SELECT ON TABLE relation."base" TO minerva;

