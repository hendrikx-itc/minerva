SET client_encoding = 'UTF8';

CREATE SCHEMA materialization;
ALTER SCHEMA materialization OWNER TO minerva_admin;

GRANT ALL ON SCHEMA materialization TO minerva_writer;
GRANT USAGE ON SCHEMA materialization TO minerva;

-- Table 'type'

CREATE TABLE materialization.type (
    id serial NOT NULL,
    src_trendstore_id integer NOT NULL,
    dst_trendstore_id integer NOT NULL,
    processing_delay interval NOT NULL,
    stability_delay interval NOT NULL,
    reprocessing_period interval NOT NULL,
    enabled boolean NOT NULL DEFAULT FALSE,
    cost integer NOT NULL DEFAULT 10,
    partials integer NOT NULL DEFAULT 1 CHECK (partials > 0)
);

COMMENT ON COLUMN materialization.type.src_trendstore_id IS
'The unique identifier of this materialization type';
COMMENT ON COLUMN materialization.type.src_trendstore_id IS
'The Id of the source trendstore, which should be the Id of a view based trendstore';
COMMENT ON COLUMN materialization.type.dst_trendstore_id IS
'The Id of the destination trendstore, which should be the Id of a table based trendstore';
COMMENT ON COLUMN materialization.type.processing_delay IS
'The time after the destination timestamp before this materialization can be executed';
COMMENT ON COLUMN materialization.type.stability_delay IS
'The time to wait after the most recent modified timestamp before the source data is considered ''stable''';
COMMENT ON COLUMN materialization.type.reprocessing_period IS
'The maximum time after the destination timestamp that the materialization is allowed to be executed';
COMMENT ON COLUMN materialization.type.enabled IS
'Indicates if jobs should be created for this materialization (manual execution is always possible)';
COMMENT ON COLUMN materialization.type.partials IS
'Materialization is divided into this amount of partial materialization jobs';

ALTER TABLE materialization.type OWNER TO minerva_admin;

ALTER TABLE ONLY materialization.type
    ADD CONSTRAINT type_pkey PRIMARY KEY (id);

GRANT ALL ON TABLE materialization.type TO minerva_admin;
GRANT SELECT ON TABLE materialization.type TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE materialization.type TO minerva_writer;

ALTER TABLE ONLY materialization.type
    ADD CONSTRAINT materialization_type_src_trendstore_id_fkey
    FOREIGN KEY (src_trendstore_id) REFERENCES trend.trendstore(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY materialization.type
    ADD CONSTRAINT materialization_type_dst_trendstore_id_fkey
    FOREIGN KEY (dst_trendstore_id) REFERENCES trend.trendstore(id)
    ON DELETE CASCADE;

CREATE UNIQUE INDEX ix_materialization_type_uniqueness
    ON materialization.type (src_trendstore_id, dst_trendstore_id);


-- Table 'type_tag_link'

CREATE TABLE materialization.type_tag_link (
    type_id integer NOT NULL,
    tag_id integer NOT NULL
);

ALTER TABLE materialization.type_tag_link OWNER TO minerva_admin;

ALTER TABLE ONLY materialization.type_tag_link
    ADD CONSTRAINT type_tag_link_pkey PRIMARY KEY (type_id, tag_id);

ALTER TABLE ONLY materialization.type_tag_link
    ADD CONSTRAINT type_tag_link_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES directory.tag(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY materialization.type_tag_link
    ADD CONSTRAINT type_tag_link_type_id_fkey FOREIGN KEY (type_id) REFERENCES materialization.type(id)
    ON DELETE CASCADE;

GRANT ALL ON TABLE materialization.type_tag_link TO minerva_admin;
GRANT SELECT ON TABLE materialization.type_tag_link TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE materialization.type_tag_link TO minerva_writer;


-- Table 'group_priority'

CREATE TABLE materialization.group_priority (
    tag_id integer references directory.tag(id) PRIMARY KEY,
    resources integer not null default 500
);

ALTER TABLE materialization.group_priority OWNER TO minerva_admin;

GRANT ALL ON TABLE materialization.group_priority TO minerva_admin;
GRANT SELECT ON TABLE materialization.group_priority TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE materialization.group_priority TO minerva_writer;


-- Type 'fragment'

CREATE TYPE materialization.fragment AS (
    type materialization.type,
    timestamp timestamp with time zone
);


-- Table 'state_fingerprint'

CREATE TABLE materialization.state_fingerprint (
    type_id integer NOT NULL REFERENCES materialization.type(id) ON DELETE CASCADE,
    timestamp timestamp with time zone NOT NULL,
    fingerprint text,
    modified timestamp with time zone,
    processed_fingerprint text DEFAULT NULL,
    partial_fingerprint text DEFAULT NULL,
    partials_processed integer NOT NULL DEFAULT 0 CHECK (partials_processed >= 0),
    job_id integer DEFAULT NULL,
    PRIMARY KEY (type_id, timestamp)
);

COMMENT ON COLUMN materialization.state_fingerprint.type_id IS
'The Id of the materialization type';
COMMENT ON COLUMN materialization.state_fingerprint.timestamp IS
'The timestamp of the materialized (materialization result) data';
COMMENT ON COLUMN materialization.state_fingerprint.job_id IS
'Id of the most recent job for this materialization';

ALTER TABLE materialization.state_fingerprint OWNER TO minerva_admin;

GRANT ALL ON TABLE materialization.state_fingerprint TO minerva_admin;
GRANT SELECT ON TABLE materialization.state_fingerprint TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE materialization.state_fingerprint TO minerva_writer;


-- Table 'state_fingerprint_staging'

CREATE UNLOGGED TABLE materialization.state_fingerprint_staging (
    type_id integer NOT NULL,
    timestamp timestamp with time zone NOT NULL,
    fingerprint text,
    modified timestamp with time zone
);

COMMENT ON COLUMN materialization.state_fingerprint_staging.type_id IS
'The Id of the materialization type';
COMMENT ON COLUMN materialization.state_fingerprint_staging.timestamp IS
'The timestamp of the materialized (materialization result) data';

ALTER TABLE materialization.state_fingerprint_staging OWNER TO minerva_admin;

GRANT ALL ON TABLE materialization.state_fingerprint_staging TO minerva_admin;
GRANT SELECT ON TABLE materialization.state_fingerprint_staging TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE materialization.state_fingerprint_staging TO minerva_writer;

-- Table 'type_trendstore_link'

CREATE TABLE materialization.type_trendstore_link (
    type_id integer NOT NULL REFERENCES materialization.type(id) ON DELETE CASCADE,
    trendstore_id integer NOT NULL REFERENCES trend.trendstore(id) ON DELETE CASCADE
);

COMMENT ON TABLE materialization.type_trendstore_link IS
'Stores relation between materialization types and their source (table)
trendstores.';

ALTER TABLE materialization.type_trendstore_link OWNER TO minerva_admin;

ALTER TABLE ONLY materialization.type_trendstore_link
    ADD CONSTRAINT type_trendstore_link_pkey PRIMARY KEY (type_id, trendstore_id);

GRANT ALL ON TABLE materialization.type_trendstore_link TO minerva_admin;
GRANT SELECT ON TABLE materialization.type_trendstore_link TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE materialization.type_trendstore_link TO minerva_writer;

