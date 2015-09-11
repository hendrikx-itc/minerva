notification
============

Stores information of events that can occur at irregular intervals, but still have a fixed, known format.

Types
-----

.. _notification.attr_def:

attr_def
````````



+-----------+--------+---------------+
| Name      | Type   |   Description |
+===========+========+===============+
| name      | char[] |               |
+-----------+--------+---------------+
| data_type | char[] |               |
+-----------+--------+---------------+

Tables
------

.. _notification.notificationstore:

notificationstore
`````````````````

Describes notificationstores. Each notificationstore maps to a set of tables and functions that can store and manage notifications of a certain type. These corresponding tables and functions are created automatically for each notificationstore. Because each notificationstore maps one-on-one to a datasource, the name of the notificationstore is the same as that of the datasource. Use the create_notificationstore function to create new notificationstores.

+---------------+---------+---------------+
| Name          | Type    |   Description |
+===============+=========+===============+
| datasource_id | integer |               |
+---------------+---------+---------------+
| version       | integer |               |
+---------------+---------+---------------+
| id            | integer |               |
+---------------+---------+---------------+


.. _notification.attribute:

attribute
`````````

Describes attributes of notificationstores. An attribute of a notificationstore is an attribute that each notification stored in that notificationstore has. An attribute corresponds directly to a column in the main notificationstore table

+----------------------+-------------------+---------------+
| Name                 | Type              |   Description |
+======================+===================+===============+
| notificationstore_id | integer           |               |
+----------------------+-------------------+---------------+
| name                 | char[]            |               |
+----------------------+-------------------+---------------+
| data_type            | char[]            |               |
+----------------------+-------------------+---------------+
| description          | character varying |               |
+----------------------+-------------------+---------------+
| id                   | integer           |               |
+----------------------+-------------------+---------------+


.. _notification.notificationsetstore:

notificationsetstore
````````````````````

Describes notificationsetstores. A notificationsetstore can hold information over sets of notifications that are related to each other.

+----------------------+---------+---------------+
| Name                 | Type    |   Description |
+======================+=========+===============+
| name                 | char[]  |               |
+----------------------+---------+---------------+
| notificationstore_id | integer |               |
+----------------------+---------+---------------+
| id                   | integer |               |
+----------------------+---------+---------------+


.. _notification.setattribute:

setattribute
````````````

Describes attributes of notificationsetstores. A setattribute of a notificationsetstore is an attribute that each notification set has. A setattribute corresponds directly to a column in the main notificationsetstore table.

+-------------------------+-------------------+---------------+
| Name                    | Type              |   Description |
+=========================+===================+===============+
| notificationsetstore_id | integer           |               |
+-------------------------+-------------------+---------------+
| name                    | char[]            |               |
+-------------------------+-------------------+---------------+
| data_type               | char[]            |               |
+-------------------------+-------------------+---------------+
| description             | character varying |               |
+-------------------------+-------------------+---------------+
| id                      | integer           |               |
+-------------------------+-------------------+---------------+

Views
-----
Functions
---------

