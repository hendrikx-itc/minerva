CREATE SCHEMA trend;

COMMENT ON SCHEMA trend IS
'Stores information with fixed interval and format, like periodic measurements.';

CREATE SCHEMA trend_partition;

COMMENT ON SCHEMA trend_partition IS
'Stores information with fixed interval and format, like periodic measurements.';

CREATE SCHEMA trend_directory;

COMMENT ON SCHEMA trend_directory IS
'Stores information with fixed interval and format, like periodic measurements.';

-- Type 'trend_directory.trend_descr'

CREATE TYPE trend_directory.trend_descr AS (
    name name,
    data_type text,
    description text
);


CREATE TYPE trend_directory.view_trend_store_part_descr AS (
    name name,
    query text
);

CREATE TYPE trend_directory.table_trend_store_part_descr AS (
    name name,
    trends trend_directory.trend_descr[]
);


-- Table 'trend_directory.trend_store'

CREATE TABLE trend_directory.trend_store (
    id serial PRIMARY KEY,
    entity_type_id integer REFERENCES directory.entity_type(id) ON DELETE CASCADE,
    data_source_id integer REFERENCES directory.data_source(id),
    granularity interval NOT NULL,
    UNIQUE (entity_type_id, data_source_id, granularity)
);

-- Table 'trend_directory.trend_store_part'

CREATE TABLE trend_directory.trend_store_part (
    id serial PRIMARY KEY,
    name name NOT NULL,
    trend_store_id integer NOT NULL
);

-- Table 'trend_directory.table_trend_store'

CREATE TABLE trend_directory.table_trend_store (
    partition_size integer NOT NULL,
    retention_period interval NOT NULL DEFAULT interval '1 month',
    PRIMARY KEY (id)
) INHERITS (trend_directory.trend_store);


CREATE TABLE trend_directory.table_trend_store_part (
    PRIMARY KEY (id),
    FOREIGN KEY (trend_store_id) REFERENCES trend_directory.table_trend_store(id)
) INHERITS (trend_directory.trend_store_part);

-- Table 'trend_directory.view_trend_store'

CREATE TABLE trend_directory.view_trend_store (
    PRIMARY KEY (id)
) INHERITS (trend_directory.trend_store);

CREATE TABLE trend_directory.view_trend_store_part (
    PRIMARY KEY (id),
    FOREIGN KEY (trend_store_id) REFERENCES trend_directory.view_trend_store(id)
) INHERITS (trend_directory.trend_store_part);

-- Table 'trend_directory.trend'

CREATE TABLE trend_directory.trend (
    id integer PRIMARY KEY,
    trend_store_part_id integer NOT NULL,
    name name NOT NULL,
    data_type text NOT NULL,
    description text NOT NULL
);

-- Table 'trend_directory.table_trend'

CREATE TABLE trend_directory.table_trend(
    PRIMARY KEY (id),
    FOREIGN KEY (trend_store_part_id) REFERENCES trend_directory.table_trend_store_part(id) ON DELETE CASCADE
) INHERITS (trend_directory.trend);

-- Table 'trend_directory.view_trend'

CREATE TABLE trend_directory.view_trend(
    PRIMARY KEY (id),
    FOREIGN KEY (trend_store_part_id) REFERENCES trend_directory.view_trend_store_part(id) ON DELETE CASCADE
) INHERITS (trend_directory.trend);

-- Table 'trend_directory.partition'

CREATE TABLE trend_directory.partition (
    table_trend_store_part_id integer REFERENCES trend_directory.table_trend_store_part(id) ON DELETE CASCADE,
    index integer,
    PRIMARY KEY (table_trend_store_part_id, index)
);

-- Table 'trend_directory.trend_tag_link'

CREATE TABLE trend_directory.trend_tag_link (
    trend_id integer NOT NULL REFERENCES trend_directory.trend(id) ON DELETE CASCADE,
    tag_id integer NOT NULL REFERENCES directory.tag(id) ON DELETE CASCADE,
    PRIMARY KEY (trend_id, tag_id)
);

-- Table 'trend_directory.modified'

CREATE TABLE trend_directory.modified (
    table_trend_store_id integer NOT NULL REFERENCES trend_directory.table_trend_store ON DELETE CASCADE,
    "timestamp" timestamp WITH time zone NOT NULL,
    start timestamp WITH time zone NOT NULL,
    "end" timestamp WITH time zone NOT NULL,
    PRIMARY KEY (table_trend_store_id, "timestamp")
);

GRANT SELECT ON TABLE trend_directory.modified TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend_directory.modified TO minerva_writer;


-- ###############
-- Materialization
-- ###############

-- Table 'materialization'

CREATE TABLE trend_directory.materialization (
    id serial NOT NULL,
    dst_trend_store_id integer NOT NULL REFERENCES trend_directory.table_trend_store(id) ON DELETE CASCADE,
    processing_delay interval NOT NULL,
    stability_delay interval NOT NULL,
    reprocessing_period interval NOT NULL,
    enabled boolean NOT NULL DEFAULT FALSE,
    cost integer NOT NULL DEFAULT 10
);

