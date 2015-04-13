CREATE SCHEMA directory;

COMMENT ON SCHEMA directory IS
'Stores contextual information for the data. This includes the entities, '
'entitytypes, datasources, etc. It is the entrypoint when looking for data.';

ALTER SCHEMA directory OWNER TO minerva_admin;

GRANT USAGE ON SCHEMA directory TO minerva;

-- Table 'directory.datasource'

CREATE TABLE directory.datasource (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description character varying NOT NULL,
    timezone character varying(40) NOT NULL
);

COMMENT ON TABLE directory.datasource IS
'Describes datasources. A datasource is used to indicate where data came from. '
'Datasources are also used to prevent collisions between sets of data from '
'different sources, where names can be the same, but the meaning of the data '
'differs.';

ALTER TABLE directory.datasource OWNER TO minerva_admin;

CREATE SEQUENCE directory.datasource_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE directory.datasource_id_seq OWNER TO minerva_admin;

ALTER SEQUENCE directory.datasource_id_seq OWNED BY directory.datasource.id;

ALTER TABLE directory.datasource ALTER COLUMN id SET DEFAULT nextval('directory.datasource_id_seq'::regclass);

ALTER TABLE ONLY directory.datasource
    ADD CONSTRAINT datasource_pkey PRIMARY KEY (id);

GRANT SELECT ON TABLE directory.datasource TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.datasource TO minerva_writer;

GRANT SELECT ON SEQUENCE directory.datasource_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE directory.datasource_id_seq TO minerva_writer;

CREATE UNIQUE INDEX ix_directory_datasource_name ON directory.datasource USING btree (name);

-- Table 'entitytype'

CREATE TABLE directory.entitytype (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying NOT NULL
);

COMMENT ON TABLE directory.entitytype IS
'Stores the entity types that exist in the entity table. Entity types are '
'also used to give context to data that is stored for entities.';

ALTER TABLE directory.entitytype OWNER TO minerva_admin;

CREATE SEQUENCE directory.entitytype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE directory.entitytype_id_seq OWNER TO minerva_admin;
ALTER SEQUENCE directory.entitytype_id_seq OWNED BY directory.entitytype.id;
ALTER TABLE directory.entitytype
    ALTER COLUMN id
    SET DEFAULT nextval('directory.entitytype_id_seq'::regclass);

ALTER TABLE ONLY directory.entitytype
    ADD CONSTRAINT entitytype_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX ix_directory_entitytype_name
    ON directory.entitytype (lower(name));

GRANT SELECT ON TABLE directory.entitytype TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.entitytype TO minerva_writer;

GRANT SELECT ON SEQUENCE directory.entitytype_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE directory.entitytype_id_seq TO minerva_writer;

-- Table 'directory.entity'

CREATE TABLE directory.entity (
    id integer NOT NULL,
    first_appearance timestamp with time zone NOT NULL,
    name character varying NOT NULL,
    entitytype_id integer NOT NULL,
    dn character varying NOT NULL,
    parent_id integer
);

COMMENT ON TABLE directory.entity IS
'Describes entities. An entity is the base object for which the database can '
'hold further information such as attributes, trends and notifications. All '
'data must have a reference to an entity.';

ALTER TABLE directory.entity OWNER TO minerva_admin;

CREATE SEQUENCE directory.entity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE directory.entity_id_seq OWNER TO minerva_admin;

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
    ADD CONSTRAINT entity_entitytype_id_fkey
    FOREIGN KEY (entitytype_id) REFERENCES directory.entitytype(id)
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
CREATE INDEX ix_directory_entity_entitytype_id ON directory.entity USING btree (entitytype_id);

-- Table 'directory.taggroup'

CREATE TABLE directory.taggroup (
    id integer NOT NULL,
    name character varying NOT NULL,
    complementary boolean NOT NULL
);

CREATE UNIQUE INDEX ix_directory_taggroup_name on directory.taggroup (lower(name));

ALTER TABLE directory.taggroup OWNER TO minerva_admin;

CREATE SEQUENCE directory.taggroup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE directory.taggroup_id_seq OWNER TO minerva_admin;

ALTER TABLE directory.taggroup
    ALTER COLUMN id
    SET DEFAULT nextval('directory.taggroup_id_seq'::regclass);

ALTER SEQUENCE directory.taggroup_id_seq OWNED BY directory.taggroup.id;

ALTER TABLE ONLY directory.taggroup
    ADD CONSTRAINT taggroup_pkey PRIMARY KEY (id);

GRANT SELECT ON TABLE directory.taggroup TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.taggroup TO minerva_writer;

GRANT SELECT ON SEQUENCE directory.taggroup_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE directory.taggroup_id_seq TO minerva_writer;

INSERT INTO directory.taggroup (name, complementary) VALUES ('default', false);
INSERT INTO directory.taggroup (name, complementary) VALUES ('entitytype', true);

-- Table 'directory.tag'

CREATE TABLE directory.tag (
    id integer NOT NULL,
    name character varying NOT NULL,
    taggroup_id integer NOT NULL,
    description character varying
);

COMMENT ON TABLE directory.tag IS
'Stores all tags. A tag is a simple label that can be attached to a number of '
'object types in the database, such as entities and trends.';

CREATE UNIQUE INDEX ix_directory_tag_name
    ON directory.tag (lower(name));

CREATE INDEX ON directory.tag (lower(name), id);

ALTER TABLE directory.tag OWNER TO minerva_admin;

CREATE SEQUENCE directory.tag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE directory.tag_id_seq OWNER TO minerva_admin;

ALTER TABLE directory.tag
    ALTER COLUMN id
    SET DEFAULT nextval('directory.tag_id_seq'::regclass);

ALTER SEQUENCE directory.tag_id_seq OWNED BY directory.tag.id;

