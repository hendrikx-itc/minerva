notification_directory
======================

Stores meta-data about notification data in the notification schema.

Tables
------

.. _notification_directory.notification_store:

notification_store
``````````````````

Describes notification_stores. Each notification_store maps to a set of tables and functions that can store and manage notifications of a certain type. These corresponding tables and functions are created automatically for each notification_store. Because each notification_store maps one-on-one to a data_source, the name of the notification_store is the same as that of the data_source. Use the create_notification_store function to create new notification_stores.

+----------------+--------+---------------+
| Name           | Type   |   Description |
+================+========+===============+
| data_source_id | int4   |               |
+----------------+--------+---------------+
| id             | int4   |               |
+----------------+--------+---------------+


.. _notification_directory.notification_set_store:

notification_set_store
``````````````````````

Describes notification_set_stores. A notification_set_store can hold information over sets of notifications that are related to each other.

+-----------------------+--------+---------------+
| Name                  | Type   |   Description |
+=======================+========+===============+
| name                  | name   |               |
+-----------------------+--------+---------------+
| notification_store_id | int4   |               |
+-----------------------+--------+---------------+
| id                    | int4   |               |
+-----------------------+--------+---------------+


.. _notification_directory.set_attribute:

set_attribute
`````````````

Describes attributes of notification_set_stores. A set_attribute of a notification_set_store is an attribute that each notification set has. A set_attribute corresponds directly to a column in the main notification_set_store table.

+---------------------------+---------+---------------+
| Name                      | Type    |   Description |
+===========================+=========+===============+
| notification_set_store_id | int4    |               |
+---------------------------+---------+---------------+
| name                      | name    |               |
+---------------------------+---------+---------------+
| data_type                 | name    |               |
+---------------------------+---------+---------------+
| description               | varchar |               |
+---------------------------+---------+---------------+
| id                        | int4    |               |
+---------------------------+---------+---------------+


.. _notification_directory.attribute:

attribute
`````````

Describes attributes of notification stores. An attribute of a notification store is an attribute that each notification stored in that notification store has. An attribute corresponds directly to a column in the main notification store table

+-----------------------+---------+---------------+
| Name                  | Type    |   Description |
+=======================+=========+===============+
| notification_store_id | int4    |               |
+-----------------------+---------+---------------+
| name                  | name    |               |
+-----------------------+---------+---------------+
| data_type             | name    |               |
+-----------------------+---------+---------------+
| description           | varchar |               |
+-----------------------+---------+---------------+
| id                    | int4    |               |
+-----------------------+---------+---------------+

Functions
---------