COMMENT ON COLUMN trend_directory.materialization.id IS
'The unique identifier of this materialization';
COMMENT ON COLUMN trend_directory.materialization.dst_trend_store_id IS
'The ID of the destination table_trend_store';
COMMENT ON COLUMN trend_directory.materialization.processing_delay IS
'The time after the destination timestamp before this materialization can be executed';
COMMENT ON COLUMN trend_directory.materialization.stability_delay IS
'The time to wait after the most recent modified timestamp before the source data is considered ''stable''';
COMMENT ON COLUMN trend_directory.materialization.reprocessing_period IS
'The maximum time after the destination timestamp that the materialization is allowed to be executed';
COMMENT ON COLUMN trend_directory.materialization.enabled IS
'Indicates if jobs should be created for this materialization (manual execution is always possible)';

ALTER TABLE ONLY trend_directory.materialization
    ADD CONSTRAINT materialization_pkey PRIMARY KEY (id);

GRANT SELECT ON TABLE trend_directory.materialization TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend_directory.materialization TO minerva_writer;

CREATE UNIQUE INDEX ix_trend_materialization_uniqueness
    ON trend_directory.materialization (dst_trend_store_id);

COMMENT ON INDEX trend_directory.ix_trend_materialization_uniqueness IS
'Only one materialization should populate a specific table trend store';


CREATE TABLE trend_directory.view_materialization (
    src_view regclass NOT NULL
) INHERITS (trend_directory.materialization);

COMMENT ON TABLE trend_directory.view_materialization IS
'A view_materialization is a materialization that uses the data from the view
registered in the src_view column to populate the target trend store.';


CREATE TABLE trend_directory.function_materialization (
    src_function regprocedure NOT NULL
) INHERITS (trend_directory.materialization);

COMMENT ON TABLE trend_directory.view_materialization IS
'A table_materialization is a materialization that uses the data from the function
registered in the src_function column to populate the target trend store.';


-- table state

CREATE TYPE trend_directory.source_fragment AS (
    trend_store_id integer,
    timestamp timestamp with time zone
);


CREATE TYPE trend_directory.source_fragment_state AS (
    fragment trend_directory.source_fragment,
    modified timestamp with time zone
);

COMMENT ON TYPE trend_directory.source_fragment_state IS
'Stores the max modified of a specific source_fragment.';


CREATE TABLE trend_directory.state (
    materialization_id integer NOT NULL,
    timestamp timestamp with time zone NOT NULL,
    max_modified timestamp with time zone NOT NULL,
    source_states trend_directory.source_fragment_state[] DEFAULT NULL,
    processed_states trend_directory.source_fragment_state[] DEFAULT NULL,
    job_id integer DEFAULT NULL
);

COMMENT ON COLUMN trend_directory.state.materialization_id IS
'The ID of the materialization type';
COMMENT ON COLUMN trend_directory.state.timestamp IS
'The timestamp of the materialized (materialization result) data';
COMMENT ON COLUMN trend_directory.state.max_modified IS
'The greatest modified timestamp of all materialization sources';
COMMENT ON COLUMN trend_directory.state.source_states IS
'Array of trend_store_id/timestamp/modified combinations for all source data fragments';
COMMENT ON COLUMN trend_directory.state.processed_states IS
'Array containing a snapshot of the source_states at the time of the most recent materialization';
COMMENT ON COLUMN trend_directory.state.job_id IS
'ID of the most recent job for this materialization';

ALTER TABLE ONLY trend_directory.state
    ADD CONSTRAINT state_pkey PRIMARY KEY (materialization_id, timestamp);

ALTER TABLE ONLY trend_directory.state
    ADD CONSTRAINT materialization_state_materialization_id_fkey
    FOREIGN KEY (materialization_id) REFERENCES trend_directory.materialization(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE trend_directory.state TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend_directory.state TO minerva_writer;


-- Table 'materialization_tag_link'

CREATE TABLE trend_directory.materialization_tag_link (
    materialization_id integer NOT NULL,
    tag_id integer NOT NULL
);

COMMENT ON TABLE trend_directory.materialization_tag_link IS
'Links tags to materializations. Examples of tags to link to a materialization
might be: online, offline, aggregation, kpi, etc.';

ALTER TABLE ONLY trend_directory.materialization_tag_link
    ADD CONSTRAINT materialization_tag_link_pkey PRIMARY KEY (materialization_id, tag_id);

ALTER TABLE ONLY trend_directory.materialization_tag_link
    ADD CONSTRAINT materialization_tag_link_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES directory.tag(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY trend_directory.materialization_tag_link
    ADD CONSTRAINT materialization_tag_link_materialization_id_fkey FOREIGN KEY (materialization_id) REFERENCES trend_directory.materialization(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE trend_directory.materialization_tag_link TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend_directory.materialization_tag_link TO minerva_writer;


-- Table 'group_priority'

CREATE TABLE trend_directory.group_priority (
    tag_id integer references directory.tag(id) PRIMARY KEY,
    resources integer not null default 500
);

GRANT SELECT ON TABLE trend_directory.group_priority TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend_directory.group_priority TO minerva_writer;


-- Table 'materialization_trend_store_link'

CREATE TABLE trend_directory.materialization_trend_store_link (
    materialization_id integer NOT NULL REFERENCES trend_directory.materialization(id) ON DELETE CASCADE,
    trend_store_id integer NOT NULL REFERENCES trend_directory.table_trend_store(id) ON DELETE CASCADE
);

COMMENT ON TABLE trend_directory.materialization_trend_store_link IS
'Stores the dependencies between a materialization and its source table trend
stores. Multiple levels of views and functions may exist between a
materialization and its source table trend stores. These intermediate views and
functions are not registered here, but only the table trend stores containing
the actual source data used in the views and/or functions.';

