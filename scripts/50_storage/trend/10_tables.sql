CREATE SCHEMA trend;

COMMENT ON SCHEMA trend IS
'Stores information with fixed interval and format, like periodic measurements.';

ALTER SCHEMA trend OWNER TO minerva_admin;

GRANT ALL ON SCHEMA trend TO minerva_writer;
GRANT USAGE ON SCHEMA trend TO minerva;

-- Type 'trend.trend_descr'

CREATE TYPE trend.trend_descr AS (
    name name,
    datatype varchar,
    description text
);

ALTER TYPE trend.trend_descr OWNER TO minerva_admin;


-- Table 'trend.trend'

CREATE TABLE trend.trend (
    id integer not null,
    name varchar not null,
    description varchar not null
);

ALTER TABLE trend.trend OWNER TO minerva_admin;

CREATE SEQUENCE trend.trend_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE trend.trend_id_seq OWNER TO minerva_admin;

ALTER TABLE trend.trend
    ALTER COLUMN id
    SET DEFAULT nextval('trend.trend_id_seq'::regclass);

ALTER SEQUENCE trend.trend_id_seq OWNED BY trend.trend.id;

ALTER TABLE ONLY trend.trend
    ADD CONSTRAINT trend_pkey PRIMARY KEY (id);

GRANT SELECT ON TABLE trend.trend TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend.trend TO minerva_writer;

GRANT SELECT ON SEQUENCE trend.trend_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE trend.trend_id_seq TO minerva_writer;

CREATE TYPE trend.storetype AS ENUM ('table', 'view');

-- Table 'trend.trendstore'

CREATE TABLE trend.trendstore (
    id integer not null,
    entitytype_id integer not null,
    datasource_id integer not null,
    granularity varchar not null,
    partition_size integer not null,
    type trend.storetype not null DEFAULT 'table',
    version integer not null DEFAULT 4,
    retention_period interval not null DEFAULT interval '1 month'
);

ALTER TABLE trend.trendstore OWNER TO minerva_admin;

CREATE SEQUENCE trend.trendstore_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE trend.trendstore_id_seq OWNER TO minerva_admin;

ALTER SEQUENCE trend.trendstore_id_seq OWNED BY trend.trendstore.id;

ALTER TABLE trend.trendstore
    ALTER COLUMN id
    SET DEFAULT nextval('trend.trendstore_id_seq'::regclass);

ALTER TABLE ONLY trend.trendstore
    ADD CONSTRAINT trendstore_pkey PRIMARY KEY (id);

