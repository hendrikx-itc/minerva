notification
============

Stores information of events that can occur at irregular intervals, but still have a fixed, known format.

Tables
------

.. _notification.notificationstore:

notificationstore
`````````````````

Describes notificationstores. Each notificationstore maps to a set of tables and functions that can store and manage notifications of a certain type. These corresponding tables and functions are created automatically for each notificationstore. Because each notificationstore maps one-on-one to a datasource, the name of the notificationstore is the same as that of the datasource. Use the create_notificationstore function to create new notificationstores.

+---------------+--------+---------------+
| Name          | Type   |   Description |
+===============+========+===============+
| datasource_id | int4   |               |
+---------------+--------+---------------+
| version       | int4   |               |
+---------------+--------+---------------+
| id            | int4   |               |
+---------------+--------+---------------+


.. _notification.notificationsetstore:

notificationsetstore
````````````````````

Describes notificationsetstores. A notificationsetstore can hold information over sets of notifications that are related to each other.

+----------------------+--------+---------------+
| Name                 | Type   |   Description |
+======================+========+===============+
| name                 | name   |               |
+----------------------+--------+---------------+
| notificationstore_id | int4   |               |
+----------------------+--------+---------------+
| id                   | int4   |               |
+----------------------+--------+---------------+


.. _notification.setattribute:

setattribute
````````````

Describes attributes of notificationsetstores. A setattribute of a notificationsetstore is an attribute that each notification set has. A setattribute corresponds directly to a column in the main notificationsetstore table.

+-------------------------+---------+---------------+
| Name                    | Type    |   Description |
+=========================+=========+===============+
| notificationsetstore_id | int4    |               |
+-------------------------+---------+---------------+
| name                    | name    |               |
+-------------------------+---------+---------------+
| data_type               | name    |               |
+-------------------------+---------+---------------+
| description             | varchar |               |
+-------------------------+---------+---------------+
| id                      | int4    |               |
+-------------------------+---------+---------------+


.. _notification.attribute:

attribute
`````````

Describes attributes of notificationstores. An attribute of a notificationstore is an attribute that each notification stored in that notificationstore has. An attribute corresponds directly to a column in the main notificationstore table

+----------------------+---------+---------------+
| Name                 | Type    |   Description |
+======================+=========+===============+
| notificationstore_id | int4    |               |
+----------------------+---------+---------------+
| name                 | name    |               |
+----------------------+---------+---------------+
| data_type            | name    |               |
+----------------------+---------+---------------+
| description          | varchar |               |
+----------------------+---------+---------------+
| id                   | int4    |               |
+----------------------+---------+---------------+

Functions
---------

+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| Name                                                                                                                                                         | Return Type                       | Description   |
+==============================================================================================================================================================+===================================+===============+
| :ref:`to_char(notification.notificationstore)<notification.to_char(notification.notificationstore)>`                                                         | text                              |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`get_column_type_name(notification.notificationstore, char[])<notification.get_column_type_name(notification.notificationstore, char[])>`               | name                              |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`add_attribute_column_sql(char[], notification.attribute)<notification.add_attribute_column_sql(char[], notification.attribute)>`                       | text                              |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`add_staging_attribute_column_sql(notification.attribute)<notification.add_staging_attribute_column_sql(notification.attribute)>`                       | text                              |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_attribute(notification.notificationstore, char[], char[])<notification.create_attribute(notification.notificationstore, char[], char[])>`       | SETOF notification.attribute      |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_notificationstore(integer, attr_def[])<notification.create_notificationstore(integer, attr_def[])>`                                             | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`table_name(notification.notificationstore)<notification.table_name(notification.notificationstore)>`                                                   | name                              |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`table_exists(char[])<notification.table_exists(char[])>`                                                                                               | boolean                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_notificationstore(text)<notification.create_notificationstore(text)>`                                                                           | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`define_notificationsetstore(char[], integer)<notification.define_notificationsetstore(char[], integer)>`                                               | notification.notificationsetstore |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`notificationstore(notification.notificationsetstore)<notification.notificationstore(notification.notificationsetstore)>`                               | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_notificationsetstore(char[], notification.notificationstore)<notification.create_notificationsetstore(char[], notification.notificationstore)>` | notification.notificationsetstore |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`get_column_type_name(char[], char[], char[])<notification.get_column_type_name(char[], char[], char[])>`                                               | name                              |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_attribute_column(notification.attribute)<notification.create_attribute_column(notification.attribute)>`                                         | notification.attribute            |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`get_attr_defs(notification.notificationstore)<notification.get_attr_defs(notification.notificationstore)>`                                             | SETOF notification.attr_def       |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`drop_table_on_delete()<notification.drop_table_on_delete()>`                                                                                           | trigger                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`drop_notificationsetstore_table_on_delete()<notification.drop_notificationsetstore_table_on_delete()>`                                                 | trigger                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_attribute_column_on_insert()<notification.create_attribute_column_on_insert()>`                                                                 | trigger                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`cleanup_on_datasource_delete()<notification.cleanup_on_datasource_delete()>`                                                                           | trigger                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_notificationstore(integer)<notification.create_notificationstore(integer)>`                                                                     | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`staging_table_name(notification.notificationstore)<notification.staging_table_name(notification.notificationstore)>`                                   | name                              |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_notificationstore(text, attr_def[])<notification.create_notificationstore(text, attr_def[])>`                                                   | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_table_on_insert()<notification.create_table_on_insert()>`                                                                                       | trigger                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_table(notification.notificationstore)<notification.create_table(notification.notificationstore)>`                                               | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_staging_table(notification.notificationstore)<notification.create_staging_table(notification.notificationstore)>`                               | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`get_notificationstore(char[])<notification.get_notificationstore(char[])>`                                                                             | notification.notificationstore    |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`table_exists(char[], char[])<notification.table_exists(char[], char[])>`                                                                               | boolean                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`init_notificationsetstore(notification.notificationsetstore)<notification.init_notificationsetstore(notification.notificationsetstore)>`               | notification.notificationsetstore |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`action(anyelement, text)<notification.action(anyelement, text)>`                                                                                       | anyelement                        |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`create_notificationsetstore(char[], integer)<notification.create_notificationsetstore(char[], integer)>`                                               | notification.notificationsetstore |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`column_exists(char[], char[])<notification.column_exists(char[], char[])>`                                                                             | boolean                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+
| :ref:`column_exists(char[], char[], char[])<notification.column_exists(char[], char[], char[])>`                                                             | boolean                           |               |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------+---------------+

.. _notification.to_char(notification.notificationstore):

to_char(notification.notificationstore) -> text
```````````````````````````````````````````````


