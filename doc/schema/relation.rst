relation
========

Stores directional relations between entities.

Tables
------

.. _relation.group:

group
`````



+--------+---------+---------------+
| Name   | Type    |   Description |
+========+=========+===============+
| name   | varchar |               |
+--------+---------+---------------+
| id     | int4    |               |
+--------+---------+---------------+


.. _relation.all_materialized:

all_materialized
````````````````



+-----------+--------+---------------+
| Name      | Type   |   Description |
+===========+========+===============+
| source_id | int4   |               |
+-----------+--------+---------------+
| target_id | int4   |               |
+-----------+--------+---------------+


.. _relation.type:

type
````



+-------------+-----------------------+---------------+
| Name        | Type                  |   Description |
+=============+=======================+===============+
| name        | varchar               |               |
+-------------+-----------------------+---------------+
| cardinality | type_cardinality_enum |               |
+-------------+-----------------------+---------------+
| group_id    | int4                  |               |
+-------------+-----------------------+---------------+
| id          | int4                  |               |
+-------------+-----------------------+---------------+


.. _relation.all_tables:

all_tables
``````````



+-----------+--------+---------------+
| Name      | Type   |   Description |
+===========+========+===============+
| source_id | int4   |               |
+-----------+--------+---------------+
| target_id | int4   |               |
+-----------+--------+---------------+

Functions
---------

+--------------------------------------------------------------------------------------------------+---------------+---------------+
| Name                                                                                             | Return Type   | Description   |
+==================================================================================================+===============+===============+
| :ref:`create_relation_table(text)<relation.create_relation_table(text)>`                         | void          |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`get_type(character varying)<relation.get_type(character varying)>`                         | relation.type |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`create_type(character varying)<relation.create_type(character varying)>`                   | relation.type |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`update(relation.type, text)<relation.update(relation.type, text)>`                         | relation.type |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`set_view_permissions(relation.type)<relation.set_view_permissions(relation.type)>`         | relation.type |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`define(char[], text)<relation.define(char[], text)>`                                       | relation.type |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`define_reverse(char[], relation.type)<relation.define_reverse(char[], relation.type)>`     | relation.type |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`create_all_materialized(char[])<relation.create_all_materialized(char[])>`                 | name          |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`create_all_materialized_indexes(char[])<relation.create_all_materialized_indexes(char[])>` | name          |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`populate_all_materialized(char[])<relation.populate_all_materialized(char[])>`             | name          |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`update_all_materialized(char[])<relation.update_all_materialized(char[])>`                 | name          |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`update_all_materialized()<relation.update_all_materialized()>`                             | name          |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`create_relation_table_on_insert()<relation.create_relation_table_on_insert()>`             | trigger       |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`name_to_type(character varying)<relation.name_to_type(character varying)>`                 | relation.type |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`define_reverse(char[], char[])<relation.define_reverse(char[], char[])>`                   | relation.type |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`materialize(relation.type)<relation.materialize(relation.type)>`                           | integer       |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`replace_all_materialized(char[])<relation.replace_all_materialized(char[])>`               | name          |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`drop_table_on_type_delete()<relation.drop_table_on_type_delete()>`                         | trigger       |               |
+--------------------------------------------------------------------------------------------------+---------------+---------------+

.. _relation.create_relation_table(text):

create_relation_table(text) -> void
```````````````````````````````````


.. _relation.get_type(character varying):

get_type(character varying) -> relation.type
````````````````````````````````````````````


.. _relation.create_type(character varying):

create_type(character varying) -> relation.type
```````````````````````````````````````````````


.. _relation.update(relation.type, text):

update(relation.type, text) -> relation.type
````````````````````````````````````````````


.. _relation.set_view_permissions(relation.type):

set_view_permissions(relation.type) -> relation.type
````````````````````````````````````````````````````


.. _relation.define(char[], text):

define(char[], text) -> relation.type
`````````````````````````````````````


.. _relation.define_reverse(char[], relation.type):

define_reverse(char[], relation.type) -> relation.type
``````````````````````````````````````````````````````


.. _relation.create_all_materialized(char[]):

create_all_materialized(char[]) -> name
```````````````````````````````````````


.. _relation.create_all_materialized_indexes(char[]):

create_all_materialized_indexes(char[]) -> name
```````````````````````````````````````````````


.. _relation.populate_all_materialized(char[]):

populate_all_materialized(char[]) -> name
`````````````````````````````````````````


.. _relation.update_all_materialized(char[]):

update_all_materialized(char[]) -> name
```````````````````````````````````````


.. _relation.update_all_materialized():

update_all_materialized() -> name
`````````````````````````````````


.. _relation.create_relation_table_on_insert():

create_relation_table_on_insert() -> trigger
````````````````````````````````````````````


.. _relation.name_to_type(character varying):

name_to_type(character varying) -> relation.type
````````````````````````````````````````````````


.. _relation.define_reverse(char[], char[]):

define_reverse(char[], char[]) -> relation.type
```````````````````````````````````````````````


.. _relation.materialize(relation.type):

materialize(relation.type) -> integer
`````````````````````````````````````


.. _relation.replace_all_materialized(char[]):

replace_all_materialized(char[]) -> name
````````````````````````````````````````


.. _relation.drop_table_on_type_delete():

drop_table_on_type_delete() -> trigger
``````````````````````````````````````