+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| Name                                                                                                                                                                                       | Return Type                       | Description   |
+============================================================================================================================================================================================+===================================+===============+
| :ref:`action(anyelement, text)<notification.action(anyelement, text)>`                                                                                                                     | anyelement                        |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`to_char(notification.notificationstore)<notification.to_char(notification.notificationstore)>`                                                                                       | text                              |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`get_notificationstore(datasource_name char[])<notification.get_notificationstore(datasource_name char[])>`                                                                           | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`table_name(notification.notificationstore)<notification.table_name(notification.notificationstore)>`                                                                                 | char[]                            |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`staging_table_name(notification.notificationstore)<notification.staging_table_name(notification.notificationstore)>`                                                                 | char[]                            |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_attribute(notification.notificationstore, char[], char[])<notification.create_attribute(notification.notificationstore, char[], char[])>`                                     | notification.attribute            |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_notificationsetstore(name char[], notificationstore_id integer)<notification.create_notificationsetstore(name char[], notificationstore_id integer)>`                         | notification.notificationsetstore |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`get_column_type_name(namespace_name char[], table_name char[], column_name char[])<notification.get_column_type_name(namespace_name char[], table_name char[], column_name char[])>` | char[]                            |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`get_attr_defs(notification.notificationstore)<notification.get_attr_defs(notification.notificationstore)>`                                                                           | notification.attr_def             |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_table_on_insert()<notification.create_table_on_insert()>`                                                                                                                     | trigger                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_attribute_column_on_insert()<notification.create_attribute_column_on_insert()>`                                                                                               | trigger                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`cleanup_on_datasource_delete()<notification.cleanup_on_datasource_delete()>`                                                                                                         | trigger                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_table(notification.notificationstore)<notification.create_table(notification.notificationstore)>`                                                                             | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_staging_table(notification.notificationstore)<notification.create_staging_table(notification.notificationstore)>`                                                             | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`table_exists(schema_name char[], table_name char[])<notification.table_exists(schema_name char[], table_name char[])>`                                                               | boolean                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`table_exists(char[])<notification.table_exists(char[])>`                                                                                                                             | boolean                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`column_exists(schema_name char[], table_name char[], column_name char[])<notification.column_exists(schema_name char[], table_name char[], column_name char[])>`                     | boolean                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`column_exists(table_name char[], column_name char[])<notification.column_exists(table_name char[], column_name char[])>`                                                             | boolean                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_notificationstore(datasource_id integer)<notification.create_notificationstore(datasource_id integer)>`                                                                       | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_notificationstore(datasource_name text)<notification.create_notificationstore(datasource_name text)>`                                                                         | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_notificationstore(datasource_id integer, attr_def[])<notification.create_notificationstore(datasource_id integer, attr_def[])>`                                               | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_notificationstore(datasource_name text, attr_def[])<notification.create_notificationstore(datasource_name text, attr_def[])>`                                                 | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`define_notificationsetstore(name char[], notificationstore_id integer)<notification.define_notificationsetstore(name char[], notificationstore_id integer)>`                         | notification.notificationsetstore |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`notificationstore(notification.notificationsetstore)<notification.notificationstore(notification.notificationsetstore)>`                                                             | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`init_notificationsetstore(notification.notificationsetstore)<notification.init_notificationsetstore(notification.notificationsetstore)>`                                             | notification.notificationsetstore |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_notificationsetstore(name char[], notification.notificationstore)<notification.create_notificationsetstore(name char[], notification.notificationstore)>`                     | notification.notificationsetstore |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`get_column_type_name(notification.notificationstore, char[])<notification.get_column_type_name(notification.notificationstore, char[])>`                                             | char[]                            |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`add_attribute_column_sql(char[], notification.attribute)<notification.add_attribute_column_sql(char[], notification.attribute)>`                                                     | text                              |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`add_staging_attribute_column_sql(notification.attribute)<notification.add_staging_attribute_column_sql(notification.attribute)>`                                                     | text                              |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_attribute_column(notification.attribute)<notification.create_attribute_column(notification.attribute)>`                                                                       | notification.attribute            |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`drop_table_on_delete()<notification.drop_table_on_delete()>`                                                                                                                         | trigger                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`drop_notificationsetstore_table_on_delete()<notification.drop_notificationsetstore_table_on_delete()>`                                                                               | trigger                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+

.. _notification.action(anyelement, text):

action(anyelement, text) -> anyelement
``````````````````````````````````````
returns: anyelement



.. _notification.to_char(notification.notificationstore):

to_char(notification.notificationstore) -> text
```````````````````````````````````````````````
returns: text



.. _notification.get_notificationstore(datasource_name char[]):

get_notificationstore(datasource_name char[]) -> notification.notificationstore
```````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.notificationstore<notification.notificationstore>`



.. _notification.table_name(notification.notificationstore):

table_name(notification.notificationstore) -> char[]
````````````````````````````````````````````````````
returns: char[]



.. _notification.staging_table_name(notification.notificationstore):

staging_table_name(notification.notificationstore) -> char[]
````````````````````````````````````````````````````````````
returns: char[]



.. _notification.create_attribute(notification.notificationstore, char[], char[]):

create_attribute(notification.notificationstore, char[], char[]) -> SETOF notification.attribute
````````````````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.attribute<notification.attribute>`



.. _notification.create_notificationsetstore(name char[], notificationstore_id integer):

create_notificationsetstore(name char[], notificationstore_id integer) -> notification.notificationsetstore
```````````````````````````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.notificationsetstore<notification.notificationsetstore>`



.. _notification.get_column_type_name(namespace_name char[], table_name char[], column_name char[]):

get_column_type_name(namespace_name char[], table_name char[], column_name char[]) -> char[]
````````````````````````````````````````````````````````````````````````````````````````````
returns: char[]



.. _notification.get_attr_defs(notification.notificationstore):

