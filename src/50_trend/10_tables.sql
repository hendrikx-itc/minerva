CREATE SCHEMA trend;

COMMENT ON SCHEMA trend IS
'Stores information with fixed interval and format, like periodic measurements.';

GRANT ALL ON SCHEMA trend TO minerva_writer;
GRANT USAGE ON SCHEMA trend TO minerva;


CREATE SCHEMA trend_partition;

COMMENT ON SCHEMA trend_partition IS
'Stores information with fixed interval and format, like periodic measurements.';

GRANT ALL ON SCHEMA trend_partition TO minerva_writer;
GRANT USAGE ON SCHEMA trend_partition TO minerva;


CREATE SCHEMA trend_directory;

COMMENT ON SCHEMA trend_directory IS
'Stores information with fixed interval and format, like periodic measurements.';

GRANT ALL ON SCHEMA trend_directory TO minerva_writer;
GRANT USAGE ON SCHEMA trend_directory TO minerva;


-- Type 'trend_directory.trend_descr'

CREATE TYPE trend_directory.trend_descr AS (
    name name,
    data_type text,
    description text
);


-- Table 'trend_directory.trend_store'

CREATE TABLE trend_directory.trend_store (
    id integer NOT NULL,
    entity_type_id integer NOT NULL,
    data_source_id integer NOT NULL,
    granularity interval NOT NULL
);

CREATE SEQUENCE trend_directory.trend_store_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE trend_directory.trend_store_id_seq OWNED BY trend_directory.trend_store.id;

ALTER TABLE trend_directory.trend_store
    ALTER COLUMN id
    SET DEFAULT nextval('trend_directory.trend_store_id_seq'::regclass);

ALTER TABLE ONLY trend_directory.trend_store
    ADD CONSTRAINT trend_store_pkey PRIMARY KEY (id);

