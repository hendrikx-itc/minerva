How To
======

Examples are executed on a psql prompt.

Create Entities
---------------

Before any data is stored, entities have to be created to which the data
belongs. Basic information about entities is stored in the tables
:ref:`directory.entity_type` and :ref:`directory.entity`. These tables are
automatically populated when the appropriate functions are used to create the
entities.

Create an entity using :ref:`create_entity<directory.create_entity(text)>`:

.. code-block:: psql

    minerva=# select directory.create_entity('Node=root');
                         create_entity
    -------------------------------------------------------
     (1,"2015-09-07 12:21:01.594337+00",root,2,Node=root,)

The directory.create_entity function returns a value of type :ref:`directory.entity`
and this is exactly the record you will find in the table :ref:`directory.entity`:

.. code-block:: psql

    minerva=# select * from directory.entity where id = 1;
     id |       first_appearance        | name | entitytype_id |    dn     | parent_id
    ----+-------------------------------+------+---------------+-----------+-----------
      1 | 2015-09-07 12:21:01.594337+00 | root |             2 | Node=root |

The function :ref:`create_entity<directory.create_entity(text)>`
will also define new entitytypes if required. So the previous example will
have resulted in a new record in the :ref:`directory.entity_type` table:

.. code-block:: psql

    minerva=# select * from directory.entitytype where id = 2;
     id |       name       | description
    ----+------------------+-------------
      2 | Node             |

Any required intermediate entities are also automatically created:

.. code-block:: psql

    minerva=# select directory.create_entity('Node=root,Slot=c1,Port=12');
                                 create_entity
    ------------------------------------------------------------------------
     (2,"2015-09-07 13:10:11.809796+00",12,3,"Node=root,Slot=c1,Port=12",3)

    minerva=# select * from directory.entity;
     id |       first_appearance        | name | entitytype_id |            dn             | parent_id
    ----+-------------------------------+------+---------------+---------------------------+-----------
      1 | 2015-09-07 12:21:01.594337+00 | root |             2 | Node=root                 |
      3 | 2015-09-07 13:10:11.809796+00 | c1   |             4 | Node=root,Slot=c1         |         1
      2 | 2015-09-07 13:10:11.809796+00 | 12   |             3 | Node=root,Slot=c1,Port=12 |         3

The intermediate 'Node=root,Slot=c1' entity and its type are automatically
created.


Define Data Sources
-------------------

All data about entities is linked to a data source. Data sources are used to
organize different sets of data for potentially overlapping sets of entities.
This solves the problem of having conflicting facts about entities when they
have the same name, but come from different sources and have different values
and meanings.

To create a data source, use the function
:ref:`create_datasource<directory.create_data_source(text)>`:

.. code-block:: psql

    minerva=# select directory.create_datasource('network-conf');
          create_datasource
    ------------------------------
     (2,network-conf,default,UTC)

The function returns a value of type :ref:`directory.data_source`, and is the
record inserted into the :ref:`directory.data_source` table:

.. code-block:: psql

    minerva=# select * from directory.datasource where id = 2;
     id |     name     | description | timezone
    ----+--------------+-------------+----------
      2 | network-conf | default     | UTC

Store Attributes
----------------

To store attributes of entities, you have to create one or more attribute
stores. One attribute store can hold data for exactly one entity type of one
data source. What data an attribute store can hold is reflected in the name:
<data source name>_<entity type name>

Create the attribute store
~~~~~~~~~~~~~~~~~~~~~~~~~~

Create an attribute store to hold data for the entity type 'Port' of data
source 'network-conf':

.. code-block:: psql

    minerva=# select attribute_directory.create_attributestore('network-conf', 'Port', ARRAY[('speed','integer', '')]::attribute_directory.attribute_descr[]);
     create_attributestore
    -----------------------
     (1,1,1)

Like the functions mentioned in the previous sections, this function also
returns a value of its corresponding type
:ref:`attribute_directory.attribute_store`, which is the record inserted into the
table :ref:`attribute_directory.attribute_store`:

.. code-block:: psql

    minerva=# select * from attribute_directory.attributestore where id = 2;
     id | datasource_id | entitytype_id
    ----+---------------+---------------
      1 |             1 |             1

Now this record doesn't read as easily as the records seen in the previous
sections about entities and data sources because there is no textual component
in the attributestore record. An easy way to make this more readable is by
using the to-text-cast to obtain the 'name' of the attribute store:

.. code-block:: psql

    minerva=# select attributestore::text, * from attribute_directory.attributestore where id = 1;
      attributestore   | id | datasource_id | entitytype_id
    -------------------+----+---------------+---------------
     network-conf_Port |  1 |             1 |             1

Here you can see the textual representation of the attribute store that is
used for naming the corresponding tables, functions and views of the attribute
store.

Store attribute data
~~~~~~~~~~~~~~~~~~~~

Now the attribute store is ready to hold data, add an initial value. First
insert the data into the staging table:

.. code-block:: psql

    minerva=# insert into attribute_staging."network-conf_Port"(entity_id, timestamp, speed) values (2, now(), 1000);
    INSERT 0 1

And then transfer the staged data to the history table:

