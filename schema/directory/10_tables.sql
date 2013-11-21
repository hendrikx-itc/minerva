SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

CREATE SCHEMA directory;
ALTER SCHEMA directory OWNER TO minerva_admin;

GRANT ALL ON SCHEMA directory TO minerva_admin;
GRANT USAGE ON SCHEMA directory TO minerva;

SET search_path = directory, pg_catalog;

-- Table 'datasource'

CREATE TABLE datasource (
	id integer NOT NULL,
	name character varying(100) NOT NULL,
	description character varying NOT NULL,
	timezone character varying(40) NOT NULL
);

ALTER TABLE directory.datasource OWNER TO minerva_admin;

CREATE SEQUENCE datasource_id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;

ALTER TABLE directory.datasource_id_seq OWNER TO minerva_admin;

ALTER SEQUENCE datasource_id_seq OWNED BY datasource.id;

ALTER TABLE datasource ALTER COLUMN id SET DEFAULT nextval('datasource_id_seq'::regclass);

ALTER TABLE ONLY datasource
	ADD CONSTRAINT datasource_pkey PRIMARY KEY (id);

GRANT ALL ON TABLE datasource TO minerva_admin;
GRANT SELECT ON TABLE datasource TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE datasource TO minerva_writer;

GRANT ALL ON SEQUENCE datasource_id_seq TO minerva_admin;
GRANT SELECT ON SEQUENCE datasource_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE datasource_id_seq TO minerva_writer;

CREATE UNIQUE INDEX ix_directory_datasource_name ON datasource USING btree (name);

-- Table 'entitytype'

CREATE TABLE entitytype (
	id integer NOT NULL,
	name character varying(50) NOT NULL,
	description character varying NOT NULL
);

ALTER TABLE directory.entitytype OWNER TO minerva_admin;

CREATE SEQUENCE entitytype_id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;

ALTER TABLE directory.entitytype_id_seq OWNER TO minerva_admin;
ALTER SEQUENCE entitytype_id_seq OWNED BY entitytype.id;
ALTER TABLE entitytype
	ALTER COLUMN id
	SET DEFAULT nextval('entitytype_id_seq'::regclass);

ALTER TABLE ONLY entitytype
	ADD CONSTRAINT entitytype_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX ix_directory_entitytype_name
	ON entitytype (lower(name));

GRANT ALL ON TABLE entitytype TO minerva_admin;
GRANT SELECT ON TABLE entitytype TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE entitytype TO minerva_writer;

GRANT ALL ON SEQUENCE entitytype_id_seq TO minerva_admin;
GRANT SELECT ON SEQUENCE entitytype_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE entitytype_id_seq TO minerva_writer;

-- Table 'entity'

CREATE TABLE entity (
	id integer NOT NULL,
	first_appearance timestamp with time zone NOT NULL,
	name character varying NOT NULL,
	entitytype_id integer NOT NULL,
	dn character varying NOT NULL,
	parent_id integer
);

ALTER TABLE directory.entity OWNER TO minerva_admin;

CREATE SEQUENCE entity_id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;

ALTER TABLE directory.entity_id_seq OWNER TO minerva_admin;

ALTER SEQUENCE entity_id_seq OWNED BY entity.id;

ALTER TABLE entity
	ALTER COLUMN id
	SET DEFAULT nextval('entity_id_seq'::regclass);

ALTER TABLE ONLY entity
	ADD CONSTRAINT entity_pkey PRIMARY KEY (id);

GRANT ALL ON TABLE entity TO minerva_admin;
GRANT SELECT ON TABLE entity TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE entity TO minerva_writer;

GRANT ALL ON SEQUENCE entity_id_seq TO minerva_admin;
GRANT SELECT ON SEQUENCE entity_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE entity_id_seq TO minerva_writer;

ALTER TABLE ONLY entity
	ADD CONSTRAINT entity_entitytype_id_fkey
	FOREIGN KEY (entitytype_id) REFERENCES entitytype(id)
	ON DELETE CASCADE;

ALTER TABLE ONLY entity
	ADD CONSTRAINT entity_parent_id_fkey
	FOREIGN KEY (parent_id) REFERENCES entity(id)
	ON DELETE CASCADE;

CREATE UNIQUE INDEX ix_directory_entity_dn
	ON entity USING btree (dn);