+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| Name                                                                                                                                                                                               | Return Type                                   | Description   |
+====================================================================================================================================================================================================+===============================================+===============+
| :ref:`add_attribute_column_sql(char[], notification_directory.attribute)<notification_directory.add_attribute_column_sql(char[], notification_directory.attribute)>`                               | text                                          |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`notification_store_schema()<notification_directory.notification_store_schema()>`                                                                                                             | name                                          |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`to_char(notification_directory.notification_store)<notification_directory.to_char(notification_directory.notification_store)>`                                                               | text                                          |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`get_notification_store(char[])<notification_directory.get_notification_store(char[])>`                                                                                                       | notification_directory.notification_store     |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`table_name(notification_directory.notification_store)<notification_directory.table_name(notification_directory.notification_store)>`                                                         | name                                          |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`create_table_sql(notification_directory.notification_store)<notification_directory.create_table_sql(notification_directory.notification_store)>`                                             | text[]                                        |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`create_table(notification_directory.notification_store)<notification_directory.create_table(notification_directory.notification_store)>`                                                     | notification_directory.notification_store     |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`initialize_notification_store(notification_directory.notification_store)<notification_directory.initialize_notification_store(notification_directory.notification_store)>`                   | notification_directory.notification_store     |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`create_staging_table_sql(notification_directory.notification_store)<notification_directory.create_staging_table_sql(notification_directory.notification_store)>`                             | text[]                                        |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`create_staging_table(notification_directory.notification_store)<notification_directory.create_staging_table(notification_directory.notification_store)>`                                     | notification_directory.notification_store     |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`define_attribute(notification_directory.notification_store, char[], char[], text)<notification_directory.define_attribute(notification_directory.notification_store, char[], char[], text)>` | SETOF notification_directory.attribute        |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`define_attributes(notification_directory.notification_store, attr_def[])<notification_directory.define_attributes(notification_directory.notification_store, attr_def[])>`                   | notification_directory.notification_store     |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`define_notification_store(integer)<notification_directory.define_notification_store(integer)>`                                                                                               | notification_directory.notification_store     |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`define_notification_store(integer, attr_def[])<notification_directory.define_notification_store(integer, attr_def[])>`                                                                       | notification_directory.notification_store     |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`create_notification_store(integer, attr_def[])<notification_directory.create_notification_store(integer, attr_def[])>`                                                                       | notification_directory.notification_store     |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`create_notification_store(text, attr_def[])<notification_directory.create_notification_store(text, attr_def[])>`                                                                             | notification_directory.notification_store     |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`create_notification_store(integer)<notification_directory.create_notification_store(integer)>`                                                                                               | notification_directory.notification_store     |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`create_notification_store(text)<notification_directory.create_notification_store(text)>`                                                                                                     | notification_directory.notification_store     |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`define_notification_set_store(char[], integer)<notification_directory.define_notification_set_store(char[], integer)>`                                                                       | notification_directory.notification_set_store |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`notification_store(notification_directory.notification_set_store)<notification_directory.notification_store(notification_directory.notification_set_store)>`                                 | notification_directory.notification_store     |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`init_notification_set_store(notification_directory.notification_set_store)<notification_directory.init_notification_set_store(notification_directory.notification_set_store)>`               | notification_directory.notification_set_store |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`create_notification_set_store(char[], integer)<notification_directory.create_notification_set_store(char[], integer)>`                                                                       | notification_directory.notification_set_store |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`create_notification_set_store(char[], notification_directory.notification_store)<notification_directory.create_notification_set_store(char[], notification_directory.notification_store)>`   | notification_directory.notification_set_store |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`get_column_type_name(notification_directory.notification_store, char[])<notification_directory.get_column_type_name(notification_directory.notification_store, char[])>`                     | name                                          |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`add_staging_attribute_column_sql(notification_directory.attribute)<notification_directory.add_staging_attribute_column_sql(notification_directory.attribute)>`                               | text                                          |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`create_attribute_column(notification_directory.attribute)<notification_directory.create_attribute_column(notification_directory.attribute)>`                                                 | notification_directory.attribute              |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`get_attr_defs(notification_directory.notification_store)<notification_directory.get_attr_defs(notification_directory.notification_store)>`                                                   | SETOF notification_directory.attr_def         |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`drop_table_on_delete()<notification_directory.drop_table_on_delete()>`                                                                                                                       | trigger                                       |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`drop_notification_set_store_table_on_delete()<notification_directory.drop_notification_set_store_table_on_delete()>`                                                                         | trigger                                       |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`cleanup_on_data_source_delete()<notification_directory.cleanup_on_data_source_delete()>`                                                                                                     | trigger                                       |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`staging_table_name(notification_directory.notification_store)<notification_directory.staging_table_name(notification_directory.notification_store)>`                                         | name                                          |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+
| :ref:`get_column_type_name(char[], char[], char[])<notification_directory.get_column_type_name(char[], char[], char[])>`                                                                           | name                                          |               |
+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------+---------------+

.. _notification_directory.add_attribute_column_sql(char[], notification_directory.attribute):

add_attribute_column_sql(char[], notification_directory.attribute) -> text
``````````````````````````````````````````````````````````````````````````


.. _notification_directory.notification_store_schema():

notification_store_schema() -> name
```````````````````````````````````


.. _notification_directory.to_char(notification_directory.notification_store):

to_char(notification_directory.notification_store) -> text
``````````````````````````````````````````````````````````


.. _notification_directory.get_notification_store(char[]):

get_notification_store(char[]) -> notification_directory.notification_store
```````````````````````````````````````````````````````````````````````````


.. _notification_directory.table_name(notification_directory.notification_store):

table_name(notification_directory.notification_store) -> name
`````````````````````````````````````````````````````````````


.. _notification_directory.create_table_sql(notification_directory.notification_store):

create_table_sql(notification_directory.notification_store) -> text[]
`````````````````````````````````````````````````````````````````````


