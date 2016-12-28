entity_tag
==========



Tables
------

.. _entity_tag.type:

type
````



+-------------+--------+---------------+
| Name        | Type   |   Description |
+=============+========+===============+
| name        | name   |               |
+-------------+--------+---------------+
| taggroup_id | int4   |               |
+-------------+--------+---------------+
| id          | int4   |               |
+-------------+--------+---------------+


.. _entity_tag.entitytaglink_staging:

entitytaglink_staging
`````````````````````



+-------------+--------+---------------+
| Name        | Type   |   Description |
+=============+========+===============+
| entity_id   | int4   |               |
+-------------+--------+---------------+
| tag_name    | text   |               |
+-------------+--------+---------------+
| taggroup_id | int4   |               |
+-------------+--------+---------------+

Functions
---------

+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| Name                                                                           | Return Type                            | Description   |
+================================================================================+========================================+===============+
| :ref:`define(char[], text, text)<entity_tag.define(char[], text, text)>`       | entity_tag.type                        |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`transfer_to_staging(char[])<entity_tag.transfer_to_staging(char[])>`     | bigint                                 |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`process_staged_links(integer)<entity_tag.process_staged_links(integer)>` | entity_tag.process_staged_links_result |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`add_new_tags()<entity_tag.add_new_tags()>`                               | bigint                                 |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`remove_obsolete_links()<entity_tag.remove_obsolete_links()>`             | bigint                                 |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`update(char[], integer)<entity_tag.update(char[], integer)>`             | entity_tag.update_result               |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+
| :ref:`add_new_links(integer)<entity_tag.add_new_links(integer)>`               | bigint                                 |               |
+--------------------------------------------------------------------------------+----------------------------------------+---------------+

.. _entity_tag.define(char[], text, text):

define(char[], text, text) -> entity_tag.type
`````````````````````````````````````````````


.. _entity_tag.transfer_to_staging(char[]):

transfer_to_staging(char[]) -> bigint
`````````````````````````````````````


.. _entity_tag.process_staged_links(integer):

process_staged_links(integer) -> entity_tag.process_staged_links_result
```````````````````````````````````````````````````````````````````````


.. _entity_tag.add_new_tags():

add_new_tags() -> bigint
````````````````````````


.. _entity_tag.remove_obsolete_links():

remove_obsolete_links() -> bigint
`````````````````````````````````


.. _entity_tag.update(char[], integer):

update(char[], integer) -> entity_tag.update_result
```````````````````````````````````````````````````


.. _entity_tag.add_new_links(integer):

add_new_links(integer) -> bigint
````````````````````````````````


