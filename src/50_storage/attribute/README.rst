Attribute storage schema definition
===================================

The attribute storage is built up of a set of 5 database schemas:

:attribute_directory: The catalog/directory of existing attributestores and attributes.
:attribute_base: The parent/base tables for attributestores.
:attribute_history: The tables containing the actual attribute data with full history.
:attribute_staging: The attribute staging area for fast updating of the attribute history.
:attribute: Views for the current state of all attributes.

The name of the attribute store is built from the datasource name and the
entity type name: <datasource_name>_<entitytype_name>

An attribute store is built up from the following components:

- A record in the table attribute_directory.attributestore
- Zero or more records in the table attribute_directory.attribute
- A base table in the schema attribute_base
- A table containing all data of the attribute store in schema attribute_history
- A view indicating where the data changes in the history table.


Creating an attribute store
---------------------------

Use the following function to create new attribute stores::

    attribute_directory.create_attributestore(datasource_name text, entitytype_name text, attributes attribute_descr[]) -> attributestore


Usage example::

    SELECT attribute_directory.create_attributestore(
        'example',
        'Server',
        ARRAY[
            ('name', 'varchar', ''),
            ('location', 'varchar', ''),
            ('installed', 'timestamp with time zone', '')
        ]::attribute_directory.attribute_descr[]
    );


Load data into an attribute store
---------------------------------

Use the staging table of the attribute store in the schema attribute_staging.