.. _notification.get_column_type_name(notification.notificationstore, char[]):

get_column_type_name(notification.notificationstore, char[]) -> name
````````````````````````````````````````````````````````````````````


.. _notification.add_attribute_column_sql(char[], notification.attribute):

add_attribute_column_sql(char[], notification.attribute) -> text
````````````````````````````````````````````````````````````````


.. _notification.add_staging_attribute_column_sql(notification.attribute):

add_staging_attribute_column_sql(notification.attribute) -> text
````````````````````````````````````````````````````````````````


.. _notification.create_attribute(notification.notificationstore, char[], char[]):

create_attribute(notification.notificationstore, char[], char[]) -> SETOF notification.attribute
````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification.create_notificationstore(integer, attr_def[]):

create_notificationstore(integer, attr_def[]) -> notification.notificationstore
```````````````````````````````````````````````````````````````````````````````


.. _notification.table_name(notification.notificationstore):

table_name(notification.notificationstore) -> name
``````````````````````````````````````````````````


.. _notification.table_exists(char[]):

table_exists(char[]) -> boolean
```````````````````````````````


.. _notification.create_notificationstore(text):

create_notificationstore(text) -> notification.notificationstore
````````````````````````````````````````````````````````````````


.. _notification.define_notificationsetstore(char[], integer):

define_notificationsetstore(char[], integer) -> notification.notificationsetstore
`````````````````````````````````````````````````````````````````````````````````


.. _notification.notificationstore(notification.notificationsetstore):

notificationstore(notification.notificationsetstore) -> notification.notificationstore
``````````````````````````````````````````````````````````````````````````````````````


.. _notification.create_notificationsetstore(char[], notification.notificationstore):

create_notificationsetstore(char[], notification.notificationstore) -> notification.notificationsetstore
````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification.get_column_type_name(char[], char[], char[]):

get_column_type_name(char[], char[], char[]) -> name
````````````````````````````````````````````````````


.. _notification.create_attribute_column(notification.attribute):

create_attribute_column(notification.attribute) -> notification.attribute
`````````````````````````````````````````````````````````````````````````


.. _notification.get_attr_defs(notification.notificationstore):

get_attr_defs(notification.notificationstore) -> SETOF notification.attr_def
````````````````````````````````````````````````````````````````````````````


.. _notification.drop_table_on_delete():

drop_table_on_delete() -> trigger
`````````````````````````````````


.. _notification.drop_notificationsetstore_table_on_delete():

drop_notificationsetstore_table_on_delete() -> trigger
``````````````````````````````````````````````````````


.. _notification.create_attribute_column_on_insert():

create_attribute_column_on_insert() -> trigger
``````````````````````````````````````````````


.. _notification.cleanup_on_datasource_delete():

cleanup_on_datasource_delete() -> trigger
`````````````````````````````````````````


.. _notification.create_notificationstore(integer):

create_notificationstore(integer) -> notification.notificationstore
```````````````````````````````````````````````````````````````````


.. _notification.staging_table_name(notification.notificationstore):

staging_table_name(notification.notificationstore) -> name
``````````````````````````````````````````````````````````


.. _notification.create_notificationstore(text, attr_def[]):

create_notificationstore(text, attr_def[]) -> notification.notificationstore
````````````````````````````````````````````````````````````````````````````


.. _notification.create_table_on_insert():

create_table_on_insert() -> trigger
```````````````````````````````````


.. _notification.create_table(notification.notificationstore):

create_table(notification.notificationstore) -> notification.notificationstore
``````````````````````````````````````````````````````````````````````````````


.. _notification.create_staging_table(notification.notificationstore):

create_staging_table(notification.notificationstore) -> notification.notificationstore
``````````````````````````````````````````````````````````````````````````````````````


.. _notification.get_notificationstore(char[]):

get_notificationstore(char[]) -> notification.notificationstore
```````````````````````````````````````````````````````````````


.. _notification.table_exists(char[], char[]):

table_exists(char[], char[]) -> boolean
```````````````````````````````````````


.. _notification.init_notificationsetstore(notification.notificationsetstore):

init_notificationsetstore(notification.notificationsetstore) -> notification.notificationsetstore
`````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification.action(anyelement, text):

action(anyelement, text) -> anyelement
``````````````````````````````````````


.. _notification.create_notificationsetstore(char[], integer):

create_notificationsetstore(char[], integer) -> notification.notificationsetstore
`````````````````````````````````````````````````````````````````````````````````


.. _notification.column_exists(char[], char[]):

column_exists(char[], char[]) -> boolean
````````````````````````````````````````


.. _notification.column_exists(char[], char[], char[]):

column_exists(char[], char[], char[]) -> boolean
````````````````````````````````````````````````


