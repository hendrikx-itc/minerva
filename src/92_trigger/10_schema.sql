-- Schema trigger

CREATE SCHEMA trigger;
ALTER SCHEMA trigger OWNER TO minerva_admin;

GRANT ALL ON SCHEMA trigger TO minerva_writer;
GRANT USAGE ON SCHEMA trigger TO minerva;


CREATE TYPE trigger.kpi_def AS (
    name name,
    data_type name
);

CREATE TYPE trigger.threshold_def AS (
    name name,
    data_type name
);


CREATE TYPE trigger.notification AS (
    entity_id integer,
    timestamp timestamp with time zone,
    weight integer,
    details text
);


-- Table 'rule'

CREATE TABLE trigger.rule (
    id serial PRIMARY KEY,
    name name,
    notificationstore_id integer references notification.notificationstore(id),
    granularity interval,
    default_interval interval,
    enabled boolean NOT null DEFAULT false,
    UNIQUE(name)
);

ALTER TABLE trigger.rule OWNER TO minerva_admin;

GRANT ALL ON TABLE trigger.rule TO minerva_admin;
GRANT SELECT ON TABLE trigger.rule TO minerva;
GRANT UPDATE ON TABLE trigger.rule TO minerva_writer;

-- Table 'exception_base'

CREATE TABLE trigger.exception_base
(
    id serial,
    entity_id integer references directory.entity(id),
    created timestamp with time zone default now(),
    start timestamp with time zone,
    expires timestamp with time zone
);

ALTER TABLE trigger.exception_base OWNER TO minerva_admin;

GRANT ALL ON TABLE trigger.exception_base TO minerva_admin;
GRANT SELECT ON TABLE trigger.exception_base TO minerva;
GRANT UPDATE ON TABLE trigger.exception_base TO minerva_writer;

-- Table 'rule_tag_link'

CREATE TABLE trigger.rule_tag_link (
    rule_id integer references trigger.rule(id) on delete cascade,
    tag_id integer references directory.tag(id) on delete cascade
);

ALTER TABLE trigger.rule_tag_link OWNER TO minerva_admin;

GRANT ALL ON TABLE trigger.rule_tag_link TO minerva_admin;
GRANT SELECT ON TABLE trigger.rule_tag_link TO minerva;
GRANT UPDATE ON TABLE trigger.rule_tag_link TO minerva_writer;

-- Table 'rule_state'

CREATE TABLE trigger.rule_state (
    rule_id integer references trigger.rule(id) on delete cascade,
    timestamp timestamp with time zone,
    fingerprint text,
    PRIMARY KEY (rule_id, timestamp)
);

ALTER TABLE trigger.rule_state OWNER TO minerva_admin;

GRANT ALL ON TABLE trigger.rule_state TO minerva_admin;
GRANT SELECT ON TABLE trigger.rule_state TO minerva;
GRANT UPDATE,INSERT ON TABLE trigger.rule_state TO minerva_writer;

-- Schema trigger_rule

CREATE SCHEMA trigger_rule;

COMMENT ON SCHEMA trigger_rule IS
'Holds trigger specific auto-generated code.

This schema is mostly automatically and dynamically populated when creating
rules.';

ALTER SCHEMA trigger_rule OWNER TO minerva_admin;

GRANT ALL ON SCHEMA trigger_rule TO minerva_writer;
GRANT USAGE ON SCHEMA trigger_rule TO minerva;

-- Table 'rule_backup'

CREATE TABLE trigger.rule_backup (
    id serial PRIMARY KEY,
    name name,
    notificationstore_id integer references notification.notificationstore(id),
    granularity interval,
    default_interval interval,
    enabled boolean NOT null DEFAULT false,
    UNIQUE(name)
);

ALTER TABLE trigger.rule_backup OWNER TO minerva_admin;

GRANT ALL ON TABLE trigger.rule_backup TO minerva_admin;
GRANT SELECT ON TABLE trigger.rule_backup TO minerva;
GRANT UPDATE ON TABLE trigger.rule_backup TO minerva_writer;
