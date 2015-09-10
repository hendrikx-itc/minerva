entity_tag
==========



Tables
------

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


.. _entity_tag.type:

type
````



+-------------+---------+---------------+
| Name        | Type    |   Description |
+=============+=========+===============+
| id          | integer |               |
+-------------+---------+---------------+
| name        | name    |               |
+-------------+---------+---------------+
| taggroup_id | integer |               |
+-------------+---------+---------------+

Functions
---------

+------------------------------------------------------------+----------------------------------------+---------------+
| Name                                                       | Return Type                            | Description   |
+============================================================+========================================+===============+
| add_new_links(add_limit integer)                           | bigint                                 |               |
+------------------------------------------------------------+----------------------------------------+---------------+
| add_new_tags()                                             | bigint                                 |               |
+------------------------------------------------------------+----------------------------------------+---------------+
| define(type_name name, tag_group text, sql text)           | entity_tag.type                        |               |
+------------------------------------------------------------+----------------------------------------+---------------+
| process_staged_links(process_limit integer)                | entity_tag.process_staged_links_result |               |
+------------------------------------------------------------+----------------------------------------+---------------+
| remove_obsolete_links()                                    | bigint                                 |               |
+------------------------------------------------------------+----------------------------------------+---------------+
| transfer_to_staging(name name)                             | bigint                                 |               |
+------------------------------------------------------------+----------------------------------------+---------------+
| update(type_name name, update_limit integer DEFAULT 50000) | entity_tag.update_result               |               |
+------------------------------------------------------------+----------------------------------------+---------------+

.. _entity_tag.add_new_links(add_limit integer):

add_new_links(add_limit integer) -> bigint
``````````````````````````````````````````


.. _entity_tag.add_new_tags():

add_new_tags() -> bigint
````````````````````````


.. _entity_tag.define(type_name name, tag_group text, sql text):

define(type_name name, tag_group text, sql text) -> entity_tag.type
```````````````````````````````````````````````````````````````````


.. _entity_tag.process_staged_links(process_limit integer):

process_staged_links(process_limit integer) -> entity_tag.process_staged_links_result
`````````````````````````````````````````````````````````````````````````````````````


.. _entity_tag.remove_obsolete_links():

remove_obsolete_links() -> bigint
`````````````````````````````````


.. _entity_tag.transfer_to_staging(name name):

transfer_to_staging(name name) -> bigint
````````````````````````````````````````


.. _entity_tag.update(type_name name, update_limit integer DEFAULT 50000):

update(type_name name, update_limit integer DEFAULT 50000) -> entity_tag.update_result
``````````````````````````````````````````````````````````````````````````````````````


