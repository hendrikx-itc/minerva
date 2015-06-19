SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

CREATE SCHEMA materialization;
ALTER SCHEMA materialization OWNER TO minerva_admin;

GRANT ALL ON SCHEMA materialization TO minerva_writer;
GRANT USAGE ON SCHEMA materialization TO minerva;

SET search_path = materialization, pg_catalog;


-- Table 'type'

CREATE TABLE type (
	id serial NOT NULL,
	src_trendstore_id integer NOT NULL,
	dst_trendstore_id integer NOT NULL,
	processing_delay interval NOT NULL,
	stability_delay interval NOT NULL,
	reprocessing_period interval NOT NULL,
	enabled boolean NOT NULL DEFAULT FALSE,
    cost integer NOT NULL DEFAULT 10
);

COMMENT ON COLUMN type.src_trendstore_id IS
'The unique identifier of this materialization type';
COMMENT ON COLUMN type.src_trendstore_id IS
'The Id of the source trendstore, which should be the Id of a view based trendstore';
COMMENT ON COLUMN type.dst_trendstore_id IS
'The Id of the destination trendstore, which should be the Id of a table based trendstore';
COMMENT ON COLUMN type.processing_delay IS
'The time after the destination timestamp before this materialization can be executed';
COMMENT ON COLUMN type.stability_delay IS
'The time to wait after the most recent modified timestamp before the source data is considered ''stable''';
COMMENT ON COLUMN type.reprocessing_period IS
'The maximum time after the destination timestamp that the materialization is allowed to be executed';
COMMENT ON COLUMN type.enabled IS
'Indicates if jobs should be created for this materialization (manual execution is always possible)';

ALTER TABLE type OWNER TO minerva_admin;

ALTER TABLE ONLY type
	ADD CONSTRAINT type_pkey PRIMARY KEY (id);

GRANT ALL ON TABLE type TO minerva_admin;
GRANT SELECT ON TABLE type TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE type TO minerva_writer;

ALTER TABLE ONLY type
	ADD CONSTRAINT materialization_type_src_trendstore_id_fkey
	FOREIGN KEY (src_trendstore_id) REFERENCES trend.trendstore(id)
	ON DELETE CASCADE;

ALTER TABLE ONLY type
	ADD CONSTRAINT materialization_type_dst_trendstore_id_fkey
	FOREIGN KEY (dst_trendstore_id) REFERENCES trend.trendstore(id)
	ON DELETE CASCADE;

CREATE UNIQUE INDEX ix_materialization_type_uniqueness
	ON type (src_trendstore_id, dst_trendstore_id);


-- table state

CREATE TYPE source_fragment AS (
	trendstore_id integer,
	timestamp timestamp with time zone
);


CREATE TYPE source_fragment_state AS (
	fragment source_fragment,
	modified timestamp with time zone
);

COMMENT ON TYPE source_fragment_state IS 'Used to store the max modified of a specific source_fragment.';


CREATE TABLE state (
	type_id integer NOT NULL,
	timestamp timestamp with time zone NOT NULL,
	max_modified timestamp with time zone NOT NULL,
	source_states source_fragment_state[] DEFAULT NULL,
	processed_states source_fragment_state[] DEFAULT NULL,
	job_id integer DEFAULT NULL
);

COMMENT ON COLUMN state.type_id IS
'The Id of the materialization type';
COMMENT ON COLUMN state.timestamp IS
'The timestamp of the materialized (materialization result) data';
COMMENT ON COLUMN state.max_modified IS
'The greatest modified timestamp of all materialization sources';
COMMENT ON COLUMN state.source_states IS
'Array of trendstore_id/timestamp/modified combinations for all source data fragments';
COMMENT ON COLUMN state.processed_states IS
'Array containing a snapshot of the source_states at the time of the most recent materialization';
COMMENT ON COLUMN state.job_id IS
'Id of the most recent job for this materialization';

ALTER TABLE state OWNER TO minerva_admin;

ALTER TABLE ONLY state
	ADD CONSTRAINT state_pkey PRIMARY KEY (type_id, timestamp);

ALTER TABLE ONLY state
	ADD CONSTRAINT materialization_state_type_id_fkey
	FOREIGN KEY (type_id) REFERENCES materialization.type(id)
	ON DELETE CASCADE;

GRANT ALL ON TABLE state TO minerva_admin;
GRANT SELECT ON TABLE state TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE state TO minerva_writer;


-- Table 'type_tag_link'

CREATE TABLE type_tag_link (
    type_id integer NOT NULL,
    tag_id integer NOT NULL
);

ALTER TABLE type_tag_link OWNER TO minerva_admin;

ALTER TABLE ONLY type_tag_link
    ADD CONSTRAINT type_tag_link_pkey PRIMARY KEY (type_id, tag_id);

ALTER TABLE ONLY type_tag_link
    ADD CONSTRAINT type_tag_link_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES directory.tag(id)
	ON DELETE CASCADE;

ALTER TABLE ONLY type_tag_link
	ADD CONSTRAINT type_tag_link_type_id_fkey FOREIGN KEY (type_id) REFERENCES type(id)
	ON DELETE CASCADE;

GRANT ALL ON TABLE type_tag_link TO minerva_admin;
GRANT SELECT ON TABLE type_tag_link TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE type_tag_link TO minerva_writer;


-- Table 'group_priority'

CREATE TABLE group_priority (
    tag_id integer references directory.tag(id) PRIMARY KEY,
    resources integer not null default 500
);

ALTER TABLE group_priority OWNER TO minerva_admin;

GRANT ALL ON TABLE group_priority TO minerva_admin;
GRANT SELECT ON TABLE group_priority TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE group_priority TO minerva_writer;
