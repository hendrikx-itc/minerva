Storage Class 'attribute'
=========================

The attribute storage class stores attributes of entities and their history of changes. An attribute, sometimes called property, ascribes a characteristic to an entity. Examples of attributes are:

- 'height' - with possible values like 1.89, 1.54, 2.04 or 1.56
- 'state' - with possible values 'enabled' or 'disabled'
- 'status' - with possible values 'new', 'planned', 'in-service' or 'decomissioned'

Attributes are grouped by their originating datasource and entitytype. Such a combination of datasource, entitytype and attributes is called an 'attribute store'.

Attribute
---------

An attribute is represented by a record in the attribute table and has its own unique identifier.

Attribute Store
---------------

An attribute store is represented in the database in the form of a record in the attributestore table and set of tables, views and functions working together:

- a base table defining the attribute columns and their types
- a history table inherited from the base table
- a staging table inherited from the base table
- a view with new records in the staging table.
- a view with modified records in the staging table.
- a changes view on the history table
- a view with only the current set of attributes for each entity

An example attribute store for 'Node' entities from the 'CMDB' datasource would be formed by the following combination of database objects:


+----------+-----------------------------+
| type     | name                        |
+----------+-----------------------------+
| table    | CMDB_Node                   |
| table    | CMDB_Node_history           |
| table    | CMDB_Node_staging           |
| view     | CMDB_Node_staging_new       |
| view     | CMDB_Node_staging_modified  |
| view     | CMDB_Node_history_changes   |
| view     | CMDB_Node_curr              |
+----------+-----------------------------+

Schema
------

Functions


