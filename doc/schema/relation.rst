relation
========

Stores directional relations between entities.

Tables
------

.. _relation.Cell->HandoverRelation:

Cell->HandoverRelation
``````````````````````



+-----------+---------+---------------+
| Name      | Type    |   Description |
+===========+=========+===============+
| source_id | integer |               |
+-----------+---------+---------------+
| target_id | integer |               |
+-----------+---------+---------------+
| type_id   | integer |               |
+-----------+---------+---------------+


.. _relation.HandoverRelation->Cell:

HandoverRelation->Cell
``````````````````````



+-----------+---------+---------------+
| Name      | Type    |   Description |
+===========+=========+===============+
| source_id | integer |               |
+-----------+---------+---------------+
| target_id | integer |               |
+-----------+---------+---------------+
| type_id   | integer |               |
+-----------+---------+---------------+


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
| id     | integer           |               |
+--------+-------------------+---------------+
| name   | character varying |               |
+--------+-------------------+---------------+


.. _relation.real_handover:

real_handover
`````````````



+-----------+---------+---------------+
| Name      | Type    |   Description |
+===========+=========+===============+
| source_id | integer |               |
+-----------+---------+---------------+
| target_id | integer |               |
+-----------+---------+---------------+
| type_id   | integer |               |
+-----------+---------+---------------+


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
| id          | integer                        |               |
+-------------+--------------------------------+---------------+
| name        | character varying              |               |
+-------------+--------------------------------+---------------+
| cardinality | relation.type_cardinality_enum |               |
+-------------+--------------------------------+---------------+
| group_id    | integer                        |               |
+-------------+--------------------------------+---------------+

Functions
---------

+------------------------------------------------------+---------------+---------------+
| Name                                                 | Return Type   | Description   |
+======================================================+===============+===============+
| create_all_materialized(name)                        | name          |               |
+------------------------------------------------------+---------------+---------------+
| create_all_materialized_indexes(name)                | name          |               |
+------------------------------------------------------+---------------+---------------+
| create_relation_table(name text, type_id integer)    | void          |               |
+------------------------------------------------------+---------------+---------------+
| create_relation_table_on_insert()                    | trigger       |               |
+------------------------------------------------------+---------------+---------------+
| create_self_relation()                               | trigger       |               |
+------------------------------------------------------+---------------+---------------+
| create_type(character varying)                       | relation.type |               |
+------------------------------------------------------+---------------+---------------+
| define(name, text)                                   | relation.type |               |
+------------------------------------------------------+---------------+---------------+
| define_reverse(reverse name, original relation.type) | relation.type |               |
+------------------------------------------------------+---------------+---------------+
| define_reverse(reverse name, original name)          | relation.type |               |
+------------------------------------------------------+---------------+---------------+
| drop_table_on_type_delete()                          | trigger       |               |
+------------------------------------------------------+---------------+---------------+
| get_type(character varying)                          | relation.type |               |
+------------------------------------------------------+---------------+---------------+
| materialize_relation(type relation.type)             | integer       |               |
+------------------------------------------------------+---------------+---------------+
| name_to_type(character varying)                      | relation.type |               |
+------------------------------------------------------+---------------+---------------+
| populate_all_materialized(name)                      | name          |               |
+------------------------------------------------------+---------------+---------------+
| replace_all_materialized(name)                       | name          |               |
+------------------------------------------------------+---------------+---------------+
| set_view_permissions(relation.type)                  | relation.type |               |
+------------------------------------------------------+---------------+---------------+
| update(relation.type, text)                          | relation.type |               |
+------------------------------------------------------+---------------+---------------+
| update_all_materialized(intermediate_name name)      | name          |               |
+------------------------------------------------------+---------------+---------------+

.. _relation.create_all_materialized(name):

create_all_materialized(name) -> name
`````````````````````````````````````


.. _relation.create_all_materialized_indexes(name):

create_all_materialized_indexes(name) -> name
`````````````````````````````````````````````


.. _relation.create_relation_table(name text, type_id integer):

create_relation_table(name text, type_id integer) -> void
`````````````````````````````````````````````````````````


.. _relation.create_relation_table_on_insert():

create_relation_table_on_insert() -> trigger
````````````````````````````````````````````


.. _relation.create_self_relation():

create_self_relation() -> trigger
`````````````````````````````````


.. _relation.create_type(character varying):

create_type(character varying) -> relation.type
```````````````````````````````````````````````


.. _relation.define(name, text):

define(name, text) -> relation.type
```````````````````````````````````


.. _relation.define_reverse(reverse name, original relation.type):

define_reverse(reverse name, original relation.type) -> relation.type
`````````````````````````````````````````````````````````````````````


.. _relation.define_reverse(reverse name, original name):

define_reverse(reverse name, original name) -> relation.type
````````````````````````````````````````````````````````````


.. _relation.drop_table_on_type_delete():

drop_table_on_type_delete() -> trigger
``````````````````````````````````````


.. _relation.get_type(character varying):

get_type(character varying) -> relation.type
````````````````````````````````````````````


.. _relation.materialize_relation(type relation.type):

materialize_relation(type relation.type) -> integer
```````````````````````````````````````````````````


.. _relation.name_to_type(character varying):

name_to_type(character varying) -> relation.type
````````````````````````````````````````````````


.. _relation.populate_all_materialized(name):

populate_all_materialized(name) -> name
```````````````````````````````````````


.. _relation.replace_all_materialized(name):

replace_all_materialized(name) -> name
``````````````````````````````````````


.. _relation.set_view_permissions(relation.type):

set_view_permissions(relation.type) -> relation.type
````````````````````````````````````````````````````


.. _relation.update(relation.type, text):

update(relation.type, text) -> relation.type
````````````````````````````````````````````


.. _relation.update_all_materialized(intermediate_name name):

update_all_materialized(intermediate_name name) -> name
```````````````````````````````````````````````````````


