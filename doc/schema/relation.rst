relation
========

Stores the actual relations between entities in dynamically created tables.

Tables
------

.. _relation.base:

base
````

This table is used as the parent/base table for all relation tables and
therefore can be queried to include all relations of all types.

+-----------+--------+---------------+
| Name      | Type   |   Description |
+===========+========+===============+
| source_id | int4   |               |
+-----------+--------+---------------+
| target_id | int4   |               |
+-----------+--------+---------------+


.. _relation.self:

self
````



+-----------+--------+---------------+
| Name      | Type   |   Description |
+===========+========+===============+
| source_id | int4   |               |
+-----------+--------+---------------+
| target_id | int4   |               |
+-----------+--------+---------------+

Functions
---------

+--------+---------------+---------------+
| Name   | Return Type   | Description   |
+========+===============+===============+
+--------+---------------+---------------+

