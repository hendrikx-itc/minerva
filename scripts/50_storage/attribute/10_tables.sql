-- Table 'attribute_directory.attributestore'

CREATE TABLE attribute_directory.attributestore (
    id integer not null,
    datasource_id integer not null,
    entitytype_id integer not null
);

ALTER TABLE attribute_directory.attributestore OWNER TO minerva_admin;

CREATE SEQUENCE attribute_directory.attributestore_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE attribute_directory.attributestore_id_seq OWNER TO minerva_admin;

ALTER TABLE attribute_directory.attributestore ALTER COLUMN id SET DEFAULT nextval('attribute_directory.attributestore_id_seq'::regclass);

ALTER SEQUENCE attribute_directory.attributestore_id_seq OWNED BY attribute_directory.attributestore.id;

ALTER TABLE ONLY attribute_directory.attributestore
    ADD CONSTRAINT attributestore_pkey PRIMARY KEY (id);

ALTER TABLE attribute_directory.attributestore
    ADD CONSTRAINT attributestore_uniqueness UNIQUE (datasource_id, entitytype_id);

ALTER TABLE ONLY attribute_directory.attributestore
    ADD CONSTRAINT attribute_attributestore_entitytype_id_fkey
    FOREIGN KEY (entitytype_id) REFERENCES directory.entitytype(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY attribute_directory.attributestore
    ADD CONSTRAINT attribute_attributestore_datasource_id_fkey
    FOREIGN KEY(datasource_id) REFERENCES directory.datasource(id);

GRANT SELECT ON TABLE attribute_directory.attributestore TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE attribute_directory.attributestore TO minerva_writer;

GRANT SELECT ON SEQUENCE attribute_directory.attributestore_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE attribute_directory.attributestore_id_seq TO minerva_writer;


-- Type 'attribute_directory.attribute_descr'

CREATE TYPE attribute_directory.attribute_descr AS (
    name name,
    datatype varchar,
    description text
);

ALTER TYPE attribute_directory.attribute_descr OWNER TO minerva_admin;


-- Table 'attribute_directory.attribute'

CREATE TABLE attribute_directory.attribute (
    id integer not null,
    attributestore_id integer not null,
    description text,
    name name not null,
    datatype varchar not null
);

ALTER TABLE attribute_directory.attribute OWNER TO minerva_admin;

CREATE SEQUENCE attribute_directory.attribute_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE attribute_directory.attribute_id_seq OWNER TO minerva_admin;

ALTER TABLE attribute_directory.attribute ALTER COLUMN id SET DEFAULT nextval('attribute_directory.attribute_id_seq'::regclass);

ALTER SEQUENCE attribute_directory.attribute_id_seq OWNED BY attribute_directory.attribute.id;

ALTER TABLE ONLY attribute_directory.attribute
    ADD CONSTRAINT attribute_pkey PRIMARY KEY (id);

ALTER TABLE attribute_directory.attribute
    ADD CONSTRAINT attribute_uniqueness UNIQUE (attributestore_id, name);

ALTER TABLE ONLY attribute_directory.attribute
    ADD CONSTRAINT attribute_attribute_attributestore_id_fkey
    FOREIGN KEY(attributestore_id) REFERENCES attribute_directory.attributestore(id)
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

ALTER TABLE attribute_directory.attribute_tag_link OWNER TO minerva_admin;

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

-- Table 'attribute_directory.attributestore_modified'

CREATE TABLE attribute_directory.attributestore_modified (
    attributestore_id integer NOT NULL,
    modified timestamp with time zone NOT NULL
);

ALTER TABLE attribute_directory.attributestore_modified OWNER TO minerva_admin;

ALTER TABLE ONLY attribute_directory.attributestore_modified
    ADD CONSTRAINT attributestore_modified_pkey PRIMARY KEY (attributestore_id);

ALTER TABLE ONLY attribute_directory.attributestore_modified
    ADD CONSTRAINT attributestore_modified_attributestore_id_fkey FOREIGN KEY (attributestore_id) REFERENCES attribute_directory.attributestore(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE attribute_directory.attributestore_modified TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE attribute_directory.attributestore_modified TO minerva_writer;

-- Table 'attribute_directory.attributestore_curr_materialized'

CREATE TABLE attribute_directory.attributestore_curr_materialized (
    attributestore_id integer NOT NULL,
    materialized timestamp with time zone NOT NULL
);

ALTER TABLE attribute_directory.attributestore_curr_materialized OWNER TO minerva_admin;

ALTER TABLE ONLY attribute_directory.attributestore_curr_materialized
    ADD CONSTRAINT attributestore_curr_materialized_pkey PRIMARY KEY (attributestore_id);

ALTER TABLE ONLY attribute_directory.attributestore_curr_materialized
    ADD CONSTRAINT attributestore_curr_materialized_attributestore_id_fkey FOREIGN KEY (attributestore_id) REFERENCES attribute_directory.attributestore(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE attribute_directory.attributestore_curr_materialized TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE attribute_directory.attributestore_curr_materialized TO minerva_writer;

-- Table 'attribute_directory.attributestore_compacted'

CREATE TABLE attribute_directory.attributestore_compacted (
    attributestore_id integer NOT NULL,
    compacted timestamp with time zone NOT NULL
);

ALTER TABLE attribute_directory.attributestore_compacted OWNER TO minerva_admin;

ALTER TABLE ONLY attribute_directory.attributestore_compacted
    ADD CONSTRAINT attributestore_compacted_pkey PRIMARY KEY (attributestore_id);

ALTER TABLE ONLY attribute_directory.attributestore_compacted
    ADD CONSTRAINT attributestore_compacted_attributestore_id_fkey FOREIGN KEY (attributestore_id) REFERENCES attribute_directory.attributestore(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE attribute_directory.attributestore_compacted TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE attribute_directory.attributestore_compacted TO minerva_writer;
