directory
=========

Stores contextual information for the data. This includes the entities, entity_types, data_sources, etc. It is the entrypoint when looking for data.

Tables
------

.. _directory.data_source:

data_source
```````````

Describes data_sources. A data_source is used to indicate where data came from. Datasources are also used to prevent collisions between sets of data from different sources, where names can be the same, but the meaning of the data differs.

+-------------+---------+---------------+
| Name        | Type    |   Description |
+=============+=========+===============+
| name        | varchar |               |
+-------------+---------+---------------+
| description | varchar |               |
+-------------+---------+---------------+
| id          | int4    |               |
+-------------+---------+---------------+


.. _directory.entity_type:

entity_type
```````````

Stores the entity types that exist in the entity table. Entity types are also used to give context to data that is stored for entities.

+-------------+---------+---------------+
| Name        | Type    |   Description |
+=============+=========+===============+
| name        | varchar |               |
+-------------+---------+---------------+
| description | varchar |               |
+-------------+---------+---------------+
| id          | int4    |               |
+-------------+---------+---------------+


.. _directory.entity:

entity
``````

Describes entities. An entity is the base object for which the database can hold further information such as attributes, trends and notifications. All data must have a reference to an entity.

+----------------+-------------+---------------+
| Name           | Type        |   Description |
+================+=============+===============+
| created        | timestamptz |               |
+----------------+-------------+---------------+
| name           | varchar     |               |
+----------------+-------------+---------------+
| entity_type_id | int4        |               |
+----------------+-------------+---------------+
| dn             | varchar     |               |
+----------------+-------------+---------------+
| id             | int4        |               |
+----------------+-------------+---------------+


.. _directory.tag_group:

tag_group
`````````



+---------------+---------+---------------+
| Name          | Type    |   Description |
+===============+=========+===============+
| name          | varchar |               |
+---------------+---------+---------------+
| complementary | bool    |               |
+---------------+---------+---------------+
| id            | int4    |               |
+---------------+---------+---------------+


.. _directory.tag:

tag
```

Stores all tags. A tag is a simple label that can be attached to a number of object types in the database, such as entities and trends.

+--------------+---------+---------------+
| Name         | Type    |   Description |
+==============+=========+===============+
| name         | varchar |               |
+--------------+---------+---------------+
| tag_group_id | int4    |               |
+--------------+---------+---------------+
| description  | varchar |               |
+--------------+---------+---------------+
| id           | int4    |               |
+--------------+---------+---------------+


.. _directory.entity_tag_link:

entity_tag_link
```````````````



+-----------+--------+---------------+
| Name      | Type   |   Description |
+===========+========+===============+
| tag_id    | int4   |               |
+-----------+--------+---------------+
| entity_id | int4   |               |
+-----------+--------+---------------+


.. _directory.entity_tag_link_denorm:

entity_tag_link_denorm
``````````````````````



+-----------+--------+---------------+
| Name      | Type   |   Description |
+===========+========+===============+
| entity_id | int4   |               |
+-----------+--------+---------------+
| tags      | _text  |               |
+-----------+--------+---------------+
| name      | text   |               |
+-----------+--------+---------------+


.. _directory.alias_type:

alias_type
``````````



+--------+---------+---------------+
| Name   | Type    |   Description |
+========+=========+===============+
| name   | varchar |               |
+--------+---------+---------------+
| id     | int4    |               |
+--------+---------+---------------+


.. _directory.alias:

alias
`````



+-----------+---------+---------------+
| Name      | Type    |   Description |
+===========+=========+===============+
| entity_id | int4    |               |
+-----------+---------+---------------+
| name      | varchar |               |
+-----------+---------+---------------+
| type_id   | int4    |               |
+-----------+---------+---------------+

Functions
---------