CREATE INDEX ix_directory_entity_name
	ON entity USING btree (name);

CREATE INDEX parent_id ON entity USING btree (parent_id);
CREATE INDEX ix_directory_entity_entitytype_id ON entity USING btree (entitytype_id);

-- Table 'taggroup'

CREATE TABLE taggroup (
	id integer NOT NULL,
	name character varying NOT NULL,
	complementary boolean NOT NULL
);

CREATE UNIQUE INDEX ix_directory_taggroup_name on taggroup (lower(name));

ALTER TABLE directory.taggroup OWNER TO minerva_admin;

CREATE SEQUENCE taggroup_id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;

ALTER TABLE directory.taggroup_id_seq OWNER TO minerva_admin;

ALTER TABLE taggroup
	ALTER COLUMN id
	SET DEFAULT nextval('taggroup_id_seq'::regclass);

ALTER SEQUENCE taggroup_id_seq OWNED BY taggroup.id;

ALTER TABLE ONLY taggroup
	ADD CONSTRAINT taggroup_pkey PRIMARY KEY (id);

GRANT ALL ON TABLE taggroup TO minerva_admin;
GRANT SELECT ON TABLE taggroup TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE taggroup TO minerva_writer;

GRANT ALL ON SEQUENCE taggroup_id_seq TO minerva_admin;
GRANT SELECT ON SEQUENCE taggroup_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE taggroup_id_seq TO minerva_writer;

INSERT INTO taggroup (name, complementary) VALUES ('default', false);
INSERT INTO taggroup (name, complementary) VALUES ('entitytype', true);

-- Table 'tag'

CREATE TABLE tag (
	id integer NOT NULL,
	name character varying NOT NULL,
	taggroup_id integer NOT NULL,
	description character varying
);

CREATE UNIQUE INDEX ix_directory_tag_name
	ON tag (lower(name));

CREATE INDEX ON tag (lower(name), id);

ALTER TABLE directory.tag OWNER TO minerva_admin;

CREATE SEQUENCE tag_id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;

ALTER TABLE directory.tag_id_seq OWNER TO minerva_admin;

ALTER TABLE tag
	ALTER COLUMN id
	SET DEFAULT nextval('tag_id_seq'::regclass);

ALTER SEQUENCE tag_id_seq OWNED BY tag.id;

ALTER TABLE ONLY tag
	ADD CONSTRAINT tag_pkey PRIMARY KEY (id);

ALTER TABLE ONLY tag
	ADD CONSTRAINT tag_taggroup_id_fkey
	FOREIGN KEY (taggroup_id) REFERENCES taggroup(id)
	ON DELETE CASCADE;

GRANT ALL ON TABLE tag TO minerva_admin;
GRANT SELECT ON TABLE tag TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE tag TO minerva_writer;

GRANT ALL ON SEQUENCE tag_id_seq TO minerva_admin;
GRANT SELECT ON SEQUENCE tag_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE tag_id_seq TO minerva_writer;

-- Table 'entitytaglink'

CREATE TABLE entitytaglink (
	tag_id integer NOT NULL,
	entity_id integer NOT NULL
);

ALTER TABLE directory.entitytaglink OWNER TO minerva_admin;

ALTER TABLE ONLY entitytaglink
	ADD CONSTRAINT entitytaglink_pkey PRIMARY KEY (tag_id, entity_id);

GRANT ALL ON TABLE entitytaglink TO minerva_admin;
GRANT SELECT ON TABLE entitytaglink TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE entitytaglink TO minerva_writer;

ALTER TABLE ONLY entitytaglink
	ADD CONSTRAINT entitytaglink_entity_id_fkey
	FOREIGN KEY (entity_id) REFERENCES entity(id)
	ON DELETE CASCADE;

ALTER TABLE ONLY entitytaglink
	ADD CONSTRAINT entitytaglink_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES tag(id)
	ON DELETE CASCADE;

CREATE INDEX ix_directory_entitytaglink_entity_id
	ON entitytaglink USING btree (entity_id);

-- Table 'entitytags'

CREATE TABLE entitytags (
	entity_id integer NOT NULL,
	tag_ids integer[] NOT NULL
);

ALTER TABLE directory.entitytags OWNER TO minerva_admin;

