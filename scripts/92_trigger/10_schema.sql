-- Schema trigger

CREATE SCHEMA trigger;

GRANT ALL ON SCHEMA trigger TO minerva_writer;
GRANT USAGE ON SCHEMA trigger TO minerva;


CREATE TYPE trigger.kpi_def AS (name name, data_type name);


-- Table 'rule'

CREATE TABLE trigger.rule (
    id serial PRIMARY KEY,
    name name,
    notification_store_id integer references notification_directory.notification_store(id),
    granularity interval,
    default_interval interval,
    enabled boolean NOT null DEFAULT false,
    UNIQUE(name)
);

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

GRANT SELECT ON TABLE trigger.exception_base TO minerva;
GRANT UPDATE ON TABLE trigger.exception_base TO minerva_writer;

-- Table 'rule_tag_link'

CREATE TABLE trigger.rule_tag_link (
    rule_id integer references trigger.rule(id) on delete cascade,
    tag_id integer references directory.tag(id) on delete cascade
);

GRANT SELECT ON TABLE trigger.rule_tag_link TO minerva;
GRANT UPDATE ON TABLE trigger.rule_tag_link TO minerva_writer;

-- Schema trigger_rule

CREATE SCHEMA trigger_rule;

GRANT ALL ON SCHEMA trigger_rule TO minerva_writer;
GRANT USAGE ON SCHEMA trigger_rule TO minerva;

-- This schema is dynamically populated with rule specific tables, views and
-- functions.