.. _notification_directory.create_table(notification_directory.notification_store):

create_table(notification_directory.notification_store) -> notification_directory.notification_store
````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.initialize_notification_store(notification_directory.notification_store):

initialize_notification_store(notification_directory.notification_store) -> notification_directory.notification_store
`````````````````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.create_staging_table_sql(notification_directory.notification_store):

create_staging_table_sql(notification_directory.notification_store) -> text[]
`````````````````````````````````````````````````````````````````````````````


.. _notification_directory.create_staging_table(notification_directory.notification_store):

create_staging_table(notification_directory.notification_store) -> notification_directory.notification_store
````````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.define_attribute(notification_directory.notification_store, char[], char[], text):

define_attribute(notification_directory.notification_store, char[], char[], text) -> SETOF notification_directory.attribute
```````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.define_attributes(notification_directory.notification_store, attr_def[]):

define_attributes(notification_directory.notification_store, attr_def[]) -> notification_directory.notification_store
`````````````````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.define_notification_store(integer):

define_notification_store(integer) -> notification_directory.notification_store
```````````````````````````````````````````````````````````````````````````````


.. _notification_directory.define_notification_store(integer, attr_def[]):

define_notification_store(integer, attr_def[]) -> notification_directory.notification_store
```````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.create_notification_store(integer, attr_def[]):

create_notification_store(integer, attr_def[]) -> notification_directory.notification_store
```````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.create_notification_store(text, attr_def[]):

create_notification_store(text, attr_def[]) -> notification_directory.notification_store
````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.create_notification_store(integer):

create_notification_store(integer) -> notification_directory.notification_store
```````````````````````````````````````````````````````````````````````````````


.. _notification_directory.create_notification_store(text):

create_notification_store(text) -> notification_directory.notification_store
````````````````````````````````````````````````````````````````````````````


.. _notification_directory.define_notification_set_store(char[], integer):

define_notification_set_store(char[], integer) -> notification_directory.notification_set_store
```````````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.notification_store(notification_directory.notification_set_store):

notification_store(notification_directory.notification_set_store) -> notification_directory.notification_store
``````````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.init_notification_set_store(notification_directory.notification_set_store):

init_notification_set_store(notification_directory.notification_set_store) -> notification_directory.notification_set_store
```````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.create_notification_set_store(char[], integer):

create_notification_set_store(char[], integer) -> notification_directory.notification_set_store
```````````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.create_notification_set_store(char[], notification_directory.notification_store):

create_notification_set_store(char[], notification_directory.notification_store) -> notification_directory.notification_set_store
`````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.get_column_type_name(notification_directory.notification_store, char[]):

get_column_type_name(notification_directory.notification_store, char[]) -> name
```````````````````````````````````````````````````````````````````````````````


.. _notification_directory.add_staging_attribute_column_sql(notification_directory.attribute):

add_staging_attribute_column_sql(notification_directory.attribute) -> text
``````````````````````````````````````````````````````````````````````````


.. _notification_directory.create_attribute_column(notification_directory.attribute):

create_attribute_column(notification_directory.attribute) -> notification_directory.attribute
`````````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.get_attr_defs(notification_directory.notification_store):

get_attr_defs(notification_directory.notification_store) -> SETOF notification_directory.attr_def
`````````````````````````````````````````````````````````````````````````````````````````````````


.. _notification_directory.drop_table_on_delete():

drop_table_on_delete() -> trigger
`````````````````````````````````


.. _notification_directory.drop_notification_set_store_table_on_delete():

drop_notification_set_store_table_on_delete() -> trigger
````````````````````````````````````````````````````````


.. _notification_directory.cleanup_on_data_source_delete():

cleanup_on_data_source_delete() -> trigger
``````````````````````````````````````````


.. _notification_directory.staging_table_name(notification_directory.notification_store):

staging_table_name(notification_directory.notification_store) -> name
`````````````````````````````````````````````````````````````````````


.. _notification_directory.get_column_type_name(char[], char[], char[]):

get_column_type_name(char[], char[], char[]) -> name
````````````````````````````````````````````````````


