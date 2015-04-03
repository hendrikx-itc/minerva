CREATE SCHEMA directory;

COMMENT ON SCHEMA directory IS
'Stores contextual information for the data. This includes the entities, '
'entity_types, data_sources, etc. It is the entrypoint when looking for data.';

GRANT USAGE ON SCHEMA directory TO minerva;

-- Table 'directory.data_source'

CREATE TABLE directory.data_source (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description character varying NOT NULL
);

COMMENT ON TABLE directory.data_source IS
'Describes data_sources. A data_source is used to indicate where data came from. '
'Datasources are also used to prevent collisions between sets of data from '
'different sources, where names can be the same, but the meaning of the data '
'differs.';

CREATE SEQUENCE directory.data_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE directory.data_source_id_seq OWNED BY directory.data_source.id;

ALTER TABLE directory.data_source ALTER COLUMN id SET DEFAULT nextval('directory.data_source_id_seq'::regclass);

ALTER TABLE ONLY directory.data_source
    ADD CONSTRAINT data_source_pkey PRIMARY KEY (id);

GRANT SELECT ON TABLE directory.data_source TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.data_source TO minerva_writer;

GRANT SELECT ON SEQUENCE directory.data_source_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE directory.data_source_id_seq TO minerva_writer;

CREATE UNIQUE INDEX ix_directory_data_source_name ON directory.data_source USING btree (name);

-- Table 'entity_type'

CREATE TABLE directory.entity_type (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying NOT NULL
);

COMMENT ON TABLE directory.entity_type IS
'Stores the entity types that exist in the entity table. Entity types are '
'also used to give context to data that is stored for entities.';

CREATE SEQUENCE directory.entity_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE directory.entity_type_id_seq OWNED BY directory.entity_type.id;
ALTER TABLE directory.entity_type
    ALTER COLUMN id
    SET DEFAULT nextval('directory.entity_type_id_seq'::regclass);

ALTER TABLE ONLY directory.entity_type
    ADD CONSTRAINT entity_type_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX ix_directory_entity_type_name
    ON directory.entity_type (lower(name));

GRANT SELECT ON TABLE directory.entity_type TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.entity_type TO minerva_writer;

GRANT SELECT ON SEQUENCE directory.entity_type_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE directory.entity_type_id_seq TO minerva_writer;

-- Table 'directory.entity'

CREATE TABLE directory.entity (
    id integer NOT NULL,
    created timestamp with time zone NOT NULL,
    name character varying NOT NULL,
    entity_type_id integer NOT NULL,
    dn character varying NOT NULL,
    parent_id integer
);

COMMENT ON TABLE directory.entity IS
'Describes entities. An entity is the base object for which the database can '
'hold further information such as attributes, trends and notifications. All '
'data must have a reference to an entity.';

CREATE SEQUENCE directory.entity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE directory.entity_id_seq OWNED BY directory.entity.id;

ALTER TABLE directory.entity
    ALTER COLUMN id
    SET DEFAULT nextval('directory.entity_id_seq'::regclass);

ALTER TABLE ONLY directory.entity
    ADD CONSTRAINT entity_pkey PRIMARY KEY (id);

GRANT SELECT ON TABLE directory.entity TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.entity TO minerva_writer;

GRANT SELECT ON SEQUENCE directory.entity_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE directory.entity_id_seq TO minerva_writer;

