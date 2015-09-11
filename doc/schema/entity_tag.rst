entity_tag
==========



Types
-----

.. _entity_tag.update_result:

update_result
`````````````



+---------------+--------+---------------+
| Name          | Type   |   Description |
+===============+========+===============+
| staged        | bigint |               |
+---------------+--------+---------------+
| tags_added    | bigint |               |
+---------------+--------+---------------+
| links_added   | bigint |               |
+---------------+--------+---------------+
| links_removed | bigint |               |
+---------------+--------+---------------+


.. _entity_tag.process_staged_links_result:

process_staged_links_result
```````````````````````````



+---------------+--------+---------------+
| Name          | Type   |   Description |
+===============+========+===============+
| tags_added    | bigint |               |
+---------------+--------+---------------+
| links_added   | bigint |               |
+---------------+--------+---------------+
| links_removed | bigint |               |
+---------------+--------+---------------+

Tables
------

.. _entity_tag.type:

type
````



+-------------+---------+---------------+
| Name        | Type    |   Description |
+=============+=========+===============+
| name        | char[]  |               |
+-------------+---------+---------------+
| taggroup_id | integer |               |
+-------------+---------+---------------+
| id          | integer |               |
+-------------+---------+---------------+


.. _entity_tag.entitytaglink_staging:

entitytaglink_staging
`````````````````````



+-------------+---------+---------------+
| Name        | Type    |   Description |
+=============+=========+===============+
| entity_id   | integer |               |
+-------------+---------+---------------+
| tag_name    | text    |               |
+-------------+---------+---------------+
| taggroup_id | integer |               |
+-------------+---------+---------------+

Views
-----

.. _entity_tag._new_tags_in_staging:

_new_tags_in_staging
````````````````````



+-------------+---------+---------------+
| Name        | Type    |   Description |
+=============+=========+===============+
| name        | text    |               |
+-------------+---------+---------------+
| taggroup_id | integer |               |
+-------------+---------+---------------+


.. _entity_tag._new_links_in_staging:

_new_links_in_staging
`````````````````````



+-----------+---------+---------------+
| Name      | Type    |   Description |
+===========+=========+===============+
| entity_id | integer |               |
+-----------+---------+---------------+
| tag_id    | integer |               |
+-----------+---------+---------------+


.. _entity_tag._obsolete_links:

_obsolete_links
```````````````



+-----------+---------+---------------+
| Name      | Type    |   Description |
+===========+=========+===============+
| entity_id | integer |               |
+-----------+---------+---------------+
| tag_id    | integer |               |
+-----------+---------+---------------+

Functions
---------

+--------------------------------------------------------------------------------------------------------------------------+----------------------------------------+---------------+
| Name                                                                                                                     | Return Type                            | Description   |
+==========================================================================================================================+========================================+===============+
| :ref:`add_new_links(add_limit integer)<entity_tag.add_new_links(add_limit integer)>`                                     | bigint                                 |               |
+--------------------------------------------------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`remove_obsolete_links()<entity_tag.remove_obsolete_links()>`                                                       | bigint                                 |               |
+--------------------------------------------------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`define(type_name char[], tag_group text, sql text)<entity_tag.define(type_name char[], tag_group text, sql text)>` | entity_tag.type                        |               |
+--------------------------------------------------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`transfer_to_staging(name char[])<entity_tag.transfer_to_staging(name char[])>`                                     | bigint                                 |               |
+--------------------------------------------------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`add_new_tags()<entity_tag.add_new_tags()>`                                                                         | bigint                                 |               |
+--------------------------------------------------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`process_staged_links(process_limit integer)<entity_tag.process_staged_links(process_limit integer)>`               | entity_tag.process_staged_links_result |               |
+--------------------------------------------------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`update(type_name char[], update_limit integer)<entity_tag.update(type_name char[], update_limit integer)>`         | entity_tag.update_result               |               |
+--------------------------------------------------------------------------------------------------------------------------+----------------------------------------+---------------+

.. _entity_tag.add_new_links(add_limit integer):

add_new_links(add_limit integer) -> bigint
``````````````````````````````````````````
returns: bigint



.. _entity_tag.remove_obsolete_links():

remove_obsolete_links() -> bigint
`````````````````````````````````
returns: bigint



.. _entity_tag.define(type_name char[], tag_group text, sql text):

define(type_name char[], tag_group text, sql text) -> entity_tag.type
`````````````````````````````````````````````````````````````````````
returns: :ref:`entity_tag.type<entity_tag.type>`



.. _entity_tag.transfer_to_staging(name char[]):

transfer_to_staging(name char[]) -> bigint
``````````````````````````````````````````
returns: bigint



.. _entity_tag.add_new_tags():

add_new_tags() -> bigint
````````````````````````
returns: bigint



.. _entity_tag.process_staged_links(process_limit integer):

process_staged_links(process_limit integer) -> entity_tag.process_staged_links_result
`````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`entity_tag.process_staged_links_result<entity_tag.process_staged_links_result>`



.. _entity_tag.update(type_name char[], update_limit integer):

update(type_name char[], update_limit integer) -> entity_tag.update_result
``````````````````````````````````````````````````````````````````````````
returns: :ref:`entity_tag.update_result<entity_tag.update_result>`



