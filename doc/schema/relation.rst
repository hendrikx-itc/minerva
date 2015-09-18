relation
========

Stores directional relations between entities.

Types
-----
Tables
------

.. _relation.all:

all
```



+-----------+---------+---------------+
| Name      | Type    |   Description |
+===========+=========+===============+
| source_id | integer |               |
+-----------+---------+---------------+
| target_id | integer |               |
+-----------+---------+---------------+
| type_id   | integer |               |
+-----------+---------+---------------+


.. _relation.all_materialized:

all_materialized
````````````````



+-----------+---------+---------------+
| Name      | Type    |   Description |
+===========+=========+===============+
| source_id | integer |               |
+-----------+---------+---------------+
| target_id | integer |               |
+-----------+---------+---------------+
| type_id   | integer |               |
+-----------+---------+---------------+


.. _relation.group:

group
`````



+--------+-------------------+---------------+
| Name   | Type              |   Description |
+========+===================+===============+
| name   | character varying |               |
+--------+-------------------+---------------+
| id     | integer           |               |
+--------+-------------------+---------------+


.. _relation.self:

self
````



+-----------+---------+---------------+
| Name      | Type    |   Description |
+===========+=========+===============+
| source_id | integer |               |
+-----------+---------+---------------+
| target_id | integer |               |
+-----------+---------+---------------+
| type_id   | integer |               |
+-----------+---------+---------------+


.. _relation.type:

type
````



+-------------+--------------------------------+---------------+
| Name        | Type                           |   Description |
+=============+================================+===============+
| name        | character varying              |               |
+-------------+--------------------------------+---------------+
| cardinality | relation.type_cardinality_enum |               |
+-------------+--------------------------------+---------------+
| group_id    | integer                        |               |
+-------------+--------------------------------+---------------+
| id          | integer                        |               |
+-------------+--------------------------------+---------------+

Views
-----

.. _relation.dependencies:

dependencies
````````````



+--------+---------------+---------------+
| Name   | Type          |   Description |
+========+===============+===============+
| type   | relation.type |               |
+--------+---------------+---------------+
| depth  | integer       |               |
+--------+---------------+---------------+


.. _relation.materialization_order:

materialization_order
`````````````````````



+-------------+--------------------------------+---------------+
| Name        | Type                           |   Description |
+=============+================================+===============+
| id          | integer                        |               |
+-------------+--------------------------------+---------------+
| name        | character varying              |               |
+-------------+--------------------------------+---------------+
| cardinality | relation.type_cardinality_enum |               |
+-------------+--------------------------------+---------------+
| group_id    | integer                        |               |
+-------------+--------------------------------+---------------+
| depth       | integer                        |               |
+-------------+--------------------------------+---------------+

Functions
---------

+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| Name                                                                                                                           | Return Type   | Description   |
+================================================================================================================================+===============+===============+
| :ref:`create_all_materialized(char[])<relation.create_all_materialized(char[])>`                                               | char[]        |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`create_all_materialized_indexes(char[])<relation.create_all_materialized_indexes(char[])>`                               | char[]        |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`create_relation_table(name text, type_id integer)<relation.create_relation_table(name text, type_id integer)>`           | void          |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`create_relation_table_on_insert()<relation.create_relation_table_on_insert()>`                                           | trigger       |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`create_self_relation()<relation.create_self_relation()>`                                                                 | trigger       |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`create_type(character varying)<relation.create_type(character varying)>`                                                 | relation.type |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`define(char[], text)<relation.define(char[], text)>`                                                                     | relation.type |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`define_reverse(reverse char[], original char[])<relation.define_reverse(reverse char[], original char[])>`               | relation.type |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`define_reverse(reverse char[], original relation.type)<relation.define_reverse(reverse char[], original relation.type)>` | relation.type |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`drop_table_on_type_delete()<relation.drop_table_on_type_delete()>`                                                       | trigger       |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`get_type(character varying)<relation.get_type(character varying)>`                                                       | relation.type |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`materialize_relation(type relation.type)<relation.materialize_relation(type relation.type)>`                             | integer       |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`name_to_type(character varying)<relation.name_to_type(character varying)>`                                               | relation.type |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`populate_all_materialized(char[])<relation.populate_all_materialized(char[])>`                                           | char[]        |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`replace_all_materialized(char[])<relation.replace_all_materialized(char[])>`                                             | char[]        |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`set_view_permissions(relation.type)<relation.set_view_permissions(relation.type)>`                                       | relation.type |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`update(relation.type, text)<relation.update(relation.type, text)>`                                                       | relation.type |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+
| :ref:`update_all_materialized(intermediate_name char[])<relation.update_all_materialized(intermediate_name char[])>`           | char[]        |               |
+--------------------------------------------------------------------------------------------------------------------------------+---------------+---------------+

.. _relation.create_all_materialized(char[]):

create_all_materialized(char[]) -> char[]
`````````````````````````````````````````
returns: char[]



.. _relation.create_all_materialized_indexes(char[]):

create_all_materialized_indexes(char[]) -> char[]
`````````````````````````````````````````````````
returns: char[]



.. _relation.create_relation_table(name text, type_id integer):

create_relation_table(name text, type_id integer) -> void
`````````````````````````````````````````````````````````
returns: void



.. _relation.create_relation_table_on_insert():

create_relation_table_on_insert() -> trigger
````````````````````````````````````````````
returns: trigger



.. _relation.create_self_relation():

create_self_relation() -> trigger
`````````````````````````````````
returns: trigger



.. _relation.create_type(character varying):

create_type(character varying) -> relation.type
```````````````````````````````````````````````
returns: :ref:`relation.type<relation.type>`



.. _relation.define(char[], text):

define(char[], text) -> relation.type
`````````````````````````````````````
returns: :ref:`relation.type<relation.type>`



.. _relation.define_reverse(reverse char[], original char[]):

define_reverse(reverse char[], original char[]) -> relation.type
````````````````````````````````````````````````````````````````
returns: :ref:`relation.type<relation.type>`



.. _relation.define_reverse(reverse char[], original relation.type):

define_reverse(reverse char[], original relation.type) -> relation.type
```````````````````````````````````````````````````````````````````````
returns: :ref:`relation.type<relation.type>`



.. _relation.drop_table_on_type_delete():

drop_table_on_type_delete() -> trigger
``````````````````````````````````````
returns: trigger



.. _relation.get_type(character varying):

get_type(character varying) -> relation.type
````````````````````````````````````````````
returns: :ref:`relation.type<relation.type>`



.. _relation.materialize_relation(type relation.type):

materialize_relation(type relation.type) -> integer
```````````````````````````````````````````````````
returns: integer



.. _relation.name_to_type(character varying):

name_to_type(character varying) -> relation.type
````````````````````````````````````````````````
returns: :ref:`relation.type<relation.type>`



.. _relation.populate_all_materialized(char[]):

populate_all_materialized(char[]) -> char[]
```````````````````````````````````````````
returns: char[]



.. _relation.replace_all_materialized(char[]):

replace_all_materialized(char[]) -> char[]
``````````````````````````````````````````
returns: char[]



.. _relation.set_view_permissions(relation.type):

set_view_permissions(relation.type) -> relation.type
````````````````````````````````````````````````````
returns: :ref:`relation.type<relation.type>`



.. _relation.update(relation.type, text):

update(relation.type, text) -> relation.type
````````````````````````````````````````````
returns: :ref:`relation.type<relation.type>`



.. _relation.update_all_materialized(intermediate_name char[]):

update_all_materialized(intermediate_name char[]) -> char[]
```````````````````````````````````````````````````````````
returns: char[]



