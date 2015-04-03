CREATE SCHEMA materialization;

GRANT ALL ON SCHEMA materialization TO minerva_writer;
GRANT USAGE ON SCHEMA materialization TO minerva;


-- Table 'type'

CREATE TABLE materialization.type (
    id serial NOT NULL,
    view_trend_store_id integer NOT NULL REFERENCES trend_directory.view_trend_store(id) ON DELETE CASCADE,
    table_trend_store_id integer NOT NULL REFERENCES trend_directory.table_trend_store(id) ON DELETE CASCADE,
    processing_delay interval NOT NULL,
    stability_delay interval NOT NULL,
    reprocessing_period interval NOT NULL,
    enabled boolean NOT NULL DEFAULT FALSE,
    cost integer NOT NULL DEFAULT 10
);

COMMENT ON COLUMN materialization.type.id IS
'The unique identifier of this materialization type';
COMMENT ON COLUMN materialization.type.view_trend_store_id IS
'The Id of the source trend_store, which should be the Id of a view based trend_store';
COMMENT ON COLUMN materialization.type.table_trend_store_id IS
'The Id of the destination trend_store, which should be the Id of a table based trend_store';
COMMENT ON COLUMN materialization.type.processing_delay IS
'The time after the destination timestamp before this materialization can be executed';
COMMENT ON COLUMN materialization.type.stability_delay IS
'The time to wait after the most recent modified timestamp before the source data is considered ''stable''';
COMMENT ON COLUMN materialization.type.reprocessing_period IS
'The maximum time after the destination timestamp that the materialization is allowed to be executed';
COMMENT ON COLUMN materialization.type.enabled IS
'Indicates if jobs should be created for this materialization (manual execution is always possible)';

ALTER TABLE ONLY materialization.type
    ADD CONSTRAINT type_pkey PRIMARY KEY (id);

GRANT SELECT ON TABLE materialization.type TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE materialization.type TO minerva_writer;

CREATE UNIQUE INDEX ix_materialization_type_uniqueness
    ON materialization.type (view_trend_store_id, table_trend_store_id);


-- table state

CREATE TYPE materialization.source_fragment AS (
    trend_store_id integer,
    timestamp timestamp with time zone
);


CREATE TYPE materialization.source_fragment_state AS (
    fragment materialization.source_fragment,
    modified timestamp with time zone
);

COMMENT ON TYPE materialization.source_fragment_state IS
'Used to store the max modified of a specific source_fragment.';


CREATE TABLE materialization.state (
    type_id integer NOT NULL,
    timestamp timestamp with time zone NOT NULL,
    max_modified timestamp with time zone NOT NULL,
    source_states materialization.source_fragment_state[] DEFAULT NULL,
    processed_states materialization.source_fragment_state[] DEFAULT NULL,
    job_id integer DEFAULT NULL
);

COMMENT ON COLUMN materialization.state.type_id IS
'The Id of the materialization type';
COMMENT ON COLUMN materialization.state.timestamp IS
'The timestamp of the materialized (materialization result) data';
COMMENT ON COLUMN materialization.state.max_modified IS
'The greatest modified timestamp of all materialization sources';
COMMENT ON COLUMN materialization.state.source_states IS
'Array of trend_store_id/timestamp/modified combinations for all source data fragments';
COMMENT ON COLUMN materialization.state.processed_states IS
'Array containing a snapshot of the source_states at the time of the most recent materialization';
COMMENT ON COLUMN materialization.state.job_id IS
'Id of the most recent job for this materialization';

ALTER TABLE ONLY materialization.state
    ADD CONSTRAINT state_pkey PRIMARY KEY (type_id, timestamp);

ALTER TABLE ONLY materialization.state
    ADD CONSTRAINT materialization_state_type_id_fkey
    FOREIGN KEY (type_id) REFERENCES materialization.type(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE materialization.state TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE materialization.state TO minerva_writer;


-- Table 'type_tag_link'

CREATE TABLE materialization.type_tag_link (
    type_id integer NOT NULL,
    tag_id integer NOT NULL
);

ALTER TABLE ONLY materialization.type_tag_link
    ADD CONSTRAINT type_tag_link_pkey PRIMARY KEY (type_id, tag_id);

ALTER TABLE ONLY materialization.type_tag_link
    ADD CONSTRAINT type_tag_link_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES directory.tag(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY materialization.type_tag_link
    ADD CONSTRAINT type_tag_link_type_id_fkey FOREIGN KEY (type_id) REFERENCES materialization.type(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE materialization.type_tag_link TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE materialization.type_tag_link TO minerva_writer;


-- Table 'group_priority'

CREATE TABLE materialization.group_priority (
    tag_id integer references directory.tag(id) PRIMARY KEY,
    resources integer not null default 500
);

GRANT SELECT ON TABLE materialization.group_priority TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE materialization.group_priority TO minerva_writer;