+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| Name                                                                                                              | Return Type                                                     | Description   |
+===================================================================================================================+=================================================================+===============+
| :ref:`glue_dn(dn_part[])<directory.glue_dn(dn_part[])>`                                                           | text                                                            |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`dn_part_to_string(directory.dn_part)<directory.dn_part_to_string(directory.dn_part)>`                       | text                                                            |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`parent_dn_parts(dn_part[])<directory.parent_dn_parts(dn_part[])>`                                           | directory.dn_part[]                                             |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`name_to_entity_type(text)<directory.name_to_entity_type(text)>`                                             | directory.entity_type                                           |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`name_to_data_source(text)<directory.name_to_data_source(text)>`                                             | directory.data_source                                           |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`update_entity_tag_link_denorm_for_insert()<directory.update_entity_tag_link_denorm_for_insert()>`           | trigger                                                         |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`dns_to_entity_ids(text[])<directory.dns_to_entity_ids(text[])>`                                             | SETOF integer                                                   |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`tag_entity(text, text)<directory.tag_entity(text, text)>`                                                   | text                                                            |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`create entity_tag_link for new entity (func)()<directory.create entity_tag_link for new entity (func)()>`   | trigger                                                         |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`tag_entity(integer, text)<directory.tag_entity(integer, text)>`                                             | integer                                                         |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`create_data_source(text)<directory.create_data_source(text)>`                                               | directory.data_source                                           |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`array_to_dn_part(text[])<directory.array_to_dn_part(text[])>`                                               | directory.dn_part                                               |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`create alias for new entity (func)()<directory.create alias for new entity (func)()>`                       | trigger                                                         |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`entity_id(directory.entity)<directory.entity_id(directory.entity)>`                                         | integer                                                         |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`create tag for new entity_types (func)()<directory.create tag for new entity_types (func)()>`               | trigger                                                         |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`create_entity_type(text)<directory.create_entity_type(text)>`                                               | directory.entity_type                                           |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`make_c_join(integer, text, text, integer, text)<directory.make_c_join(integer, text, text, integer, text)>` | text                                                            |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`parent_dn(text)<directory.parent_dn(text)>`                                                                 | text                                                            |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`entity_type_id(directory.entity_type)<directory.entity_type_id(directory.entity_type)>`                     | integer                                                         |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`dn_to_entity(text)<directory.dn_to_entity(text)>`                                                           | directory.entity                                                |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`create_entity(text)<directory.create_entity(text)>`                                                         | directory.entity                                                |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`get_entity_by_id(integer)<directory.get_entity_by_id(integer)>`                                             | directory.entity                                                |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`create_or_replace_entity_type(text)<directory.create_or_replace_entity_type(text)>`                         | directory.entity_type                                           |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`update_denormalized_entity_tags(integer)<directory.update_denormalized_entity_tags(integer)>`               | directory.entity_tag_link_denorm                                |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`split_raw_part(text)<directory.split_raw_part(text)>`                                                       | directory.dn_part                                               |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`get_alias(integer, text)<directory.get_alias(integer, text)>`                                               | text                                                            |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`last_dn_part(dn_part[])<directory.last_dn_part(dn_part[])>`                                                 | directory.dn_part                                               |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`make_s_join(integer, text, text, text)<directory.make_s_join(integer, text, text, text)>`                   | text                                                            |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`get_entity_type(text)<directory.get_entity_type(text)>`                                                     | directory.entity_type                                           |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`explode_dn(text)<directory.explode_dn(text)>`                                                               | directory.dn_part[]                                             |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`update_entity_tag_link_denorm_for_delete()<directory.update_entity_tag_link_denorm_for_delete()>`           | trigger                                                         |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`run_minerva_query(query_part[])<directory.run_minerva_query(query_part[])>`                                 | TABLE(id integer, dn character varying, entity_type_id integer) |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`get_data_source(text)<directory.get_data_source(text)>`                                                     | directory.data_source                                           |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`compile_minerva_query(text)<directory.compile_minerva_query(text)>`                                         | text                                                            |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`compile_minerva_query(query_part[])<directory.compile_minerva_query(query_part[])>`                         | text                                                            |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+
| :ref:`get_entity_by_dn(text)<directory.get_entity_by_dn(text)>`                                                   | directory.entity                                                |               |
+-------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------+---------------+

.. _directory.glue_dn(dn_part[]):

glue_dn(dn_part[]) -> text
``````````````````````````


.. _directory.dn_part_to_string(directory.dn_part):

dn_part_to_string(directory.dn_part) -> text
````````````````````````````````````````````


.. _directory.parent_dn_parts(dn_part[]):

