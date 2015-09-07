notification
============

Stores information of events that can occur at irregular intervals, but still have a fixed, known format.

Tables
------

attribute
`````````

Describes attributes of notificationstores. An attribute of a notificationstore is an attribute that each notification stored in that notificationstore has. An attribute corresponds directly to a column in the main notificationstore table

+----------------------+-------------------+---------------+
| Name                 | Type              |   Description |
+======================+===================+===============+
| id                   | integer           |               |
+----------------------+-------------------+---------------+
| notificationstore_id | integer           |               |
+----------------------+-------------------+---------------+
| name                 | name              |               |
+----------------------+-------------------+---------------+
| data_type            | name              |               |
+----------------------+-------------------+---------------+
| description          | character varying |               |
+----------------------+-------------------+---------------+


notificationsetstore
````````````````````

Describes notificationsetstores. A notificationsetstore can hold information over sets of notifications that are related to each other.

+----------------------+---------+---------------+
| Name                 | Type    |   Description |
+======================+=========+===============+
| id                   | integer |               |
+----------------------+---------+---------------+
| name                 | name    |               |
+----------------------+---------+---------------+
| notificationstore_id | integer |               |
+----------------------+---------+---------------+


notificationstore
`````````````````

Describes notificationstores. Each notificationstore maps to a set of tables and functions that can store and manage notifications of a certain type. These corresponding tables and functions are created automatically for each notificationstore. Because each notificationstore maps one-on-one to a datasource, the name of the notificationstore is the same as that of the datasource. Use the create_notificationstore function to create new notificationstores.

+---------------+---------+---------------+
| Name          | Type    |   Description |
+===============+=========+===============+
| id            | integer |               |
+---------------+---------+---------------+
| datasource_id | integer |               |
+---------------+---------+---------------+
| version       | integer |               |
+---------------+---------+---------------+


setattribute
````````````

Describes attributes of notificationsetstores. A setattribute of a notificationsetstore is an attribute that each notification set has. A setattribute corresponds directly to a column in the main notificationsetstore table.

+-------------------------+-------------------+---------------+
| Name                    | Type              |   Description |
+=========================+===================+===============+
| id                      | integer           |               |
+-------------------------+-------------------+---------------+
| notificationsetstore_id | integer           |               |
+-------------------------+-------------------+---------------+
| name                    | name              |               |
+-------------------------+-------------------+---------------+
| data_type               | name              |               |
+-------------------------+-------------------+---------------+
| description             | character varying |               |
+-------------------------+-------------------+---------------+

Functions
---------

+------------------------------------------------------------------------------+-----------------------------------+---------------+
| Name                                                                         | Return Type                       | Description   |
+==============================================================================+===================================+===============+
| action(anyelement, text)                                                     | anyelement                        |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| add_attribute_column_sql(name, notification.attribute)                       | text                              |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| add_staging_attribute_column_sql(notification.attribute)                     | text                              |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| cleanup_on_datasource_delete()                                               | trigger                           |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| column_exists(schema_name name, table_name name, column_name name)           | boolean                           |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| column_exists(table_name name, column_name name)                             | boolean                           |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_attribute(notification.notificationstore, name, name)                 | SETOF notification.attribute      |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_attribute_column(notification.attribute)                              | notification.attribute            |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_attribute_column_on_insert()                                          | trigger                           |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_notificationsetstore(name name, notification.notificationstore)       | notification.notificationsetstore |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_notificationsetstore(name name, notificationstore_id integer)         | notification.notificationsetstore |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_notificationstore(datasource_name text, notification.attr_def[])      | notification.notificationstore    |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_notificationstore(datasource_id integer)                              | notification.notificationstore    |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_notificationstore(datasource_name text)                               | notification.notificationstore    |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_notificationstore(datasource_id integer, notification.attr_def[])     | notification.notificationstore    |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_staging_table(notification.notificationstore)                         | notification.notificationstore    |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_table(notification.notificationstore)                                 | notification.notificationstore    |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_table_on_insert()                                                     | trigger                           |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| define_notificationsetstore(name name, notificationstore_id integer)         | notification.notificationsetstore |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| drop_notificationsetstore_table_on_delete()                                  | trigger                           |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| drop_table_on_delete()                                                       | trigger                           |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| get_attr_defs(notification.notificationstore)                                | SETOF notification.attr_def       |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| get_column_type_name(namespace_name name, table_name name, column_name name) | name                              |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| get_column_type_name(notification.notificationstore, name)                   | name                              |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| get_notificationstore(datasource_name name)                                  | notification.notificationstore    |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| init_notificationsetstore(notification.notificationsetstore)                 | notification.notificationsetstore |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| notificationstore(notification.notificationsetstore)                         | notification.notificationstore    |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| staging_table_name(notification.notificationstore)                           | name                              |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| table_exists(schema_name name, table_name name)                              | boolean                           |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| table_exists(name)                                                           | boolean                           |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| table_name(notification.notificationstore)                                   | name                              |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| to_char(notification.notificationstore)                                      | text                              |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
