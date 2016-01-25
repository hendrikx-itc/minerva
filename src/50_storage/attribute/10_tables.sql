-- Table 'attribute_directory.attribute_store'

CREATE TABLE attribute_directory.attribute_store (
    id integer not null,
    data_source_id integer not null,
    entity_type_id integer not null
);

CREATE SEQUENCE attribute_directory.attribute_store_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE attribute_directory.attribute_store ALTER COLUMN id SET DEFAULT nextval('attribute_directory.attribute_store_id_seq'::regclass);

ALTER SEQUENCE attribute_directory.attribute_store_id_seq OWNED BY attribute_directory.attribute_store.id;

ALTER TABLE ONLY attribute_directory.attribute_store
    ADD CONSTRAINT attribute_store_pkey PRIMARY KEY (id);

ALTER TABLE attribute_directory.attribute_store
    ADD CONSTRAINT attribute_store_uniqueness UNIQUE (data_source_id, entity_type_id);

ALTER TABLE ONLY attribute_directory.attribute_store
    ADD CONSTRAINT attribute_attribute_store_entity_type_id_fkey
    FOREIGN KEY (entity_type_id) REFERENCES directory.entity_type(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY attribute_directory.attribute_store
    ADD CONSTRAINT attribute_attribute_store_data_source_id_fkey
    FOREIGN KEY(data_source_id) REFERENCES directory.data_source(id);

GRANT SELECT ON TABLE attribute_directory.attribute_store TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE attribute_directory.attribute_store TO minerva_writer;

GRANT SELECT ON SEQUENCE attribute_directory.attribute_store_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE attribute_directory.attribute_store_id_seq TO minerva_writer;


-- Type 'attribute_directory.attribute_descr'

CREATE TYPE attribute_directory.attribute_descr AS (
    name name,
    data_type text,
    description text
);


-- Table 'attribute_directory.attribute'

CREATE TABLE attribute_directory.attribute (
    id integer not null,
    attribute_store_id integer not null,
    description text,
    name name not null,
    data_type text not null
);

CREATE SEQUENCE attribute_directory.attribute_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE attribute_directory.attribute ALTER COLUMN id SET DEFAULT nextval('attribute_directory.attribute_id_seq'::regclass);

ALTER SEQUENCE attribute_directory.attribute_id_seq OWNED BY attribute_directory.attribute.id;

ALTER TABLE ONLY attribute_directory.attribute
    ADD CONSTRAINT attribute_pkey PRIMARY KEY (id);

ALTER TABLE attribute_directory.attribute
    ADD CONSTRAINT attribute_uniqueness UNIQUE (attribute_store_id, name);

ALTER TABLE ONLY attribute_directory.attribute
    ADD CONSTRAINT attribute_attribute_attribute_store_id_fkey
    FOREIGN KEY(attribute_store_id) REFERENCES attribute_directory.attribute_store(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE attribute_directory.attribute TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE attribute_directory.attribute TO minerva_writer;

GRANT SELECT ON SEQUENCE attribute_directory.attribute_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE attribute_directory.attribute_id_seq TO minerva_writer;

-- Table 'attribute_directory.attribute_tag_link'

CREATE TABLE attribute_directory.attribute_tag_link (
    attribute_id integer NOT NULL,
    tag_id integer NOT NULL
);

ALTER TABLE ONLY attribute_directory.attribute_tag_link
    ADD CONSTRAINT attribute_tag_link_pkey PRIMARY KEY (attribute_id, tag_id);

ALTER TABLE ONLY attribute_directory.attribute_tag_link
    ADD CONSTRAINT attribute_tag_link_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES directory.tag(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY attribute_directory.attribute_tag_link
    ADD CONSTRAINT attribute_tag_link_attribute_id_fkey FOREIGN KEY (attribute_id) REFERENCES attribute_directory.attribute(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE attribute_directory.attribute_tag_link TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE attribute_directory.attribute_tag_link TO minerva_writer;

-- Table 'attribute_directory.attribute_store_modified'

CREATE TABLE attribute_directory.attribute_store_modified (
    attribute_store_id integer NOT NULL,
    modified timestamp with time zone NOT NULL
);

ALTER TABLE ONLY attribute_directory.attribute_store_modified
    ADD CONSTRAINT attribute_store_modified_pkey PRIMARY KEY (attribute_store_id);

ALTER TABLE ONLY attribute_directory.attribute_store_modified
    ADD CONSTRAINT attribute_store_modified_attribute_store_id_fkey FOREIGN KEY (attribute_store_id) REFERENCES attribute_directory.attribute_store(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE attribute_directory.attribute_store_modified TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE attribute_directory.attribute_store_modified TO minerva_writer;

-- Table 'attribute_directory.attribute_store_curr_materialized'

CREATE TABLE attribute_directory.attribute_store_curr_materialized (
    attribute_store_id integer NOT NULL,
    materialized timestamp with time zone NOT NULL
);

ALTER TABLE ONLY attribute_directory.attribute_store_curr_materialized
    ADD CONSTRAINT attribute_store_curr_materialized_pkey PRIMARY KEY (attribute_store_id);

ALTER TABLE ONLY attribute_directory.attribute_store_curr_materialized
    ADD CONSTRAINT attribute_store_curr_materialized_attribute_store_id_fkey FOREIGN KEY (attribute_store_id) REFERENCES attribute_directory.attribute_store(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE attribute_directory.attribute_store_curr_materialized TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE attribute_directory.attribute_store_curr_materialized TO minerva_writer;

-- Table 'attribute_directory.attribute_store_compacted'

CREATE TABLE attribute_directory.attribute_store_compacted (
    attribute_store_id integer NOT NULL,
    compacted timestamp with time zone NOT NULL
);

ALTER TABLE ONLY attribute_directory.attribute_store_compacted
    ADD CONSTRAINT attribute_store_compacted_pkey PRIMARY KEY (attribute_store_id);

ALTER TABLE ONLY attribute_directory.attribute_store_compacted
    ADD CONSTRAINT attribute_store_compacted_attribute_store_id_fkey FOREIGN KEY (attribute_store_id) REFERENCES attribute_directory.attribute_store(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE attribute_directory.attribute_store_compacted TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE attribute_directory.attribute_store_compacted TO minerva_writer;
