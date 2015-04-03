-- Schema attribute_directory

CREATE SCHEMA attribute_directory;

GRANT ALL ON SCHEMA attribute_directory TO minerva_writer;
GRANT USAGE ON SCHEMA attribute_directory TO minerva;

-- Schema attribute_base

CREATE SCHEMA attribute_base;

GRANT ALL ON SCHEMA attribute_base TO minerva_writer;
GRANT USAGE ON SCHEMA attribute_base TO minerva;

-- Schema attribute_history

CREATE SCHEMA attribute_history;

GRANT ALL ON SCHEMA attribute_history TO minerva_writer;
GRANT USAGE ON SCHEMA attribute_history TO minerva;

-- Schema attribute_staging

CREATE SCHEMA attribute_staging;

GRANT ALL ON SCHEMA attribute_staging TO minerva_writer;
GRANT USAGE ON SCHEMA attribute_staging TO minerva;

-- Schema attribute

CREATE SCHEMA attribute;

GRANT ALL ON SCHEMA attribute TO minerva_writer;
GRANT USAGE ON SCHEMA attribute TO minerva;