get_attr_defs(notification.notificationstore) -> SETOF notification.attr_def
````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.attr_def<notification.attr_def>`



.. _notification.create_table_on_insert():

create_table_on_insert() -> trigger
```````````````````````````````````
returns: trigger



.. _notification.create_attribute_column_on_insert():

create_attribute_column_on_insert() -> trigger
``````````````````````````````````````````````
returns: trigger



.. _notification.cleanup_on_datasource_delete():

cleanup_on_datasource_delete() -> trigger
`````````````````````````````````````````
returns: trigger



.. _notification.create_table(notification.notificationstore):

create_table(notification.notificationstore) -> notification.notificationstore
``````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.notificationstore<notification.notificationstore>`



.. _notification.create_staging_table(notification.notificationstore):

create_staging_table(notification.notificationstore) -> notification.notificationstore
``````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.notificationstore<notification.notificationstore>`



.. _notification.table_exists(schema_name char[], table_name char[]):

table_exists(schema_name char[], table_name char[]) -> boolean
``````````````````````````````````````````````````````````````
returns: boolean



.. _notification.table_exists(char[]):

table_exists(char[]) -> boolean
```````````````````````````````
returns: boolean



.. _notification.column_exists(schema_name char[], table_name char[], column_name char[]):

column_exists(schema_name char[], table_name char[], column_name char[]) -> boolean
```````````````````````````````````````````````````````````````````````````````````
returns: boolean



.. _notification.column_exists(table_name char[], column_name char[]):

column_exists(table_name char[], column_name char[]) -> boolean
```````````````````````````````````````````````````````````````
returns: boolean



.. _notification.create_notificationstore(datasource_id integer):

create_notificationstore(datasource_id integer) -> notification.notificationstore
`````````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.notificationstore<notification.notificationstore>`



.. _notification.create_notificationstore(datasource_name text):

create_notificationstore(datasource_name text) -> notification.notificationstore
````````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.notificationstore<notification.notificationstore>`



.. _notification.create_notificationstore(datasource_id integer, attr_def[]):

create_notificationstore(datasource_id integer, attr_def[]) -> notification.notificationstore
`````````````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.notificationstore<notification.notificationstore>`



.. _notification.create_notificationstore(datasource_name text, attr_def[]):

create_notificationstore(datasource_name text, attr_def[]) -> notification.notificationstore
````````````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.notificationstore<notification.notificationstore>`



.. _notification.define_notificationsetstore(name char[], notificationstore_id integer):

define_notificationsetstore(name char[], notificationstore_id integer) -> notification.notificationsetstore
```````````````````````````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.notificationsetstore<notification.notificationsetstore>`



.. _notification.notificationstore(notification.notificationsetstore):

notificationstore(notification.notificationsetstore) -> notification.notificationstore
``````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.notificationstore<notification.notificationstore>`



.. _notification.init_notificationsetstore(notification.notificationsetstore):

init_notificationsetstore(notification.notificationsetstore) -> notification.notificationsetstore
`````````````````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.notificationsetstore<notification.notificationsetstore>`



.. _notification.create_notificationsetstore(name char[], notification.notificationstore):

create_notificationsetstore(name char[], notification.notificationstore) -> notification.notificationsetstore
`````````````````````````````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.notificationsetstore<notification.notificationsetstore>`



.. _notification.get_column_type_name(notification.notificationstore, char[]):

get_column_type_name(notification.notificationstore, char[]) -> char[]
``````````````````````````````````````````````````````````````````````
returns: char[]



.. _notification.add_attribute_column_sql(char[], notification.attribute):

add_attribute_column_sql(char[], notification.attribute) -> text
````````````````````````````````````````````````````````````````
returns: text



.. _notification.add_staging_attribute_column_sql(notification.attribute):

add_staging_attribute_column_sql(notification.attribute) -> text
````````````````````````````````````````````````````````````````
returns: text



.. _notification.create_attribute_column(notification.attribute):

create_attribute_column(notification.attribute) -> notification.attribute
`````````````````````````````````````````````````````````````````````````
returns: :ref:`notification.attribute<notification.attribute>`



.. _notification.drop_table_on_delete():

drop_table_on_delete() -> trigger
`````````````````````````````````
returns: trigger



.. _notification.drop_notificationsetstore_table_on_delete():

drop_notificationsetstore_table_on_delete() -> trigger
``````````````````````````````````````````````````````
returns: trigger



