-- Schema attribute_directory

CREATE SCHEMA attribute_directory;
ALTER SCHEMA attribute_directory OWNER TO minerva_admin;

GRANT ALL ON SCHEMA attribute_directory TO minerva_writer;
GRANT USAGE ON SCHEMA attribute_directory TO minerva;

-- Schema attribute_base

CREATE SCHEMA attribute_base;
ALTER SCHEMA attribute_base OWNER TO minerva_admin;

GRANT ALL ON SCHEMA attribute_base TO minerva_writer;
GRANT USAGE ON SCHEMA attribute_base TO minerva;

-- Schema attribute_history

CREATE SCHEMA attribute_history;
ALTER SCHEMA attribute_history OWNER TO minerva_admin;

GRANT ALL ON SCHEMA attribute_history TO minerva_writer;
GRANT USAGE ON SCHEMA attribute_history TO minerva;

-- Schema attribute_staging

CREATE SCHEMA attribute_staging;
ALTER SCHEMA attribute_staging OWNER TO minerva_admin;

GRANT ALL ON SCHEMA attribute_staging TO minerva_writer;
GRANT USAGE ON SCHEMA attribute_staging TO minerva;

-- Schema attribute

CREATE SCHEMA attribute;
ALTER SCHEMA attribute OWNER TO minerva_admin;

GRANT ALL ON SCHEMA attribute TO minerva_writer;
GRANT USAGE ON SCHEMA attribute TO minerva;