ALTER TABLE ONLY entitytags
	ADD CONSTRAINT entitytags_pkey PRIMARY KEY (entity_id);

CREATE INDEX ix_directory_entitytags_tag_ids
	ON entitytags USING gin(tag_ids);

GRANT ALL ON TABLE entitytags TO minerva_admin;
GRANT SELECT ON TABLE entitytags TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE entitytags TO minerva_writer;

ALTER TABLE ONLY entitytags
	ADD CONSTRAINT entitytags_entity_id_fkey
	FOREIGN KEY (entity_id) REFERENCES entity(id)
	ON DELETE CASCADE;

-- Table 'aliastype'

CREATE TABLE aliastype
(
	id integer NOT NULL,
	"name" character varying NOT NULL
);

ALTER TABLE aliastype OWNER TO minerva_admin;

CREATE SEQUENCE aliastype_id_seq
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;

ALTER TABLE directory.aliastype_id_seq OWNER TO minerva_admin;
ALTER SEQUENCE aliastype_id_seq OWNED BY aliastype.id;
ALTER TABLE aliastype
	ALTER COLUMN id
	SET DEFAULT nextval('aliastype_id_seq'::regclass);

GRANT ALL ON SEQUENCE aliastype_id_seq TO minerva_admin;
GRANT SELECT ON SEQUENCE aliastype_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE aliastype_id_seq TO minerva_writer;

ALTER TABLE ONLY aliastype
	ADD CONSTRAINT aliastype_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX ix_directory_aliastype_name
	ON aliastype (lower(name));

GRANT ALL ON TABLE aliastype TO minerva_admin;
GRANT SELECT ON TABLE aliastype TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE aliastype TO minerva_writer;

INSERT INTO aliastype (name) VALUES ('name');

-- Table 'alias'

CREATE TABLE alias
(
	entity_id integer NOT NULL,
	"name" character varying NOT NULL,
	type_id integer NOT NULL
);

ALTER TABLE alias OWNER TO minerva_admin;

ALTER TABLE ONLY alias
	ADD CONSTRAINT alias_pkey PRIMARY KEY (entity_id, type_id);

ALTER TABLE ONLY alias
	ADD CONSTRAINT alias_entity_id_fkey
	FOREIGN KEY (entity_id) REFERENCES entity(id)
	ON DELETE CASCADE;

ALTER TABLE ONLY alias
	ADD CONSTRAINT alias_aliastype_id_fkey
	FOREIGN KEY (type_id) REFERENCES aliastype(id)
	ON DELETE CASCADE;

CREATE INDEX ix_directory_alias_name ON alias USING btree (name);

GRANT ALL ON TABLE alias TO minerva_admin;
GRANT SELECT ON TABLE alias TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE alias TO minerva_writer;

-- Table 'existence'

CREATE TABLE existence
(
	timestamp timestamp with time zone NOT NULL,
	exists boolean NOT NULL,
	entity_id integer NOT NULL,
	entitytype_id integer NOT NULL
);

ALTER TABLE existence OWNER TO minerva_admin;

ALTER TABLE ONLY existence
	ADD CONSTRAINT existence_pkey PRIMARY KEY (entity_id, timestamp);

ALTER TABLE ONLY existence
	ADD CONSTRAINT existence_entity_id_fkey
	FOREIGN KEY (entity_id) REFERENCES entity(id)
	ON DELETE CASCADE;

ALTER TABLE ONLY existence
	ADD CONSTRAINT existence_entitytype_id_fkey
	FOREIGN KEY (entitytype_id) REFERENCES entitytype(id);

CREATE INDEX ix_directory_existence_timestamp
	ON existence USING btree (timestamp);

GRANT ALL ON TABLE existence TO minerva_admin;
GRANT SELECT ON TABLE existence TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE existence TO minerva_writer;

-- Table 'existence_curr'

CREATE TABLE existence_curr (
) INHERITS (existence);

ALTER TABLE existence_curr OWNER TO minerva_admin;

ALTER TABLE ONLY existence_curr
	ADD CONSTRAINT existence_curr_pkey PRIMARY KEY (entity_id);

GRANT ALL ON TABLE existence_curr TO minerva_admin;
GRANT SELECT ON TABLE existence_curr TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE existence_curr TO minerva_writer;
