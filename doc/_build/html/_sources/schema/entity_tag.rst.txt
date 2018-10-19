entity_tag
==========



Tables
------

.. _entity_tag.type:

type
````



+--------------+--------+---------------+
| Name         | Type   |   Description |
+==============+========+===============+
| name         | name   |               |
+--------------+--------+---------------+
| tag_group_id | int4   |               |
+--------------+--------+---------------+
| id           | int4   |               |
+--------------+--------+---------------+


.. _entity_tag.entity_tag_link_staging:

entity_tag_link_staging
```````````````````````



+--------------+--------+---------------+
| Name         | Type   |   Description |
+==============+========+===============+
| entity_id    | int4   |               |
+--------------+--------+---------------+
| tag_name     | text   |               |
+--------------+--------+---------------+
| tag_group_id | int4   |               |
+--------------+--------+---------------+

Functions
---------

+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| Name                                                                           | Return Type                            | Description   |
+================================================================================+========================================+===============+
| :ref:`create_view_sql(char[], text)<entity_tag.create_view_sql(char[], text)>` | text[]                                 |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`define(char[], text, text)<entity_tag.define(char[], text, text)>`       | entity_tag.type                        |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`add_new_tags()<entity_tag.add_new_tags()>`                               | bigint                                 |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`create_view(char[], text)<entity_tag.create_view(char[], text)>`         | name                                   |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`transfer_to_staging(char[])<entity_tag.transfer_to_staging(char[])>`     | bigint                                 |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`add_new_links(integer)<entity_tag.add_new_links(integer)>`               | bigint                                 |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`remove_obsolete_links()<entity_tag.remove_obsolete_links()>`             | bigint                                 |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`process_staged_links(integer)<entity_tag.process_staged_links(integer)>` | entity_tag.process_staged_links_result |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`update(char[], integer)<entity_tag.update(char[], integer)>`             | entity_tag.update_result               |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+

.. _entity_tag.create_view_sql(char[], text):

create_view_sql(char[], text) -> text[]
```````````````````````````````````````


.. _entity_tag.define(char[], text, text):

define(char[], text, text) -> entity_tag.type
`````````````````````````````````````````````


.. _entity_tag.add_new_tags():

add_new_tags() -> bigint
````````````````````````


.. _entity_tag.create_view(char[], text):

create_view(char[], text) -> name
`````````````````````````````````


.. _entity_tag.transfer_to_staging(char[]):

transfer_to_staging(char[]) -> bigint
`````````````````````````````````````


.. _entity_tag.add_new_links(integer):

add_new_links(integer) -> bigint
````````````````````````````````


.. _entity_tag.remove_obsolete_links():

remove_obsolete_links() -> bigint
`````````````````````````````````


.. _entity_tag.process_staged_links(integer):

process_staged_links(integer) -> entity_tag.process_staged_links_result
```````````````````````````````````````````````````````````````````````


.. _entity_tag.update(char[], integer):

update(char[], integer) -> entity_tag.update_result
```````````````````````````````````````````````````


