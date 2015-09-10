attribute_history
=================

Contains tables with the actual data of attribute stores

Tables
------

.. _attribute_history.existence_HandoverRelation:

existence_HandoverRelation
``````````````````````````



+------------------+--------------------------+---------------+
| Name             | Type                     |   Description |
+==================+==========================+===============+
| entity_id        | integer                  |               |
+------------------+--------------------------+---------------+
| timestamp        | timestamp with time zone |               |
+------------------+--------------------------+---------------+
| exists           | boolean                  |               |
+------------------+--------------------------+---------------+
| first_appearance | timestamp with time zone |               |
+------------------+--------------------------+---------------+
| modified         | timestamp with time zone |               |
+------------------+--------------------------+---------------+
| hash             | character varying        |               |
+------------------+--------------------------+---------------+


.. _attribute_history.existence_HandoverRelation_compacted_tmp:

existence_HandoverRelation_compacted_tmp
````````````````````````````````````````



+-----------+--------------------------+---------------+
| Name      | Type                     |   Description |
+===========+==========================+===============+
| entity_id | integer                  |               |
+-----------+--------------------------+---------------+
| timestamp | timestamp with time zone |               |
+-----------+--------------------------+---------------+
| exists    | boolean                  |               |
+-----------+--------------------------+---------------+
| end       | timestamp with time zone |               |
+-----------+--------------------------+---------------+
| modified  | timestamp with time zone |               |
+-----------+--------------------------+---------------+
| hash      | text                     |               |
+-----------+--------------------------+---------------+


.. _attribute_history.existence_HandoverRelation_curr_ptr:

existence_HandoverRelation_curr_ptr
```````````````````````````````````



+-----------+--------------------------+---------------+
| Name      | Type                     |   Description |
+===========+==========================+===============+
| entity_id | integer                  |               |
+-----------+--------------------------+---------------+
| timestamp | timestamp with time zone |               |
+-----------+--------------------------+---------------+

Functions
---------

+--------------------------------------------------------------------------------+----------------------------------------------------------------+---------------+
| Name                                                                           | Return Type                                                    | Description   |
+================================================================================+================================================================+===============+
| existence_HandoverRelation_at(timestamp with time zone)                        | SETOF attribute_history."existence_HandoverRelation"           |               |
+--------------------------------------------------------------------------------+----------------------------------------------------------------+---------------+
| existence_HandoverRelation_at(entity_id integer, timestamp with time zone)     | attribute_history."existence_HandoverRelation"                 |               |
+--------------------------------------------------------------------------------+----------------------------------------------------------------+---------------+
| existence_HandoverRelation_at_ptr(timestamp with time zone)                    | TABLE(entity_id integer, "timestamp" timestamp with time zone) |               |
+--------------------------------------------------------------------------------+----------------------------------------------------------------+---------------+
| existence_HandoverRelation_at_ptr(entity_id integer, timestamp with time zone) | timestamp with time zone                                       |               |
+--------------------------------------------------------------------------------+----------------------------------------------------------------+---------------+
| mark_modified_1()                                                              | trigger                                                        |               |
+--------------------------------------------------------------------------------+----------------------------------------------------------------+---------------+
| values_hash(attribute_history."existence_HandoverRelation")                    | text                                                           |               |
+--------------------------------------------------------------------------------+----------------------------------------------------------------+---------------+

.. _attribute_history.existence_HandoverRelation_at(timestamp with time zone):

existence_HandoverRelation_at(timestamp with time zone) -> SETOF attribute_history."existence_HandoverRelation"
```````````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _attribute_history.existence_HandoverRelation_at(entity_id integer, timestamp with time zone):

existence_HandoverRelation_at(entity_id integer, timestamp with time zone) -> attribute_history."existence_HandoverRelation"
````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _attribute_history.existence_HandoverRelation_at_ptr(timestamp with time zone):

existence_HandoverRelation_at_ptr(timestamp with time zone) -> TABLE(entity_id integer, "timestamp" timestamp with time zone)
`````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _attribute_history.existence_HandoverRelation_at_ptr(entity_id integer, timestamp with time zone):

existence_HandoverRelation_at_ptr(entity_id integer, timestamp with time zone) -> timestamp with time zone
``````````````````````````````````````````````````````````````````````````````````````````````````````````


.. _attribute_history.mark_modified_1():

mark_modified_1() -> trigger
````````````````````````````


.. _attribute_history.values_hash(attribute_history."existence_HandoverRelation"):

values_hash(attribute_history."existence_HandoverRelation") -> text
```````````````````````````````````````````````````````````````````


