CREATE SCHEMA dimension;
ALTER SCHEMA dimension OWNER TO minerva_admin;

GRANT ALL ON SCHEMA dimension TO minerva_writer;
GRANT USAGE ON SCHEMA dimension TO minerva;

-- Table 'dimension."month"'

CREATE TABLE dimension."month" (
    timestamp timestamp with time zone PRIMARY KEY,
    start timestamp with time zone,
    "end" timestamp with time zone
);

ALTER TABLE dimension."month" OWNER TO minerva_admin;
GRANT SELECT ON TABLE dimension."month" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE dimension."month" TO minerva_writer;

-- Table 'dimension.week'

CREATE TABLE dimension.week (
    timestamp timestamp with time zone PRIMARY KEY,
    start timestamp with time zone,
    "end" timestamp with time zone,
    year smallint,
    week_iso_8601 smallint
);

ALTER TABLE dimension.week OWNER TO minerva_admin;
GRANT SELECT ON TABLE dimension.week TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE dimension.week TO minerva_writer;

-- Table 'dimension."day"'

CREATE TABLE dimension."day" (
    timestamp timestamp with time zone PRIMARY KEY,
    start timestamp with time zone,
    "end" timestamp with time zone
);

ALTER TABLE dimension."day" OWNER TO minerva_admin;
GRANT SELECT ON TABLE dimension."day" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE dimension."day" TO minerva_writer;

-- Table 'dimension.hour'

CREATE TABLE dimension.hour (
    timestamp timestamp with time zone PRIMARY KEY,
    start timestamp with time zone,
    "end" timestamp with time zone
);

ALTER TABLE dimension.hour OWNER TO minerva_admin;
GRANT SELECT ON TABLE dimension.hour TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE dimension.hour TO minerva_writer;

-- Table 'dimension.quarter'

CREATE TABLE dimension.quarter (
    timestamp timestamp with time zone PRIMARY KEY,
    start timestamp with time zone,
    "end" timestamp with time zone
);

ALTER TABLE dimension.quarter OWNER TO minerva_admin;
GRANT SELECT ON TABLE dimension.quarter TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE dimension.quarter TO minerva_writer;

-- Table 'dimension.5m'

CREATE TABLE dimension."5m" (
    timestamp timestamp with time zone PRIMARY KEY,
    start timestamp with time zone,
    "end" timestamp with time zone
);

ALTER TABLE dimension."5m" OWNER TO minerva_admin;
GRANT SELECT ON TABLE dimension."5m" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE dimension."5m" TO minerva_writer;

-- Table 'dimension.four_consec_qtr'

CREATE TABLE dimension."four_consec_qtr" (
    timestamp timestamp with time zone PRIMARY KEY,
    start timestamp with time zone,
    "end" timestamp with time zone
);

ALTER TABLE dimension."four_consec_qtr" OWNER TO minerva_admin;
GRANT SELECT ON TABLE dimension."four_consec_qtr" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE dimension."four_consec_qtr" TO minerva_writer;

-- Table 'dimension."month_15m"'

CREATE TABLE dimension."month_15m" (
    timestamp timestamp with time zone,
    timestamp_15m timestamp with time zone PRIMARY KEY
);

CREATE INDEX month_15m_timestamp_idx ON dimension."month_15m"(timestamp);

ALTER TABLE dimension."month_15m" OWNER TO minerva_admin;
GRANT SELECT ON TABLE dimension."month_15m" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE dimension."month_15m" TO minerva_writer;

-- Table 'dimension."week_15m"'

CREATE TABLE dimension."week_15m" (
    timestamp timestamp with time zone,
    timestamp_15m timestamp with time zone PRIMARY KEY
);

CREATE INDEX week_15m_timestamp_idx ON dimension."week_15m"(timestamp);

ALTER TABLE dimension."week_15m" OWNER TO minerva_admin;
GRANT SELECT ON TABLE dimension."week_15m" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE dimension."week_15m" TO minerva_writer;

-- Table 'dimension."day_15m"'

CREATE TABLE dimension."day_15m" (
    timestamp timestamp with time zone,
    timestamp_15m timestamp with time zone PRIMARY KEY
);

ALTER TABLE dimension."day_15m" OWNER TO minerva_admin;
GRANT SELECT ON TABLE dimension."day_15m" TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE dimension."day_15m" TO minerva_writer;
