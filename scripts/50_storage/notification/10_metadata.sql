----------------------------------
-- Schema 'notification_directory'
----------------------------------

CREATE SCHEMA notification_directory;

COMMENT ON SCHEMA notification_directory IS
'Stores meta-data about notification data in the notification schema.';

GRANT ALL ON SCHEMA notification_directory TO minerva_writer;
GRANT USAGE ON SCHEMA notification_directory TO minerva;

CREATE TYPE notification_directory.attr_def AS (
    name name,
    data_type name,
    description text
);


-- Table 'notification_directory.notification_store'

CREATE TABLE notification_directory.notification_store (
    id serial PRIMARY KEY,
    data_source_id integer REFERENCES directory.data_source ON DELETE CASCADE,
    CONSTRAINT uniqueness UNIQUE(data_source_id)
);

COMMENT ON TABLE notification_directory.notification_store IS
'Describes notification_stores. Each notification_store maps to a set of tables '
'and functions that can store and manage notifications of a certain type. '
'These corresponding tables and functions are created automatically for each '
'notification_store. Because each notification_store maps one-on-one to a '
'data_source, the name of the notification_store is the same as that of the '
'data_source. Use the create_notification_store function to create new '
'notification_stores.';

GRANT SELECT ON TABLE notification_directory.notification_store TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE notification_directory.notification_store TO minerva_writer;


-- Table 'notification_directory.attribute'

CREATE TABLE notification_directory.attribute (
    id serial PRIMARY KEY,
    notification_store_id integer REFERENCES notification_directory.notification_store ON DELETE CASCADE,
    name name not null,
    data_type name not null,
    description varchar not null
);

COMMENT ON TABLE notification_directory.attribute IS
'Describes attributes of notification stores. An attribute of a '
'notification store is an attribute that each notification stored in that '
'notification store has. An attribute corresponds directly to a column in '
'the main notification store table';

GRANT SELECT ON TABLE notification_directory.attribute TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE notification_directory.attribute TO minerva_writer;


-- Table 'notification_directory.notification_set_store'

CREATE TABLE notification_directory.notification_set_store (
    id serial PRIMARY KEY,
    name name not null,
    notification_store_id integer REFERENCES notification_directory.notification_store ON DELETE CASCADE
);

COMMENT ON TABLE notification_directory.notification_set_store IS
'Describes notification_set_stores. A notification_set_store can hold information '
'over sets of notifications that are related to each other.';

GRANT SELECT ON TABLE notification_directory.notification_set_store TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE notification_directory.notification_set_store TO minerva_writer;


-- Table 'notification_directory.set_attribute'

CREATE TABLE notification_directory.set_attribute (
    id serial PRIMARY KEY,
    notification_set_store_id integer REFERENCES notification_directory.notification_set_store ON DELETE CASCADE,
    name name not null,
    data_type name not null,
    description varchar not null
);

COMMENT ON TABLE notification_directory.set_attribute IS
'Describes attributes of notification_set_stores. A set_attribute of a '
'notification_set_store is an attribute that each notification set has. '
'A set_attribute corresponds directly to a column in the main '
'notification_set_store table.';

GRANT SELECT ON TABLE notification_directory.set_attribute TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE notification_directory.set_attribute TO minerva_writer;


------------------------
-- Schema 'notification'
------------------------

CREATE SCHEMA notification;

COMMENT ON SCHEMA notification IS
'Stores information of events that can occur at irregular intervals, but
still have a fixed, known format.

This schema is dynamically populated.';

GRANT ALL ON SCHEMA notification TO minerva_writer;
GRANT USAGE ON SCHEMA notification TO minerva;

