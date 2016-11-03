relation_directory
==================

Stores directional relations between entities.

Tables
------

.. _relation_directory.type:

type
````



+-------------+-----------------------+---------------+
| Name        | Type                  |   Description |
+=============+=======================+===============+
| name        | name                  |               |
+-------------+-----------------------+---------------+
| cardinality | type_cardinality_enum |               |
+-------------+-----------------------+---------------+
| id          | int4                  |               |
+-------------+-----------------------+---------------+

Functions
---------

+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| Name                                                                                                                                                             | Return Type             | Description                                                                   |
+==================================================================================================================================================================+=========================+===============================================================================+
| :ref:`create_relation_table_on_insert()<relation_directory.create_relation_table_on_insert()>`                                                                   | trigger                 |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`define(char[])<relation_directory.define(char[])>`                                                                                                         | relation_directory.type | Defines a new relation type, creates the corresponding table and then returns |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`define(char[], text)<relation_directory.define(char[], text)>`                                                                                             | relation_directory.type | Defines a new relation type (just like relation_directory.define(name)),      |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`define_reverse(char[], char[])<relation_directory.define_reverse(char[], char[])>`                                                                         | relation_directory.type |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`create_self_relation()<relation_directory.create_self_relation()>`                                                                                         | trigger                 |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`define_reverse(char[], relation_directory.type)<relation_directory.define_reverse(char[], relation_directory.type)>`                                       | relation_directory.type |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`materialize_relation(relation_directory.type)<relation_directory.materialize_relation(relation_directory.type)>`                                           | integer                 |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`drop_table_on_type_delete()<relation_directory.drop_table_on_type_delete()>`                                                                               | trigger                 |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`table_schema()<relation_directory.table_schema()>`                                                                                                         | name                    |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`drop_relation_view_sql(relation_directory.type)<relation_directory.drop_relation_view_sql(relation_directory.type)>`                                       | text                    |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`get_type(char[])<relation_directory.get_type(char[])>`                                                                                                     | relation_directory.type |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`view_schema()<relation_directory.view_schema()>`                                                                                                           | name                    |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`create_relation_table_sql(relation_directory.type)<relation_directory.create_relation_table_sql(relation_directory.type)>`                                 | text[]                  |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`create_or_replace_relation_view_sql(relation_directory.type, text)<relation_directory.create_or_replace_relation_view_sql(relation_directory.type, text)>` | text                    |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`create_relation_table(relation_directory.type)<relation_directory.create_relation_table(relation_directory.type)>`                                         | relation_directory.type |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`drop_relation_table(relation_directory.type)<relation_directory.drop_relation_table(relation_directory.type)>`                                             | relation_directory.type |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`create_type(char[])<relation_directory.create_type(char[])>`                                                                                               | relation_directory.type |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`name_to_type(char[])<relation_directory.name_to_type(char[])>`                                                                                             | relation_directory.type |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`create_relation_view_sql(relation_directory.type, text)<relation_directory.create_relation_view_sql(relation_directory.type, text)>`                       | text                    |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`create_relation_view(relation_directory.type, text)<relation_directory.create_relation_view(relation_directory.type, text)>`                               | relation_directory.type |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`drop_relation_table_sql(relation_directory.type)<relation_directory.drop_relation_table_sql(relation_directory.type)>`                                     | text                    |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`drop_relation_view(relation_directory.type)<relation_directory.drop_relation_view(relation_directory.type)>`                                               | relation_directory.type |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`update(relation_directory.type, text)<relation_directory.update(relation_directory.type, text)>`                                                           | relation_directory.type |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+
| :ref:`remove(char[])<relation_directory.remove(char[])>`                                                                                                         | void                    |                                                                               |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------+-------------------------------------------------------------------------------+

.. _relation_directory.create_relation_table_on_insert():

create_relation_table_on_insert() -> trigger
````````````````````````````````````````````


.. _relation_directory.define(char[]):

define(char[]) -> relation_directory.type
`````````````````````````````````````````
Defines a new relation type, creates the corresponding table and then returns
the new type record

.. _relation_directory.define(char[], text):

define(char[], text) -> relation_directory.type
```````````````````````````````````````````````
Defines a new relation type (just like relation_directory.define(name)),
including a view that will be used to populate the relation table.

.. _relation_directory.define_reverse(char[], char[]):

define_reverse(char[], char[]) -> relation_directory.type
`````````````````````````````````````````````````````````


.. _relation_directory.create_self_relation():

create_self_relation() -> trigger
`````````````````````````````````


.. _relation_directory.define_reverse(char[], relation_directory.type):

define_reverse(char[], relation_directory.type) -> relation_directory.type
``````````````````````````````````````````````````````````````````````````


.. _relation_directory.materialize_relation(relation_directory.type):

materialize_relation(relation_directory.type) -> integer
````````````````````````````````````````````````````````


.. _relation_directory.drop_table_on_type_delete():

drop_table_on_type_delete() -> trigger
``````````````````````````````````````


.. _relation_directory.table_schema():

table_schema() -> name
``````````````````````


.. _relation_directory.drop_relation_view_sql(relation_directory.type):

drop_relation_view_sql(relation_directory.type) -> text
```````````````````````````````````````````````````````


.. _relation_directory.get_type(char[]):

get_type(char[]) -> relation_directory.type
```````````````````````````````````````````


.. _relation_directory.view_schema():

view_schema() -> name
`````````````````````


.. _relation_directory.create_relation_table_sql(relation_directory.type):

create_relation_table_sql(relation_directory.type) -> text[]
````````````````````````````````````````````````````````````


.. _relation_directory.create_or_replace_relation_view_sql(relation_directory.type, text):

create_or_replace_relation_view_sql(relation_directory.type, text) -> text
``````````````````````````````````````````````````````````````````````````


.. _relation_directory.create_relation_table(relation_directory.type):

create_relation_table(relation_directory.type) -> relation_directory.type
`````````````````````````````````````````````````````````````````````````


.. _relation_directory.drop_relation_table(relation_directory.type):

drop_relation_table(relation_directory.type) -> relation_directory.type
```````````````````````````````````````````````````````````````````````


.. _relation_directory.create_type(char[]):

create_type(char[]) -> relation_directory.type
``````````````````````````````````````````````


.. _relation_directory.name_to_type(char[]):

name_to_type(char[]) -> relation_directory.type
```````````````````````````````````````````````


.. _relation_directory.create_relation_view_sql(relation_directory.type, text):

create_relation_view_sql(relation_directory.type, text) -> text
```````````````````````````````````````````````````````````````


.. _relation_directory.create_relation_view(relation_directory.type, text):

create_relation_view(relation_directory.type, text) -> relation_directory.type
``````````````````````````````````````````````````````````````````````````````


.. _relation_directory.drop_relation_table_sql(relation_directory.type):

drop_relation_table_sql(relation_directory.type) -> text
````````````````````````````````````````````````````````


.. _relation_directory.drop_relation_view(relation_directory.type):

drop_relation_view(relation_directory.type) -> relation_directory.type
``````````````````````````````````````````````````````````````````````


.. _relation_directory.update(relation_directory.type, text):

update(relation_directory.type, text) -> relation_directory.type
````````````````````````````````````````````````````````````````


.. _relation_directory.remove(char[]):

remove(char[]) -> void
``````````````````````


