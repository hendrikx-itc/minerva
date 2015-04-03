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
    id integer NOT NULL,
    name character varying NOT NULL,
    cardinality relation_directory.type_cardinality_enum DEFAULT NULL
);

ALTER TABLE ONLY relation_directory."type"
    ADD CONSTRAINT type_pkey PRIMARY KEY (id);

GRANT SELECT ON TABLE relation_directory."type" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE relation_directory."type" TO minerva_writer;

CREATE SEQUENCE relation_directory.type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE relation_directory.type_id_seq OWNED BY relation_directory."type".id;

ALTER TABLE relation_directory."type"
    ALTER COLUMN id
    SET DEFAULT nextval('relation_directory.type_id_seq'::regclass);

GRANT SELECT ON SEQUENCE relation_directory.type_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE relation_directory.type_id_seq TO minerva_writer;

CREATE UNIQUE INDEX ix_type_name ON relation_directory."type" (name);

------------------------
-- Schema 'relation_def'
------------------------

CREATE SCHEMA relation_def;

GRANT ALL ON SCHEMA relation_def TO minerva_writer;
GRANT USAGE ON SCHEMA relation_def TO minerva;


------------------------------
-- Schema 'relation'
------------------------------

CREATE SCHEMA relation;

COMMENT ON SCHEMA relation IS
'Stores the actual relations between entities in dynamically created tables.';

GRANT ALL ON SCHEMA relation TO minerva_writer;
GRANT USAGE ON SCHEMA relation TO minerva;


-- Table 'relation.all'

CREATE TABLE relation."all" (
    source_id integer NOT NULL,
    target_id integer NOT NULL,
    type_id integer NOT NULL
);

ALTER TABLE ONLY relation."all"
    ADD PRIMARY KEY (source_id, target_id);

ALTER TABLE ONLY relation."all"
    ADD CONSTRAINT source_id_fkey
    FOREIGN KEY (source_id) REFERENCES directory.entity(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY relation."all"
    ADD CONSTRAINT target_id_fkey
    FOREIGN KEY (target_id) REFERENCES directory.entity(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE relation."all" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE relation."all" TO minerva_writer;

ALTER TABLE ONLY relation."all"
    ADD CONSTRAINT type_id_fkey
    FOREIGN KEY (type_id) REFERENCES relation_directory."type"(id)
    ON DELETE CASCADE;

CREATE INDEX ON relation."all" USING btree (target_id);
CREATE INDEX ON relation."all" USING btree (type_id);

-- Table 'relation.all_materialized'

CREATE TABLE relation.all_materialized (
    source_id integer NOT NULL,
    target_id integer NOT NULL,
    type_id integer NOT NULL
);

ALTER TABLE relation."all_materialized"
    ADD PRIMARY KEY (source_id, target_id, type_id);

GRANT SELECT ON TABLE relation."all_materialized" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE relation."all_materialized" TO minerva_writer;

CREATE INDEX ON relation."all_materialized" USING btree (target_id);
CREATE INDEX ON relation."all_materialized" USING btree (type_id);
