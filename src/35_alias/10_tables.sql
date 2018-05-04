CREATE SCHEMA alias_directory;
CREATE SCHEMA alias;

CREATE TABLE alias_directory.alias_type
(
    id serial PRIMARY KEY,
    "name" character varying NOT NULL
);

CREATE UNIQUE INDEX ON alias_directory.alias_type (name, lower(name));
