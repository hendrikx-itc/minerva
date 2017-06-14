-- Schema attribute_directory

CREATE SCHEMA attribute_directory;
COMMENT ON SCHEMA attribute_directory IS
'Contains a directory with attribute store meta data';

ALTER SCHEMA attribute_directory OWNER TO minerva_admin;

GRANT ALL ON SCHEMA attribute_directory TO minerva_writer;
GRANT USAGE ON SCHEMA attribute_directory TO minerva;

-- Schema attribute_base

CREATE SCHEMA attribute_base;
COMMENT ON SCHEMA attribute_base IS
'Contains the parent/base tables for attribute store data tables';

ALTER SCHEMA attribute_base OWNER TO minerva_admin;

GRANT ALL ON SCHEMA attribute_base TO minerva_writer;
GRANT USAGE ON SCHEMA attribute_base TO minerva;

-- Schema attribute_history

CREATE SCHEMA attribute_history;
COMMENT ON SCHEMA attribute_history IS
'Contains tables with the actual data of attribute stores';

ALTER SCHEMA attribute_history OWNER TO minerva_admin;

GRANT ALL ON SCHEMA attribute_history TO minerva_writer;
GRANT USAGE ON SCHEMA attribute_history TO minerva;

-- Schema attribute_staging

CREATE SCHEMA attribute_staging;
COMMENT ON SCHEMA attribute_staging IS
'Contains tables for staging new data to be added to attribute stores';

ALTER SCHEMA attribute_staging OWNER TO minerva_admin;

GRANT ALL ON SCHEMA attribute_staging TO minerva_writer;
GRANT USAGE ON SCHEMA attribute_staging TO minerva;

-- Schema attribute

CREATE SCHEMA attribute;
COMMENT ON SCHEMA attribute IS
'Contains views pointing to current attribute records';

ALTER SCHEMA attribute OWNER TO minerva_admin;

GRANT ALL ON SCHEMA attribute TO minerva_writer;
GRANT USAGE ON SCHEMA attribute TO minerva;