parent_dn_parts(dn_part[]) -> directory.dn_part[]
`````````````````````````````````````````````````


.. _directory.name_to_entity_type(text):

name_to_entity_type(text) -> directory.entity_type
``````````````````````````````````````````````````


.. _directory.name_to_data_source(text):

name_to_data_source(text) -> directory.data_source
``````````````````````````````````````````````````


.. _directory.update_entity_tag_link_denorm_for_insert():

update_entity_tag_link_denorm_for_insert() -> trigger
`````````````````````````````````````````````````````


.. _directory.dns_to_entity_ids(text[]):

dns_to_entity_ids(text[]) -> SETOF integer
``````````````````````````````````````````


.. _directory.tag_entity(text, text):

tag_entity(text, text) -> text
``````````````````````````````


.. _directory.create entity_tag_link for new entity (func)():

create entity_tag_link for new entity (func)() -> trigger
`````````````````````````````````````````````````````````


.. _directory.tag_entity(integer, text):

tag_entity(integer, text) -> integer
````````````````````````````````````


.. _directory.create_data_source(text):

create_data_source(text) -> directory.data_source
`````````````````````````````````````````````````


.. _directory.array_to_dn_part(text[]):

array_to_dn_part(text[]) -> directory.dn_part
`````````````````````````````````````````````


.. _directory.create alias for new entity (func)():

create alias for new entity (func)() -> trigger
```````````````````````````````````````````````


.. _directory.entity_id(directory.entity):

entity_id(directory.entity) -> integer
``````````````````````````````````````


.. _directory.create tag for new entity_types (func)():

create tag for new entity_types (func)() -> trigger
```````````````````````````````````````````````````


.. _directory.create_entity_type(text):

create_entity_type(text) -> directory.entity_type
`````````````````````````````````````````````````


.. _directory.make_c_join(integer, text, text, integer, text):

make_c_join(integer, text, text, integer, text) -> text
```````````````````````````````````````````````````````


.. _directory.parent_dn(text):

parent_dn(text) -> text
```````````````````````


.. _directory.entity_type_id(directory.entity_type):

entity_type_id(directory.entity_type) -> integer
````````````````````````````````````````````````


.. _directory.dn_to_entity(text):

dn_to_entity(text) -> directory.entity
``````````````````````````````````````


.. _directory.create_entity(text):

create_entity(text) -> directory.entity
```````````````````````````````````````


.. _directory.get_entity_by_id(integer):

get_entity_by_id(integer) -> directory.entity
`````````````````````````````````````````````


.. _directory.create_or_replace_entity_type(text):

create_or_replace_entity_type(text) -> directory.entity_type
````````````````````````````````````````````````````````````


.. _directory.update_denormalized_entity_tags(integer):

update_denormalized_entity_tags(integer) -> directory.entity_tag_link_denorm
````````````````````````````````````````````````````````````````````````````


.. _directory.split_raw_part(text):

split_raw_part(text) -> directory.dn_part
`````````````````````````````````````````


.. _directory.get_alias(integer, text):

get_alias(integer, text) -> text
````````````````````````````````


.. _directory.last_dn_part(dn_part[]):

last_dn_part(dn_part[]) -> directory.dn_part
````````````````````````````````````````````


.. _directory.make_s_join(integer, text, text, text):

make_s_join(integer, text, text, text) -> text
``````````````````````````````````````````````


.. _directory.get_entity_type(text):

get_entity_type(text) -> directory.entity_type
``````````````````````````````````````````````


.. _directory.explode_dn(text):

explode_dn(text) -> directory.dn_part[]
```````````````````````````````````````


.. _directory.update_entity_tag_link_denorm_for_delete():

update_entity_tag_link_denorm_for_delete() -> trigger
`````````````````````````````````````````````````````


.. _directory.run_minerva_query(query_part[]):

run_minerva_query(query_part[]) -> TABLE(id integer, dn character varying, entity_type_id integer)
``````````````````````````````````````````````````````````````````````````````````````````````````


.. _directory.get_data_source(text):

get_data_source(text) -> directory.data_source
``````````````````````````````````````````````


.. _directory.compile_minerva_query(text):

compile_minerva_query(text) -> text
```````````````````````````````````


.. _directory.compile_minerva_query(query_part[]):

compile_minerva_query(query_part[]) -> text
```````````````````````````````````````````


.. _directory.get_entity_by_dn(text):

get_entity_by_dn(text) -> directory.entity
``````````````````````````````````````````