ALTER TABLE ONLY trend.trendstore
    ADD CONSTRAINT trend_trendstore_entitytype_id_fkey
    FOREIGN KEY (entitytype_id) REFERENCES directory.entitytype(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY trend.trendstore
    ADD CONSTRAINT trend_trendstore_datasource_id_fkey
    FOREIGN KEY(datasource_id) REFERENCES directory.datasource(id);

CREATE UNIQUE INDEX ix_trend_trendstore_uniqueness
    ON trend.trendstore (entitytype_id, datasource_id, granularity);

GRANT SELECT ON TABLE trend.trendstore TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend.trendstore TO minerva_writer;

GRANT SELECT ON SEQUENCE trend.trendstore_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE trend.trendstore_id_seq TO minerva_writer;

-- Table 'trend.trendstore_trend_link'

CREATE TABLE trend.trendstore_trend_link (
    trendstore_id integer NOT NULL,
    trend_id integer NOT NULL
);

ALTER TABLE trend.trendstore_trend_link OWNER TO minerva_admin;

ALTER TABLE ONLY trend.trendstore_trend_link
    ADD CONSTRAINT trend_trendstore_trend_link_pkey
    PRIMARY KEY (trendstore_id, trend_id);

ALTER TABLE ONLY trend.trendstore_trend_link
    ADD CONSTRAINT trend_trendstore_trend_link_trendstore_id_fkey
    FOREIGN KEY (trendstore_id) REFERENCES trend.trendstore(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY trend.trendstore_trend_link
    ADD CONSTRAINT trend_trendstore_trend_link_trend_id_fkey
    FOREIGN KEY (trend_id) REFERENCES trend.trend(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE trend.trendstore_trend_link TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend.trendstore_trend_link TO minerva_writer;

-- Table 'trend.partition'

CREATE TABLE trend.partition (
    table_name name not null,
    trendstore_id integer,
    data_start timestamp with time zone not null,
    data_end timestamp with time zone not null,
    version integer not null default 4
);

ALTER TABLE trend.partition OWNER TO minerva_admin;

ALTER TABLE ONLY trend.partition
    ADD CONSTRAINT trend_partition_pkey
    PRIMARY KEY (table_name);

ALTER TABLE ONLY trend.partition
    ADD CONSTRAINT trend_partition_trendstore_id_fkey
    FOREIGN KEY (trendstore_id) REFERENCES trend.trendstore(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE trend.partition TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend.partition TO minerva_writer;

-- Table 'trend.trend_tag_link'

CREATE TABLE trend.trend_tag_link (
    trend_id integer NOT NULL,
    tag_id integer NOT NULL
);

ALTER TABLE trend.trend_tag_link OWNER TO minerva_admin;

ALTER TABLE ONLY trend.trend_tag_link
    ADD CONSTRAINT trend_tag_link_pkey
    PRIMARY KEY (trend_id, tag_id);

ALTER TABLE ONLY trend.trend_tag_link
    ADD CONSTRAINT trend_tag_link_tag_id_fkey
    FOREIGN KEY (tag_id) REFERENCES directory.tag(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY trend.trend_tag_link
    ADD CONSTRAINT trend_tag_link_trend_id_fkey
    FOREIGN KEY (trend_id) REFERENCES trend.trend(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE trend.trend_tag_link TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend.trend_tag_link TO minerva_writer;

-- Table 'trend.modified'

CREATE TABLE trend.modified (
    "timestamp" timestamp WITH time zone NOT NULL,
    table_name varchar NOT NULL,
    start timestamp WITH time zone NOT NULL,
    "end" timestamp WITH time zone NOT NULL
);

ALTER TABLE trend.modified OWNER TO minerva_admin;

ALTER TABLE ONLY trend.modified
    ADD CONSTRAINT modified_pkey PRIMARY KEY ("timestamp", table_name);

ALTER TABLE ONLY trend.modified
    ADD CONSTRAINT modified_table_name_fkey
    FOREIGN KEY (table_name) REFERENCES trend.partition(table_name)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

GRANT SELECT ON TABLE trend.modified TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend.modified TO minerva_writer;


-- Table 'trend.view'

CREATE TABLE trend.view (
    id integer not null,
    description varchar not null,
    trendstore_id integer not null,
    sql text not null
);

ALTER TABLE trend.view OWNER TO minerva_admin;

CREATE SEQUENCE trend.view_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE trend.view_id_seq OWNER TO minerva_admin;

ALTER TABLE trend.view
    ALTER COLUMN id
    SET DEFAULT nextval('trend.view_id_seq'::regclass);

ALTER SEQUENCE trend.view_id_seq OWNED BY trend.view.id;

ALTER TABLE ONLY trend.view
    ADD CONSTRAINT trend_view_pkey
    PRIMARY KEY (id);

ALTER TABLE ONLY trend.view
    ADD CONSTRAINT trend_view_trendstore_id_fkey
    FOREIGN KEY (trendstore_id) REFERENCES trend.trendstore(id)
    ON DELETE CASCADE;

CREATE UNIQUE INDEX ix_trend_view_uniqueness
    ON trend.view (trendstore_id);

GRANT SELECT ON TABLE trend.view TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend.view TO minerva_writer;

GRANT SELECT ON SEQUENCE trend.view_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE trend.view_id_seq TO minerva_writer;


-- Table 'trend.view_trendstore_link'

CREATE TABLE trend.view_trendstore_link (
    view_id integer not null,
    trendstore_id integer not null
);

ALTER TABLE trend.view_trendstore_link OWNER TO minerva_admin;

ALTER TABLE ONLY trend.view_trendstore_link
    ADD CONSTRAINT trend_view_trendstore_link_pkey
    PRIMARY KEY (view_id, trendstore_id);

ALTER TABLE ONLY trend.view_trendstore_link
    ADD CONSTRAINT view_trendstore_link_view_id_fkey
    FOREIGN KEY (view_id) REFERENCES trend.view(id)
    ON DELETE CASCADE;

ALTER TABLE ONLY trend.view_trendstore_link
    ADD CONSTRAINT view_trendstore_link_trendstore_id_fkey
    FOREIGN KEY (trendstore_id) REFERENCES trend.trendstore(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE trend.view_trendstore_link TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend.view_trendstore_link TO minerva_writer;


CREATE TABLE trend.to_be_vacuumed (
    table_name name not null primary key
);

ALTER TABLE trend.to_be_vacuumed OWNER TO minerva_admin;
GRANT SELECT ON TABLE trend.to_be_vacuumed TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE trend.to_be_vacuumed TO minerva_writer;