ALTER TABLE ONLY directory.entity
    ADD CONSTRAINT entity_entity_type_id_fkey
    FOREIGN KEY (entity_type_id) REFERENCES directory.entity_type(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY directory.entity
    ADD CONSTRAINT entity_parent_id_fkey
    FOREIGN KEY (parent_id) REFERENCES directory.entity(id)
    ON DELETE CASCADE;

CREATE UNIQUE INDEX ix_directory_entity_dn
    ON directory.entity USING btree (dn);

CREATE INDEX ix_directory_entity_name
    ON directory.entity USING btree (name);

CREATE INDEX parent_id ON directory.entity USING btree (parent_id);
CREATE INDEX ix_directory_entity_entity_type_id ON directory.entity USING btree (entity_type_id);

-- Table 'directory.tag_group'

CREATE TABLE directory.tag_group (
    id integer NOT NULL,
    name character varying NOT NULL,
    complementary boolean NOT NULL
);

CREATE UNIQUE INDEX ix_directory_tag_group_name on directory.tag_group (lower(name));

CREATE SEQUENCE directory.tag_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE directory.tag_group
    ALTER COLUMN id
    SET DEFAULT nextval('directory.tag_group_id_seq'::regclass);

ALTER SEQUENCE directory.tag_group_id_seq OWNED BY directory.tag_group.id;

ALTER TABLE ONLY directory.tag_group
    ADD CONSTRAINT tag_group_pkey PRIMARY KEY (id);

GRANT SELECT ON TABLE directory.tag_group TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.tag_group TO minerva_writer;

GRANT SELECT ON SEQUENCE directory.tag_group_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE directory.tag_group_id_seq TO minerva_writer;

INSERT INTO directory.tag_group (name, complementary) VALUES ('default', false);
INSERT INTO directory.tag_group (name, complementary) VALUES ('entity_type', true);

-- Table 'directory.tag'

CREATE TABLE directory.tag (
    id integer NOT NULL,
    name character varying NOT NULL,
    tag_group_id integer NOT NULL,
    description character varying
);

COMMENT ON TABLE directory.tag IS
'Stores all tags. A tag is a simple label that can be attached to a number of '
'object types in the database, such as entities and trends.';

CREATE UNIQUE INDEX ix_directory_tag_name
    ON directory.tag (lower(name));

CREATE INDEX ON directory.tag (lower(name), id);

CREATE SEQUENCE directory.tag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE directory.tag
    ALTER COLUMN id
    SET DEFAULT nextval('directory.tag_id_seq'::regclass);

ALTER SEQUENCE directory.tag_id_seq OWNED BY directory.tag.id;

ALTER TABLE ONLY directory.tag
    ADD CONSTRAINT tag_pkey PRIMARY KEY (id);

ALTER TABLE ONLY directory.tag
    ADD CONSTRAINT tag_tag_group_id_fkey
    FOREIGN KEY (tag_group_id) REFERENCES directory.tag_group(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE directory.tag TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.tag TO minerva_writer;

GRANT SELECT ON SEQUENCE directory.tag_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE directory.tag_id_seq TO minerva_writer;

-- Table 'directory.entity_tag_link'

CREATE TABLE directory.entity_tag_link (
    tag_id integer NOT NULL,
    entity_id integer NOT NULL
);

ALTER TABLE ONLY directory.entity_tag_link
    ADD CONSTRAINT entity_tag_link_pkey PRIMARY KEY (tag_id, entity_id);

GRANT SELECT ON TABLE directory.entity_tag_link TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.entity_tag_link TO minerva_writer;

ALTER TABLE ONLY directory.entity_tag_link
    ADD CONSTRAINT entity_tag_link_entity_id_fkey
    FOREIGN KEY (entity_id) REFERENCES directory.entity(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY directory.entity_tag_link
    ADD CONSTRAINT entity_tag_link_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES directory.tag(id)
    ON DELETE CASCADE;

CREATE INDEX ix_directory_entity_tag_link_entity_id
    ON directory.entity_tag_link USING btree (entity_id);

-- Table 'directory.entity_tag_link_denorm'

CREATE TABLE directory.entity_tag_link_denorm (
    entity_id integer primary key not null,
    tags text[] not null,
    name text not null
);

CREATE INDEX ON directory.entity_tag_link_denorm USING gin (tags);
CREATE INDEX ON directory.entity_tag_link_denorm (name);

GRANT SELECT ON TABLE directory.entity_tag_link_denorm TO minerva;
GRANT UPDATE, INSERT, DELETE ON TABLE directory.entity_tag_link_denorm TO minerva_writer;


-- Table 'directory.alias_type'

CREATE TABLE directory.alias_type
(
    id integer NOT NULL,
    "name" character varying NOT NULL
);

CREATE SEQUENCE directory.alias_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE directory.alias_type_id_seq OWNED BY directory.alias_type.id;
ALTER TABLE directory.alias_type
    ALTER COLUMN id
    SET DEFAULT nextval('directory.alias_type_id_seq'::regclass);

GRANT SELECT ON SEQUENCE directory.alias_type_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE directory.alias_type_id_seq TO minerva_writer;

ALTER TABLE ONLY directory.alias_type
    ADD CONSTRAINT alias_type_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX ix_directory_alias_type_name
    ON directory.alias_type (lower(name));

GRANT SELECT ON TABLE directory.alias_type TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.alias_type TO minerva_writer;

INSERT INTO directory.alias_type (name) VALUES ('name');

-- Table 'directory.alias'

CREATE TABLE directory.alias
(
    entity_id integer NOT NULL,
    "name" character varying NOT NULL,
    type_id integer NOT NULL
);

ALTER TABLE ONLY directory.alias
    ADD CONSTRAINT alias_pkey PRIMARY KEY (entity_id, type_id);

ALTER TABLE ONLY directory.alias
    ADD CONSTRAINT alias_entity_id_fkey
    FOREIGN KEY (entity_id) REFERENCES directory.entity(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY directory.alias
    ADD CONSTRAINT alias_alias_type_id_fkey
    FOREIGN KEY (type_id) REFERENCES directory.alias_type(id)
    ON DELETE CASCADE;

CREATE INDEX ON directory.alias USING btree (name);

CREATE INDEX ON directory.alias (lower(name));

GRANT SELECT ON TABLE directory.alias TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.alias TO minerva_writer;

-- Table 'directory.existence'

CREATE TABLE directory.existence
(
    timestamp timestamp with time zone NOT NULL,
    exists boolean NOT NULL,
    entity_id integer NOT NULL,
    entity_type_id integer NOT NULL
);

ALTER TABLE ONLY directory.existence
    ADD CONSTRAINT existence_pkey PRIMARY KEY (entity_id, timestamp);

ALTER TABLE ONLY directory.existence
    ADD CONSTRAINT existence_entity_id_fkey
    FOREIGN KEY (entity_id) REFERENCES directory.entity(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY directory.existence
    ADD CONSTRAINT existence_entity_type_id_fkey
    FOREIGN KEY (entity_type_id) REFERENCES directory.entity_type(id)
    ON DELETE CASCADE;

CREATE INDEX ix_directory_existence_timestamp
    ON directory.existence USING btree (timestamp);

GRANT SELECT ON TABLE directory.existence TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.existence TO minerva_writer;


-- View 'directory.existence_curr'

CREATE VIEW directory.existence_curr AS
SELECT
    entity_id,
    entity_type_id,
    public.first("timestamp" ORDER BY "timestamp" DESC) AS "timestamp",
    public.first("exists" ORDER BY "timestamp" DESC) AS "exists"
FROM directory.existence GROUP BY entity_id, entity_type_id;


-- Table 'directory.existence_staging'

CREATE UNLOGGED TABLE directory.existence_staging
(
    dn character varying NOT NULL UNIQUE
);

GRANT SELECT ON TABLE directory.existence_staging TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.existence_staging TO minerva_writer;


CREATE VIEW directory.existence_staging_entity_type_ids AS
SELECT entity.entity_type_id
FROM directory.existence_staging JOIN directory.entity
ON entity.dn = existence_staging.dn
GROUP BY entity_type_id;

GRANT SELECT ON TABLE directory.existence_staging_entity_type_ids TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.existence_staging_entity_type_ids TO minerva_writer;
