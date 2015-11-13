CREATE SCHEMA notification;

COMMENT ON SCHEMA notification IS
'Stores information of events that can occur at irregular intervals, but '
'still have a fixed, known format.';

ALTER SCHEMA notification OWNER TO minerva_admin;

GRANT ALL ON SCHEMA notification TO minerva_writer;
GRANT USAGE ON SCHEMA notification TO minerva;

CREATE TYPE notification.attr_def AS (name name, data_type name);


-- Table 'notification.notificationstore'

CREATE TABLE notification.notificationstore (
    id serial PRIMARY KEY,
    datasource_id integer REFERENCES directory.datasource ON DELETE CASCADE,
    version integer not null,
    CONSTRAINT uniqueness UNIQUE(datasource_id)
);

COMMENT ON TABLE notification.notificationstore IS
'Describes notificationstores. Each notificationstore maps to a set of tables '
'and functions that can store and manage notifications of a certain type. '
'These corresponding tables and functions are created automatically for each '
'notificationstore. Because each notificationstore maps one-on-one to a '
'datasource, the name of the notificationstore is the same as that of the '
'datasource. Use the create_notificationstore function to create new '
'notificationstores.';

ALTER TABLE notification.notificationstore OWNER TO minerva_admin;

GRANT SELECT ON TABLE notification.notificationstore TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE notification.notificationstore TO minerva_writer;


-- Table 'notification.attribute'

CREATE TABLE notification.attribute (
    id serial PRIMARY KEY,
    notificationstore_id integer REFERENCES notification.notificationstore ON DELETE CASCADE,
    name name not null,
    data_type name not null,
    description varchar not null
);

COMMENT ON TABLE notification.attribute IS
'Describes attributes of notificationstores. An attribute of a '
'notificationstore is an attribute that each notification stored in that '
'notificationstore has. An attribute corresponds directly to a column in '
'the main notificationstore table';

ALTER TABLE notification.attribute OWNER TO minerva_admin;

GRANT SELECT ON TABLE notification.attribute TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE notification.attribute TO minerva_writer;


-- Table 'notification.notificationsetstore'

CREATE TABLE notification.notificationsetstore (
    id serial PRIMARY KEY,
    name name not null,
    notificationstore_id integer REFERENCES notification.notificationstore ON DELETE CASCADE
);

COMMENT ON TABLE notification.notificationsetstore IS
'Describes notificationsetstores. A notificationsetstore can hold information '
'over sets of notifications that are related to each other.';

ALTER TABLE notification.notificationsetstore OWNER TO minerva_admin;

GRANT SELECT ON TABLE notification.notificationsetstore TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE notification.notificationsetstore TO minerva_writer;


-- Table 'notification.setattribute'

CREATE TABLE notification.setattribute (
    id serial PRIMARY KEY,
    notificationsetstore_id integer REFERENCES notification.notificationsetstore ON DELETE CASCADE,
    name name not null,
    data_type name not null,
    description varchar not null
);

COMMENT ON TABLE notification.setattribute IS
'Describes attributes of notificationsetstores. A setattribute of a '
'notificationsetstore is an attribute that each notification set has. '
'A setattribute corresponds directly to a column in the main '
'notificationsetstore table.';

ALTER TABLE notification.attribute OWNER TO minerva_admin;

GRANT SELECT ON TABLE notification.attribute TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE notification.attribute TO minerva_writer;
