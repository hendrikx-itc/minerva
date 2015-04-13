-- Table 'type'

CREATE TABLE entity_tag.type (
	id serial,
	name name UNIQUE,
	taggroup_id integer REFERENCES directory.taggroup(id) ON DELETE CASCADE
);

ALTER TABLE entity_tag.type OWNER TO minerva_admin;


-- Table 'entitytaglink_staging'

CREATE UNLOGGED TABLE entity_tag.entitytaglink_staging (
    entity_id integer NOT NULL,
    tag_name text NOT NULL,
    taggroup_id integer NOT NULL
);

ALTER TABLE entity_tag.entitytaglink_staging OWNER TO minerva_admin;

GRANT SELECT ON TABLE entity_tag.entitytaglink_staging TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE entity_tag.entitytaglink_staging TO minerva_writer;
