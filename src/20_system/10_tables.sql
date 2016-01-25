CREATE SCHEMA system;

GRANT ALL ON SCHEMA system TO minerva_writer;

CREATE TYPE system.job_state_enum AS ENUM (
    'queued',
    'running',
    'finished',
    'failed'
);

-- Table 'system.job_source'

CREATE TABLE system.job_source (
    id integer NOT NULL,
    name character varying(64) NOT NULL,
    job_type character varying(64) NOT NULL,
    config json
);

CREATE SEQUENCE system.job_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE system.job_source_id_seq OWNED BY system.job_source.id;

ALTER TABLE system.job_source
    ALTER COLUMN id
    SET DEFAULT nextval('system.job_source_id_seq'::regclass);

ALTER TABLE ONLY system.job_source
    ADD CONSTRAINT job_source_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX ix_system_job_source_name
    ON system.job_source USING btree (name);

GRANT SELECT ON TABLE system.job_source TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE system.job_source TO minerva_writer;

GRANT SELECT ON SEQUENCE system.job_source_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE system.job_source_id_seq TO minerva_writer;


-- Table 'job'

CREATE TABLE system.job (
    id integer NOT NULL,
    type character varying NOT NULL,
    description json NOT NULL,
    size bigint NOT NULL,
    created timestamp with time zone NOT NULL DEFAULT now(),
    started timestamp with time zone,
    finished timestamp with time zone,
    job_source_id integer NOT NULL,
    state system.job_state_enum NOT NULL DEFAULT 'queued'
);

CREATE SEQUENCE system.job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE system.job_id_seq OWNED BY system.job.id;

ALTER TABLE system.job
    ALTER COLUMN id
    SET DEFAULT nextval('system.job_id_seq'::regclass);

ALTER TABLE ONLY system.job
    ADD CONSTRAINT job_pkey PRIMARY KEY (id);

ALTER TABLE ONLY system.job
    ADD CONSTRAINT job_job_source_id_fkey
    FOREIGN KEY (job_source_id) REFERENCES system.job_source(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE system.job TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE system.job TO minerva_writer;

GRANT SELECT ON SEQUENCE system.job_id_seq TO minerva;
GRANT UPDATE ON SEQUENCE system.job_id_seq TO minerva_writer;

-- Table 'system.job_error_log'

CREATE TABLE system.job_error_log (
    job_id integer NOT NULL,
    message character varying
);

ALTER TABLE ONLY system.job_error_log
    ADD CONSTRAINT job_error_log_pkey PRIMARY KEY (job_id);

GRANT SELECT ON TABLE system.job_error_log TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE system.job_error_log TO minerva_writer;

-- Table 'system.job_queue'

CREATE TABLE system.job_queue (
    job_id integer NOT NULL
);

ALTER TABLE ONLY system.job_queue
    ADD CONSTRAINT job_queue_pkey PRIMARY KEY (job_id);

ALTER TABLE ONLY system.job_queue
    ADD CONSTRAINT job_queue_job_id_fkey
    FOREIGN KEY (job_id) REFERENCES system.job(id)
    ON DELETE CASCADE;

GRANT SELECT ON TABLE system.job_queue TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE system.job_queue TO minerva_writer;

-- Table 'system.setting'

CREATE TABLE system.setting (
    id integer NOT NULL,
    name text NOT NULL,
    value text
);

CREATE SEQUENCE system.setting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE system.setting_id_seq OWNED BY system.setting.id;

ALTER TABLE system.setting
    ALTER COLUMN id
    SET DEFAULT nextval('system.setting_id_seq'::regclass);

ALTER TABLE ONLY system.setting
    ADD CONSTRAINT setting_pkey PRIMARY KEY (id);

GRANT SELECT ON TABLE system.setting TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE system.setting TO minerva_writer;