.. code-block:: psql

    minerva=# select attribute_directory.transfer_staged(attributestore) from attribute_directory.attributestore where attributestore::text = 'network-conf_Port';
     transfer_staged
    -----------------
     (1,1,1)

    minerva=# select * from attribute_history."network-conf_Port";
     entity_id |           timestamp           | speed |       first_appearance        |           modified            |               hash
     -----------+-------------------------------+-------+-------------------------------+-------------------------------+----------------------------------
              2 | 2015-09-07 14:11:47.768745+00 |  1000 | 2015-09-07 14:14:51.160655+00 | 2015-09-07 14:14:51.160655+00 | a9b7ba70783b617e9998dc4dd82eb3c5

It can be difficult to script the insertion of attribute data when the entity
Id is not yet known. For this reason, there is a convenience function to
lookup the entity by its Distinguished Name, named :ref:`directory.dn_to_entity(text)`.
This function returns an existing entity or creates a new one and returns
that. Now to combine that with adding a new attribute record that updates
the 'current' state:

.. code-block:: psql

    minerva=# insert into attribute_staging."network-conf_Port"(entity_id, timestamp, speed) values ((directory.dn_to_entity('Node=root,Slot=c1,Port=12')).id, now(), 5000);
    INSERT 0 1

    minerva=# select attribute_directory.transfer_staged(attributestore) from attribute_directory.attributestore where attributestore::text = 'network-conf_Port';
     transfer_staged
    -----------------
     (2,2,3)

    minerva=# select * from attribute_history."network-conf_Port";
     entity_id |           timestamp           | speed |       first_appearance        |           modified            |               hash
    -----------+-------------------------------+-------+-------------------------------+-------------------------------+----------------------------------
             2 | 2015-09-07 14:11:47.768745+00 |  1000 | 2015-09-07 14:14:51.160655+00 | 2015-09-07 14:14:51.160655+00 | a9b7ba70783b617e9998dc4dd82eb3c5
             2 | 2015-09-07 14:27:13.738692+00 |  5000 | 2015-09-07 14:27:18.066607+00 | 2015-09-07 14:27:18.066607+00 | a35fe7f7fe8217b4369a0af4244d1fca

Store Trends
------------

Create the trend store
~~~~~~~~~~~~~~~~~~~~~~

Create a trend store to hold data for the entity type 'Port' of data source
'network-measurements' with a granularity of 15 minutes:

.. code-block:: psql

    minerva=# select trend.create_trendstore('network-measurements', 'Port', '900', ARRAY[('bytes_transferred', 'bigint', '')]::trend.trend_descr[]);
             create_trendstore
    -----------------------------------
     (1,3,3,900,21600,table,4,"1 mon")

The return value is of type `trend.trendstore` and holds the record inserted into the trend.trendstore table:

.. code-block:: psql

    minerva=# select * from trend.trendstore where id = 1;
     id | entitytype_id | datasource_id | granularity | partition_size | type  | version | retention_period
    ----+---------------+---------------+-------------+----------------+-------+---------+------------------
      1 |             3 |             3 | 900         |          21600 | table |       4 | 1 mon

By default, a trend store with a granularity of 900 seconds is partitioned
into tables with a partition size of 6 hours (21600 seconds) and has a data
retention period of 1 month.


Materialize Trend Data
----------------------

To be documented

Define Triggers
---------------

Triggers are defined in a number of steps:

1. Create a function that returns records with all KPI's, measurement values, etc that are needed to calculate the notifications for a specific timestamp.
2. Create the new rule with it's name and thresholds.
3. Define the actual rule in the form of a where-clause.
4. Set the threshold values for the defined thresholds in step 1.
5. Define the weighing function.
6. Define the notification details text.

Here, we will work out an example trigger named 'high_traffic'.

Create KPI function
~~~~~~~~~~~~~~~~~~~
This function should return all data that is required for the actual rule and
weight calculation. Before we can create this function, we need to define a
return record type:

.. literalinclude:: create_trigger_kpi_type.sql
   :language: postgres

Now we can create the actual function:

.. literalinclude:: create_trigger_kpi_function.sql
   :language: postgres

Create New Rule
~~~~~~~~~~~~~~~

The following statement defines the rule in the system.

.. code-block:: postgres

    SELECT trigger.create_rule(
        'high_traffic',
        ARRAY[
            ('max_traffic', 'bigint')
        ]::trigger.threshold_def[]
    );

Define Rule Condition
~~~~~~~~~~~~~~~~~~~~~

Now set the actual condition of the rule that defines when a record results in
a notification:

.. literalinclude:: create_trigger_set_condition.sql
   :language: postgres

Set Threshold Values
~~~~~~~~~~~~~~~~~~~~

Set the threshold values for the condition. The arguments are in the same order
as defined in the create_rule statement:

.. code-block:: postgres

    SELECT trigger_rule."high_traffic_set_thresholds"(50000);

Define Weighing Function
~~~~~~~~~~~~~~~~~~~~~~~~

The logic for determining the weight of a notification can be as complex as you
want, or as simple as a constant value. Here we choose a simple case selection:

.. code-block:: postgres

    SELECT trigger.set_weight(
        'high_traffic',
        $query$
        SELECT CASE
        WHEN $1.traffic > 1000000 THEN
            100
        WHEN $1.traffic > 500000 THEN
            50
        ELSE
            10
        END
        $query$
    );

Define Notification Details
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: postgres

    SELECT trigger.define_notification(
        'high_traffic',
        $details$
        SELECT format('traffic(%s) > max_traffic(%s)', $1.traffic, $1.max_traffic);
        $details$
    );

