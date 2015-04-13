CREATE SCHEMA relation;

COMMENT ON SCHEMA relation IS
'Stores directional relations between entities.';

ALTER SCHEMA relation OWNER TO minerva_admin;

GRANT ALL ON SCHEMA relation TO minerva_admin;
GRANT ALL ON SCHEMA relation TO minerva_writer;
GRANT USAGE ON SCHEMA relation TO minerva;

CREATE SCHEMA relation_def;
ALTER SCHEMA relation_def OWNER TO minerva_admin;

GRANT ALL ON SCHEMA relation_def TO minerva_admin;
GRANT ALL ON SCHEMA relation_def TO minerva_writer;
GRANT USAGE ON SCHEMA relation_def TO minerva;

-- Table 'relation.group'

CREATE TABLE relation."group" (
    id integer NOT NULL,
    name character varying NOT NULL
);

ALTER TABLE relation."group" OWNER TO minerva_admin;

ALTER TABLE ONLY relation."group"
    ADD CONSTRAINT group_pkey PRIMARY KEY (id);

GRANT ALL ON TABLE relation."group" TO minerva_admin;
GRANT SELECT ON TABLE relation."group" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE relation."group" TO minerva_writer;

CREATE SEQUENCE relation.group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE relation.group_id_seq OWNER TO minerva_admin;

ALTER SEQUENCE relation.group_id_seq OWNED BY relation."group".id;

ALTER TABLE relation."group"
    ALTER COLUMN id
    SET DEFAULT nextval('relation.group_id_seq'::regclass);

GRANT ALL ON SEQUENCE relation.group_id_seq TO minerva_admin;
GRANT SELECT ON SEQUENCE relation.group_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE relation.group_id_seq TO minerva_writer;

CREATE UNIQUE INDEX ix_group_name ON relation."group" (name);

-- Table 'relation.type'

CREATE TYPE relation.type_cardinality_enum AS ENUM (
    'one-to-one',
    'one-to-many',
    'many-to-one'
);

CREATE TABLE relation."type" (
    id integer NOT NULL,
    name character varying NOT NULL,
    cardinality relation.type_cardinality_enum DEFAULT NULL,
    group_id integer DEFAULT NULL
);

ALTER TABLE relation."type" OWNER TO minerva_admin;

ALTER TABLE ONLY relation."type"
    ADD CONSTRAINT type_pkey PRIMARY KEY (id);

GRANT ALL ON TABLE relation."type" TO minerva_admin;
GRANT SELECT ON TABLE relation."type" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE relation."type" TO minerva_writer;

CREATE SEQUENCE relation.type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE relation.type_id_seq OWNER TO minerva_admin;

ALTER SEQUENCE relation.type_id_seq OWNED BY relation."type".id;

ALTER TABLE relation."type"
    ALTER COLUMN id
    SET DEFAULT nextval('relation.type_id_seq'::regclass);

ALTER TABLE ONLY relation."type"
    ADD CONSTRAINT group_id_fkey
    FOREIGN KEY (group_id) REFERENCES relation."group"(id)
    ON DELETE CASCADE;

GRANT ALL ON SEQUENCE relation.type_id_seq TO minerva_admin;
GRANT SELECT ON SEQUENCE relation.type_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE relation.type_id_seq TO minerva_writer;

CREATE UNIQUE INDEX ix_type_name ON relation."type" (name);

-- Table 'relation.all'

CREATE TABLE relation."all" (
    source_id integer NOT NULL,
    target_id integer NOT NULL,
    type_id integer NOT NULL
);

ALTER TABLE relation."all" OWNER TO minerva_admin;

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

GRANT ALL ON TABLE relation."all" TO minerva_admin;
GRANT SELECT ON TABLE relation."all" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE relation."all" TO minerva_writer;

ALTER TABLE ONLY relation."all"
    ADD CONSTRAINT type_id_fkey
    FOREIGN KEY (type_id) REFERENCES relation."type"(id)
    ON DELETE CASCADE;

CREATE INDEX ON relation."all" USING btree (target_id);
CREATE INDEX ON relation."all" USING btree (type_id);

-- Table 'relation.all_materialized'

CREATE TABLE relation.all_materialized (
    source_id integer NOT NULL,
    target_id integer NOT NULL,
    type_id integer NOT NULL
);

ALTER TABLE relation."all_materialized" OWNER TO minerva_admin;

ALTER TABLE relation."all_materialized"
    ADD PRIMARY KEY (source_id, target_id, type_id);

GRANT ALL ON TABLE relation."all_materialized" TO minerva_admin;
GRANT SELECT ON TABLE relation."all_materialized" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE relation."all_materialized" TO minerva_writer;

CREATE INDEX ON relation."all_materialized" USING btree (target_id);
CREATE INDEX ON relation."all_materialized" USING btree (type_id);