ALTER TABLE ONLY directory.tag
    ADD CONSTRAINT tag_pkey PRIMARY KEY (id);

ALTER TABLE ONLY directory.tag
    ADD CONSTRAINT tag_taggroup_id_fkey
    FOREIGN KEY (taggroup_id) REFERENCES directory.taggroup(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE directory.tag TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.tag TO minerva_writer;

GRANT SELECT ON SEQUENCE directory.tag_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE directory.tag_id_seq TO minerva_writer;

-- Table 'directory.entitytaglink'

CREATE TABLE directory.entitytaglink (
    tag_id integer NOT NULL,
    entity_id integer NOT NULL
);

ALTER TABLE directory.entitytaglink OWNER TO minerva_admin;

ALTER TABLE ONLY directory.entitytaglink
    ADD CONSTRAINT entitytaglink_pkey PRIMARY KEY (tag_id, entity_id);

GRANT SELECT ON TABLE directory.entitytaglink TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.entitytaglink TO minerva_writer;

ALTER TABLE ONLY directory.entitytaglink
    ADD CONSTRAINT entitytaglink_entity_id_fkey
    FOREIGN KEY (entity_id) REFERENCES directory.entity(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY directory.entitytaglink
    ADD CONSTRAINT entitytaglink_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES directory.tag(id)
    ON DELETE CASCADE;

CREATE INDEX ix_directory_entitytaglink_entity_id
    ON directory.entitytaglink USING btree (entity_id);

-- Table 'directory.entity_link_denorm'

CREATE TABLE directory.entity_link_denorm (
    entity_id integer primary key not null,
    tags text[] not null,
    name text not null
);

ALTER TABLE directory.entity_link_denorm OWNER TO minerva_admin;

CREATE INDEX ON directory.entity_link_denorm USING gin (tags);
CREATE INDEX ON directory.entity_link_denorm (name);

GRANT SELECT ON TABLE directory.entity_link_denorm TO minerva;
GRANT UPDATE, INSERT, DELETE ON TABLE directory.entity_link_denorm TO minerva_writer;


-- Table 'directory.aliastype'

CREATE TABLE directory.aliastype
(
    id integer NOT NULL,
    "name" character varying NOT NULL
);

ALTER TABLE directory.aliastype OWNER TO minerva_admin;

CREATE SEQUENCE directory.aliastype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE directory.aliastype_id_seq OWNER TO minerva_admin;
ALTER SEQUENCE directory.aliastype_id_seq OWNED BY directory.aliastype.id;
ALTER TABLE directory.aliastype
    ALTER COLUMN id
    SET DEFAULT nextval('directory.aliastype_id_seq'::regclass);

GRANT SELECT ON SEQUENCE directory.aliastype_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE directory.aliastype_id_seq TO minerva_writer;

ALTER TABLE ONLY directory.aliastype
    ADD CONSTRAINT aliastype_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX ix_directory_aliastype_name
    ON directory.aliastype (lower(name));

GRANT SELECT ON TABLE directory.aliastype TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.aliastype TO minerva_writer;

INSERT INTO directory.aliastype (name) VALUES ('name');

-- Table 'directory.alias'

CREATE TABLE directory.alias
(
    entity_id integer NOT NULL,
    "name" character varying NOT NULL,
    type_id integer NOT NULL
);

ALTER TABLE directory.alias OWNER TO minerva_admin;

ALTER TABLE ONLY directory.alias
    ADD CONSTRAINT alias_pkey PRIMARY KEY (entity_id, type_id);

ALTER TABLE ONLY directory.alias
    ADD CONSTRAINT alias_entity_id_fkey
    FOREIGN KEY (entity_id) REFERENCES directory.entity(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY directory.alias
    ADD CONSTRAINT alias_aliastype_id_fkey
    FOREIGN KEY (type_id) REFERENCES directory.aliastype(id)
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
    entitytype_id integer NOT NULL
);

ALTER TABLE directory.existence OWNER TO minerva_admin;

ALTER TABLE ONLY directory.existence
    ADD CONSTRAINT existence_pkey PRIMARY KEY (entity_id, timestamp);

ALTER TABLE ONLY directory.existence
    ADD CONSTRAINT existence_entity_id_fkey
    FOREIGN KEY (entity_id) REFERENCES directory.entity(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY directory.existence
    ADD CONSTRAINT existence_entitytype_id_fkey
    FOREIGN KEY (entitytype_id) REFERENCES directory.entitytype(id);

CREATE INDEX ix_directory_existence_timestamp
    ON directory.existence USING btree (timestamp);

GRANT SELECT ON TABLE directory.existence TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.existence TO minerva_writer;


-- View 'directory.existence_curr'

CREATE VIEW directory.existence_curr AS
SELECT
    entity_id,
    entitytype_id,
    public.first("timestamp" ORDER BY "timestamp" DESC) AS "timestamp",
    public.first("exists" ORDER BY "timestamp" DESC) AS "exists"
FROM directory.existence GROUP BY entity_id, entitytype_id;


-- Table 'directory.existence_staging'

CREATE UNLOGGED TABLE directory.existence_staging
(
    dn character varying NOT NULL UNIQUE
);

ALTER TABLE directory.existence_staging OWNER TO minerva_admin;

GRANT SELECT ON TABLE directory.existence_staging TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.existence_staging TO minerva_writer;


CREATE VIEW directory.existence_staging_entitytype_ids AS
SELECT entity.entitytype_id
FROM directory.existence_staging JOIN directory.entity
ON entity.dn = existence_staging.dn
GROUP BY entitytype_id;

GRANT SELECT ON TABLE directory.existence_staging_entitytype_ids TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.existence_staging_entitytype_ids TO minerva_writer;