ALTER TABLE ONLY trend_directory.trend_store
    ADD CONSTRAINT trend_trend_store_entity_type_id_fkey
    FOREIGN KEY (entity_type_id) REFERENCES directory.entity_type(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY trend_directory.trend_store
    ADD CONSTRAINT trend_trend_store_data_source_id_fkey
    FOREIGN KEY(data_source_id) REFERENCES directory.data_source(id);

CREATE UNIQUE INDEX ix_trend_trend_store_uniqueness
    ON trend_directory.trend_store (entity_type_id, data_source_id, granularity);

GRANT SELECT ON TABLE trend_directory.trend_store TO minerva;

GRANT SELECT ON SEQUENCE trend_directory.trend_store_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE trend_directory.trend_store_id_seq TO minerva_writer;


-- Table 'trend_directory.table_trend_store'


CREATE TABLE trend_directory.table_trend_store (
    partition_size integer NOT NULL,
    retention_period interval NOT NULL DEFAULT interval '1 month'
) INHERITS (trend_directory.trend_store);

ALTER TABLE ONLY trend_directory.table_trend_store
    ADD CONSTRAINT table_trend_store_pkey PRIMARY KEY (id);

GRANT SELECT ON TABLE trend_directory.table_trend_store TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend_directory.table_trend_store TO minerva_writer;


-- Table 'trend_directory.view_trend_store'


CREATE TABLE trend_directory.view_trend_store (
) INHERITS (trend_directory.trend_store);

ALTER TABLE ONLY trend_directory.view_trend_store
    ADD CONSTRAINT view_trend_store_pkey PRIMARY KEY (id);

GRANT SELECT ON TABLE trend_directory.view_trend_store TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend_directory.view_trend_store TO minerva_writer;


-- Table 'trend_directory.trend'

CREATE TABLE trend_directory.trend (
    id integer NOT NULL,
    trend_store_id integer NOT NULL,
    name name NOT NULL,
    data_type text NOT NULL,
    description text NOT NULL
);

CREATE SEQUENCE trend_directory.trend_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE trend_directory.trend
    ALTER COLUMN id
    SET DEFAULT nextval('trend_directory.trend_id_seq'::regclass);

ALTER SEQUENCE trend_directory.trend_id_seq OWNED BY trend_directory.trend.id;

ALTER TABLE ONLY trend_directory.trend
    ADD CONSTRAINT trend_pkey PRIMARY KEY (id);

GRANT SELECT ON TABLE trend_directory.trend TO minerva;

GRANT SELECT ON SEQUENCE trend_directory.trend_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE trend_directory.trend_id_seq TO minerva_writer;


-- Table 'trend_directory.table_trend'

CREATE TABLE trend_directory.table_trend(
) INHERITS (trend_directory.trend);

ALTER TABLE ONLY trend_directory.table_trend
    ADD CONSTRAINT table_trend_pkey PRIMARY KEY (id);

ALTER TABLE trend_directory.table_trend
    ALTER COLUMN id
    SET DEFAULT nextval('trend_directory.trend_id_seq'::regclass);

ALTER TABLE trend_directory.table_trend
ADD FOREIGN KEY (trend_store_id) REFERENCES trend_directory.table_trend_store(id) ON DELETE CASCADE;


-- Table 'trend_directory.view_trend'

CREATE TABLE trend_directory.view_trend(
) INHERITS (trend_directory.trend);

ALTER TABLE ONLY trend_directory.view_trend
    ADD CONSTRAINT view_trend_pkey PRIMARY KEY (id);

ALTER TABLE trend_directory.view_trend
    ALTER COLUMN id
    SET DEFAULT nextval('trend_directory.trend_id_seq'::regclass);

ALTER TABLE trend_directory.view_trend
ADD FOREIGN KEY (trend_store_id) REFERENCES trend_directory.view_trend_store(id) ON DELETE CASCADE;


-- Table 'trend_directory.partition'

CREATE TABLE trend_directory.partition (
    table_trend_store_id integer,
    index integer
);

ALTER TABLE ONLY trend_directory.partition
    ADD CONSTRAINT trend_partition_pkey
    PRIMARY KEY (table_trend_store_id, index);

ALTER TABLE ONLY trend_directory.partition
    ADD CONSTRAINT trend_partition_trend_store_id_fkey
    FOREIGN KEY (table_trend_store_id) REFERENCES trend_directory.table_trend_store(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE trend_directory.partition TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend_directory.partition TO minerva_writer;


-- Table 'trend_directory.trend_tag_link'

CREATE TABLE trend_directory.trend_tag_link (
    trend_id integer NOT NULL,
    tag_id integer NOT NULL
);

ALTER TABLE ONLY trend_directory.trend_tag_link
    ADD CONSTRAINT trend_tag_link_pkey
    PRIMARY KEY (trend_id, tag_id);

ALTER TABLE ONLY trend_directory.trend_tag_link
    ADD CONSTRAINT trend_tag_link_tag_id_fkey
    FOREIGN KEY (tag_id) REFERENCES directory.tag(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY trend_directory.trend_tag_link
    ADD CONSTRAINT trend_tag_link_trend_id_fkey
    FOREIGN KEY (trend_id) REFERENCES trend_directory.trend(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE trend_directory.trend_tag_link TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend_directory.trend_tag_link TO minerva_writer;

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


-- Table 'trend_directory.view_dependency'

CREATE TABLE trend_directory.view_dependency (
    view_trend_store_id integer not null,
    table_trend_store_id integer not null
);

ALTER TABLE ONLY trend_directory.view_dependency
    ADD CONSTRAINT trend_view_dependency_pkey
    PRIMARY KEY (view_trend_store_id, table_trend_store_id);

ALTER TABLE ONLY trend_directory.view_dependency
    ADD CONSTRAINT view_dependency_view_trend_store_id_fkey
    FOREIGN KEY (view_trend_store_id) REFERENCES trend_directory.view_trend_store(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY trend_directory.view_dependency
    ADD CONSTRAINT view_dependency_table_trend_store_id_fkey
    FOREIGN KEY (table_trend_store_id) REFERENCES trend_directory.table_trend_store(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE trend_directory.view_dependency TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend_directory.view_dependency TO minerva_writer;
