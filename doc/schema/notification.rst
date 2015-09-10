notification
============

Stores information of events that can occur at irregular intervals, but still have a fixed, known format.

Tables
------

.. _notification.attribute:

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


.. _notification.notificationsetstore:

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


.. _notification.notificationstore:

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


.. _notification.setattribute:

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
| create_notificationstore(datasource_id integer)                              | notification.notificationstore    |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_notificationstore(datasource_name text)                               | notification.notificationstore    |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_notificationstore(datasource_id integer, notification.attr_def[])     | notification.notificationstore    |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| create_notificationstore(datasource_name text, notification.attr_def[])      | notification.notificationstore    |               |
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
| get_column_type_name(notification.notificationstore, name)                   | name                              |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| get_column_type_name(namespace_name name, table_name name, column_name name) | name                              |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| get_notificationstore(datasource_name name)                                  | notification.notificationstore    |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| init_notificationsetstore(notification.notificationsetstore)                 | notification.notificationsetstore |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| notificationstore(notification.notificationsetstore)                         | notification.notificationstore    |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| staging_table_name(notification.notificationstore)                           | name                              |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| table_exists(name)                                                           | boolean                           |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| table_exists(schema_name name, table_name name)                              | boolean                           |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| table_name(notification.notificationstore)                                   | name                              |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+
| to_char(notification.notificationstore)                                      | text                              |               |
+------------------------------------------------------------------------------+-----------------------------------+---------------+

.. _notification.action(anyelement, text):

action(anyelement, text) -> anyelement
``````````````````````````````````````


.. _notification.add_attribute_column_sql(name, notification.attribute):

add_attribute_column_sql(name, notification.attribute) -> text
``````````````````````````````````````````````````````````````


.. _notification.add_staging_attribute_column_sql(notification.attribute):

add_staging_attribute_column_sql(notification.attribute) -> text
````````````````````````````````````````````````````````````````


.. _notification.cleanup_on_datasource_delete():

cleanup_on_datasource_delete() -> trigger
`````````````````````````````````````````


.. _notification.column_exists(schema_name name, table_name name, column_name name):

column_exists(schema_name name, table_name name, column_name name) -> boolean
`````````````````````````````````````````````````````````````````````````````


.. _notification.column_exists(table_name name, column_name name):

column_exists(table_name name, column_name name) -> boolean
```````````````````````````````````````````````````````````


.. _notification.create_attribute(notification.notificationstore, name, name):

create_attribute(notification.notificationstore, name, name) -> SETOF notification.attribute
````````````````````````````````````````````````````````````````````````````````````````````


.. _notification.create_attribute_column(notification.attribute):

create_attribute_column(notification.attribute) -> notification.attribute
`````````````````````````````````````````````````````````````````````````


.. _notification.create_attribute_column_on_insert():

create_attribute_column_on_insert() -> trigger
``````````````````````````````````````````````


.. _notification.create_notificationsetstore(name name, notification.notificationstore):

create_notificationsetstore(name name, notification.notificationstore) -> notification.notificationsetstore
```````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification.create_notificationsetstore(name name, notificationstore_id integer):

create_notificationsetstore(name name, notificationstore_id integer) -> notification.notificationsetstore
`````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification.create_notificationstore(datasource_id integer):

create_notificationstore(datasource_id integer) -> notification.notificationstore
`````````````````````````````````````````````````````````````````````````````````


.. _notification.create_notificationstore(datasource_name text):

create_notificationstore(datasource_name text) -> notification.notificationstore
````````````````````````````````````````````````````````````````````````````````


.. _notification.create_notificationstore(datasource_id integer, notification.attr_def[]):

create_notificationstore(datasource_id integer, notification.attr_def[]) -> notification.notificationstore
``````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification.create_notificationstore(datasource_name text, notification.attr_def[]):

create_notificationstore(datasource_name text, notification.attr_def[]) -> notification.notificationstore
`````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification.create_staging_table(notification.notificationstore):

create_staging_table(notification.notificationstore) -> notification.notificationstore
``````````````````````````````````````````````````````````````````````````````````````


.. _notification.create_table(notification.notificationstore):

create_table(notification.notificationstore) -> notification.notificationstore
``````````````````````````````````````````````````````````````````````````````


.. _notification.create_table_on_insert():

create_table_on_insert() -> trigger
```````````````````````````````````


.. _notification.define_notificationsetstore(name name, notificationstore_id integer):

define_notificationsetstore(name name, notificationstore_id integer) -> notification.notificationsetstore
`````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification.drop_notificationsetstore_table_on_delete():

drop_notificationsetstore_table_on_delete() -> trigger
``````````````````````````````````````````````````````


.. _notification.drop_table_on_delete():

drop_table_on_delete() -> trigger
`````````````````````````````````


.. _notification.get_attr_defs(notification.notificationstore):

get_attr_defs(notification.notificationstore) -> SETOF notification.attr_def
````````````````````````````````````````````````````````````````````````````


.. _notification.get_column_type_name(notification.notificationstore, name):

get_column_type_name(notification.notificationstore, name) -> name
``````````````````````````````````````````````````````````````````


.. _notification.get_column_type_name(namespace_name name, table_name name, column_name name):

get_column_type_name(namespace_name name, table_name name, column_name name) -> name
````````````````````````````````````````````````````````````````````````````````````


.. _notification.get_notificationstore(datasource_name name):

get_notificationstore(datasource_name name) -> notification.notificationstore
`````````````````````````````````````````````````````````````````````````````


.. _notification.init_notificationsetstore(notification.notificationsetstore):

init_notificationsetstore(notification.notificationsetstore) -> notification.notificationsetstore
`````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification.notificationstore(notification.notificationsetstore):

notificationstore(notification.notificationsetstore) -> notification.notificationstore
``````````````````````````````````````````````````````````````````````````````````````


.. _notification.staging_table_name(notification.notificationstore):

staging_table_name(notification.notificationstore) -> name
``````````````````````````````````````````````````````````


.. _notification.table_exists(name):

table_exists(name) -> boolean
`````````````````````````````


.. _notification.table_exists(schema_name name, table_name name):

table_exists(schema_name name, table_name name) -> boolean
``````````````````````````````````````````````````````````


.. _notification.table_name(notification.notificationstore):

table_name(notification.notificationstore) -> name
``````````````````````````````````````````````````


.. _notification.to_char(notification.notificationstore):

to_char(notification.notificationstore) -> text
```````````````````````````````````````````````


