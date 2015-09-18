materialization
===============



Types
-----

.. _materialization.materialization_result:

materialization_result
``````````````````````



+------------------------+--------------------------+---------------+
| Name                   | Type                     |   Description |
+========================+==========================+===============+
| processed_max_modified | timestamp with time zone |               |
+------------------------+--------------------------+---------------+
| row_count              | integer                  |               |
+------------------------+--------------------------+---------------+


.. _materialization.source_fragment:

source_fragment
```````````````



+---------------+--------------------------+---------------+
| Name          | Type                     |   Description |
+===============+==========================+===============+
| trendstore_id | integer                  |               |
+---------------+--------------------------+---------------+
| timestamp     | timestamp with time zone |               |
+---------------+--------------------------+---------------+


.. _materialization.source_fragment_state:

source_fragment_state
`````````````````````



+----------+---------------------------------+---------------+
| Name     | Type                            |   Description |
+==========+=================================+===============+
| fragment | materialization.source_fragment |               |
+----------+---------------------------------+---------------+
| modified | timestamp with time zone        |               |
+----------+---------------------------------+---------------+

Tables
------

.. _materialization.group_priority:

group_priority
``````````````



+-----------+---------+---------------+
| Name      | Type    |   Description |
+===========+=========+===============+
| tag_id    | integer |               |
+-----------+---------+---------------+
| resources | integer |               |
+-----------+---------+---------------+


.. _materialization.state:

state
`````

The Id of the materialization type

+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| Name             | Type                     | Description                                                                                     |
+==================+==========================+=================================================================================================+
| type_id          | integer                  | The Id of the materialization type                                                              |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| timestamp        | timestamp with time zone | The timestamp of the materialized (materialization result) data                                 |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| max_modified     | timestamp with time zone | The greatest modified timestamp of all materialization sources                                  |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| source_states    | source_fragment_state[]  | Array of trendstore_id/timestamp/modified combinations for all source data fragments            |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| processed_states | source_fragment_state[]  | Array containing a snapshot of the source_states at the time of the most recent materialization |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| job_id           | integer                  | Id of the most recent job for this materialization                                              |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+


.. _materialization.state:

state
`````

The timestamp of the materialized (materialization result) data

+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| Name             | Type                     | Description                                                                                     |
+==================+==========================+=================================================================================================+
| type_id          | integer                  | The Id of the materialization type                                                              |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| timestamp        | timestamp with time zone | The timestamp of the materialized (materialization result) data                                 |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| max_modified     | timestamp with time zone | The greatest modified timestamp of all materialization sources                                  |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| source_states    | source_fragment_state[]  | Array of trendstore_id/timestamp/modified combinations for all source data fragments            |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| processed_states | source_fragment_state[]  | Array containing a snapshot of the source_states at the time of the most recent materialization |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| job_id           | integer                  | Id of the most recent job for this materialization                                              |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+


.. _materialization.state:

state
`````

The greatest modified timestamp of all materialization sources

+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| Name             | Type                     | Description                                                                                     |
+==================+==========================+=================================================================================================+
| type_id          | integer                  | The Id of the materialization type                                                              |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| timestamp        | timestamp with time zone | The timestamp of the materialized (materialization result) data                                 |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| max_modified     | timestamp with time zone | The greatest modified timestamp of all materialization sources                                  |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| source_states    | source_fragment_state[]  | Array of trendstore_id/timestamp/modified combinations for all source data fragments            |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| processed_states | source_fragment_state[]  | Array containing a snapshot of the source_states at the time of the most recent materialization |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| job_id           | integer                  | Id of the most recent job for this materialization                                              |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+


.. _materialization.state:

state
`````

Array of trendstore_id/timestamp/modified combinations for all source data fragments

+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| Name             | Type                     | Description                                                                                     |
+==================+==========================+=================================================================================================+
| type_id          | integer                  | The Id of the materialization type                                                              |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| timestamp        | timestamp with time zone | The timestamp of the materialized (materialization result) data                                 |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| max_modified     | timestamp with time zone | The greatest modified timestamp of all materialization sources                                  |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| source_states    | source_fragment_state[]  | Array of trendstore_id/timestamp/modified combinations for all source data fragments            |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| processed_states | source_fragment_state[]  | Array containing a snapshot of the source_states at the time of the most recent materialization |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| job_id           | integer                  | Id of the most recent job for this materialization                                              |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+


.. _materialization.state:

state
`````

Array containing a snapshot of the source_states at the time of the most recent materialization

+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| Name             | Type                     | Description                                                                                     |
+==================+==========================+=================================================================================================+
| type_id          | integer                  | The Id of the materialization type                                                              |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| timestamp        | timestamp with time zone | The timestamp of the materialized (materialization result) data                                 |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| max_modified     | timestamp with time zone | The greatest modified timestamp of all materialization sources                                  |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| source_states    | source_fragment_state[]  | Array of trendstore_id/timestamp/modified combinations for all source data fragments            |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| processed_states | source_fragment_state[]  | Array containing a snapshot of the source_states at the time of the most recent materialization |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| job_id           | integer                  | Id of the most recent job for this materialization                                              |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+


.. _materialization.state:

state
`````

Id of the most recent job for this materialization

+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| Name             | Type                     | Description                                                                                     |
+==================+==========================+=================================================================================================+
| type_id          | integer                  | The Id of the materialization type                                                              |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| timestamp        | timestamp with time zone | The timestamp of the materialized (materialization result) data                                 |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| max_modified     | timestamp with time zone | The greatest modified timestamp of all materialization sources                                  |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| source_states    | source_fragment_state[]  | Array of trendstore_id/timestamp/modified combinations for all source data fragments            |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| processed_states | source_fragment_state[]  | Array containing a snapshot of the source_states at the time of the most recent materialization |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+
| job_id           | integer                  | Id of the most recent job for this materialization                                              |
+------------------+--------------------------+-------------------------------------------------------------------------------------------------+


.. _materialization.type:

type
````

The Id of the source trendstore, which should be the Id of a view based trendstore

+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| Name                | Type     | Description                                                                                             |
+=====================+==========+=========================================================================================================+
| src_trendstore_id   | integer  | The Id of the source trendstore, which should be the Id of a view based trendstore                      |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| dst_trendstore_id   | integer  | The Id of the destination trendstore, which should be the Id of a table based trendstore                |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| processing_delay    | interval | The time after the destination timestamp before this materialization can be executed                    |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| stability_delay     | interval | The time to wait after the most recent modified timestamp before the source data is considered 'stable' |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| reprocessing_period | interval | The maximum time after the destination timestamp that the materialization is allowed to be executed     |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| id                  | integer  |                                                                                                         |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| enabled             | boolean  | Indicates if jobs should be created for this materialization (manual execution is always possible)      |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| cost                | integer  |                                                                                                         |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+


.. _materialization.type:

type
````

The Id of the destination trendstore, which should be the Id of a table based trendstore

+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| Name                | Type     | Description                                                                                             |
+=====================+==========+=========================================================================================================+
| src_trendstore_id   | integer  | The Id of the source trendstore, which should be the Id of a view based trendstore                      |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| dst_trendstore_id   | integer  | The Id of the destination trendstore, which should be the Id of a table based trendstore                |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| processing_delay    | interval | The time after the destination timestamp before this materialization can be executed                    |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| stability_delay     | interval | The time to wait after the most recent modified timestamp before the source data is considered 'stable' |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| reprocessing_period | interval | The maximum time after the destination timestamp that the materialization is allowed to be executed     |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| id                  | integer  |                                                                                                         |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| enabled             | boolean  | Indicates if jobs should be created for this materialization (manual execution is always possible)      |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| cost                | integer  |                                                                                                         |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+


.. _materialization.type:

type
````

The time after the destination timestamp before this materialization can be executed

+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| Name                | Type     | Description                                                                                             |
+=====================+==========+=========================================================================================================+
| src_trendstore_id   | integer  | The Id of the source trendstore, which should be the Id of a view based trendstore                      |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| dst_trendstore_id   | integer  | The Id of the destination trendstore, which should be the Id of a table based trendstore                |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| processing_delay    | interval | The time after the destination timestamp before this materialization can be executed                    |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| stability_delay     | interval | The time to wait after the most recent modified timestamp before the source data is considered 'stable' |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| reprocessing_period | interval | The maximum time after the destination timestamp that the materialization is allowed to be executed     |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| id                  | integer  |                                                                                                         |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| enabled             | boolean  | Indicates if jobs should be created for this materialization (manual execution is always possible)      |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| cost                | integer  |                                                                                                         |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+


.. _materialization.type:

type
````

The time to wait after the most recent modified timestamp before the source data is considered 'stable'

+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| Name                | Type     | Description                                                                                             |
+=====================+==========+=========================================================================================================+
| src_trendstore_id   | integer  | The Id of the source trendstore, which should be the Id of a view based trendstore                      |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| dst_trendstore_id   | integer  | The Id of the destination trendstore, which should be the Id of a table based trendstore                |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| processing_delay    | interval | The time after the destination timestamp before this materialization can be executed                    |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| stability_delay     | interval | The time to wait after the most recent modified timestamp before the source data is considered 'stable' |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| reprocessing_period | interval | The maximum time after the destination timestamp that the materialization is allowed to be executed     |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| id                  | integer  |                                                                                                         |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| enabled             | boolean  | Indicates if jobs should be created for this materialization (manual execution is always possible)      |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| cost                | integer  |                                                                                                         |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+


.. _materialization.type:

type
````

The maximum time after the destination timestamp that the materialization is allowed to be executed

+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| Name                | Type     | Description                                                                                             |
+=====================+==========+=========================================================================================================+
| src_trendstore_id   | integer  | The Id of the source trendstore, which should be the Id of a view based trendstore                      |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| dst_trendstore_id   | integer  | The Id of the destination trendstore, which should be the Id of a table based trendstore                |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| processing_delay    | interval | The time after the destination timestamp before this materialization can be executed                    |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| stability_delay     | interval | The time to wait after the most recent modified timestamp before the source data is considered 'stable' |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| reprocessing_period | interval | The maximum time after the destination timestamp that the materialization is allowed to be executed     |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| id                  | integer  |                                                                                                         |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| enabled             | boolean  | Indicates if jobs should be created for this materialization (manual execution is always possible)      |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| cost                | integer  |                                                                                                         |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+


.. _materialization.type:

type
````

Indicates if jobs should be created for this materialization (manual execution is always possible)

+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| Name                | Type     | Description                                                                                             |
+=====================+==========+=========================================================================================================+
| src_trendstore_id   | integer  | The Id of the source trendstore, which should be the Id of a view based trendstore                      |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| dst_trendstore_id   | integer  | The Id of the destination trendstore, which should be the Id of a table based trendstore                |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| processing_delay    | interval | The time after the destination timestamp before this materialization can be executed                    |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| stability_delay     | interval | The time to wait after the most recent modified timestamp before the source data is considered 'stable' |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| reprocessing_period | interval | The maximum time after the destination timestamp that the materialization is allowed to be executed     |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| id                  | integer  |                                                                                                         |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| enabled             | boolean  | Indicates if jobs should be created for this materialization (manual execution is always possible)      |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+
| cost                | integer  |                                                                                                         |
+---------------------+----------+---------------------------------------------------------------------------------------------------------+


.. _materialization.type_tag_link:

type_tag_link
`````````````



+---------+---------+---------------+
| Name    | Type    |   Description |
+=========+=========+===============+
| type_id | integer |               |
+---------+---------+---------------+
| tag_id  | integer |               |
+---------+---------+---------------+

Views
-----

.. _materialization.materializable_source_state:

materializable_source_state
```````````````````````````



+---------------+--------------------------+---------------+
| Name          | Type                     |   Description |
+===============+==========================+===============+
| type_id       | integer                  |               |
+---------------+--------------------------+---------------+
| timestamp     | timestamp with time zone |               |
+---------------+--------------------------+---------------+
| trendstore_id | integer                  |               |
+---------------+--------------------------+---------------+
| src_timestamp | timestamp with time zone |               |
+---------------+--------------------------+---------------+
| modified      | timestamp with time zone |               |
+---------------+--------------------------+---------------+


.. _materialization.materializables:

materializables
```````````````



+---------------+--------------------------+---------------+
| Name          | Type                     |   Description |
+===============+==========================+===============+
| type_id       | integer                  |               |
+---------------+--------------------------+---------------+
| timestamp     | timestamp with time zone |               |
+---------------+--------------------------+---------------+
| max_modified  | timestamp with time zone |               |
+---------------+--------------------------+---------------+
| source_states | source_fragment_state[]  |               |
+---------------+--------------------------+---------------+


.. _materialization.modified_materializables:

modified_materializables
````````````````````````



+---------------+--------------------------+---------------+
| Name          | Type                     |   Description |
+===============+==========================+===============+
| type_id       | integer                  |               |
+---------------+--------------------------+---------------+
| timestamp     | timestamp with time zone |               |
+---------------+--------------------------+---------------+
| max_modified  | timestamp with time zone |               |
+---------------+--------------------------+---------------+
| source_states | source_fragment_state[]  |               |
+---------------+--------------------------+---------------+


.. _materialization.new_materializables:

new_materializables
```````````````````



+---------------+--------------------------+---------------+
| Name          | Type                     |   Description |
+===============+==========================+===============+
| type_id       | integer                  |               |
+---------------+--------------------------+---------------+
| timestamp     | timestamp with time zone |               |
+---------------+--------------------------+---------------+
| max_modified  | timestamp with time zone |               |
+---------------+--------------------------+---------------+
| source_states | source_fragment_state[]  |               |
+---------------+--------------------------+---------------+


.. _materialization.next_up_materializations:

next_up_materializations
````````````````````````



+-----------------+--------------------------+---------------+
| Name            | Type                     |   Description |
+=================+==========================+===============+
| type_id         | integer                  |               |
+-----------------+--------------------------+---------------+
| timestamp       | timestamp with time zone |               |
+-----------------+--------------------------+---------------+
| name            | character varying        |               |
+-----------------+--------------------------+---------------+
| cost            | integer                  |               |
+-----------------+--------------------------+---------------+
| cumsum          | bigint                   |               |
+-----------------+--------------------------+---------------+
| group_resources | integer                  |               |
+-----------------+--------------------------+---------------+
| job_active      | boolean                  |               |
+-----------------+--------------------------+---------------+


.. _materialization.obsolete_state:

obsolete_state
``````````````



+-----------+--------------------------+---------------+
| Name      | Type                     |   Description |
+===========+==========================+===============+
| type_id   | integer                  |               |
+-----------+--------------------------+---------------+
| timestamp | timestamp with time zone |               |
+-----------+--------------------------+---------------+


.. _materialization.required_resources_by_group:

required_resources_by_group
```````````````````````````



+----------+---------+---------------+
| Name     | Type    |   Description |
+==========+=========+===============+
| tag_id   | integer |               |
+----------+---------+---------------+
| required | bigint  |               |
+----------+---------+---------------+


.. _materialization.runnable_materializations:

runnable_materializations
`````````````````````````



+--------+-----------------------+---------------+
| Name   | Type                  |   Description |
+========+=======================+===============+
| type   | materialization.type  |               |
+--------+-----------------------+---------------+
| state  | materialization.state |               |
+--------+-----------------------+---------------+


.. _materialization.tagged_runnable_materializations:

tagged_runnable_materializations
````````````````````````````````



+-----------+--------------------------+---------------+
| Name      | Type                     |   Description |
+===========+==========================+===============+
| type_id   | integer                  |               |
+-----------+--------------------------+---------------+
| timestamp | timestamp with time zone |               |
+-----------+--------------------------+---------------+
| tag       | character varying        |               |
+-----------+--------------------------+---------------+


.. _materialization.trend_ext:

trend_ext
`````````

Convenience view for easy lookup of trends

+-----------------+-------------------+---------------+
| Name            | Type              |   Description |
+=================+===================+===============+
| id              | integer           |               |
+-----------------+-------------------+---------------+
| name            | character varying |               |
+-----------------+-------------------+---------------+
| datasource_name | character varying |               |
+-----------------+-------------------+---------------+
| entitytype_name | character varying |               |
+-----------------+-------------------+---------------+
| granularity     | character varying |               |
+-----------------+-------------------+---------------+
| materialized    | boolean           |               |
+-----------------+-------------------+---------------+

Functions
---------

+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| Name                                                                                                                                                                                                                                                                    | Return Type                                 | Description                                                                                                   |
+=========================================================================================================================================================================================================================================================================+=============================================+===============================================================================================================+
| :ref:`add_missing_trends(src trend.trendstore, dst trend.trendstore)<materialization.add_missing_trends(src trend.trendstore, dst trend.trendstore)>`                                                                                                                   | bigint                                      | Add trends and actual table columns to destination that exist in the source                                   |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`add_missing_trends(materialization.type)<materialization.add_missing_trends(materialization.type)>`                                                                                                                                                               | materialization.type                        |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`add_new_state()<materialization.add_new_state()>`                                                                                                                                                                                                                 | integer                                     |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`create_job(type_id integer, timestamp timestamp with time zone)<materialization.create_job(type_id integer, timestamp timestamp with time zone)>`                                                                                                                 | integer                                     |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`create_jobs(tag character varying, job_limit integer)<materialization.create_jobs(tag character varying, job_limit integer)>`                                                                                                                                     | integer                                     |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`create_jobs(tag character varying)<materialization.create_jobs(tag character varying)>`                                                                                                                                                                           | integer                                     |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`create_jobs()<materialization.create_jobs()>`                                                                                                                                                                                                                     | integer                                     |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`create_jobs_limited(tag character varying, job_limit integer)<materialization.create_jobs_limited(tag character varying, job_limit integer)>`                                                                                                                     | integer                                     | Deprecated function that just calls the overloaded create_jobs function.                                      |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`default_processing_delay(granularity character varying)<materialization.default_processing_delay(granularity character varying)>`                                                                                                                                 | interval                                    |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`default_stability_delay(granularity character varying)<materialization.default_stability_delay(granularity character varying)>`                                                                                                                                   | interval                                    |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`define(src_trendstore_id integer, dst_trendstore_id integer)<materialization.define(src_trendstore_id integer, dst_trendstore_id integer)>`                                                                                                                       | materialization.type                        |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`define(src trend.trendstore, dst trend.trendstore)<materialization.define(src trend.trendstore, dst trend.trendstore)>`                                                                                                                                           | materialization.type                        |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`define(text, text)<materialization.define(text, text)>`                                                                                                                                                                                                           | materialization.type                        |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`define(trend.trendstore)<materialization.define(trend.trendstore)>`                                                                                                                                                                                               | materialization.type                        | Defines a new materialization with the convention that the datasource of                                      |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`define(trend.view)<materialization.define(trend.view)>`                                                                                                                                                                                                           | materialization.type                        | Defines a new materialization with the convention that the datasource of                                      |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`delete_obsolete_state()<materialization.delete_obsolete_state()>`                                                                                                                                                                                                 | integer                                     |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`dependencies(trend.trendstore, level integer)<materialization.dependencies(trend.trendstore, level integer)>`                                                                                                                                                     | TABLE(trend.trendstore, integer)            |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`dependencies(trend.trendstore)<materialization.dependencies(trend.trendstore)>`                                                                                                                                                                                   | TABLE(trend.trendstore, integer)            |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`dependencies(name text)<materialization.dependencies(name text)>`                                                                                                                                                                                                 | TABLE(trend.trendstore, integer)            |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`direct_dependencies(trend.trendstore)<materialization.direct_dependencies(trend.trendstore)>`                                                                                                                                                                     | trend.trendstore                            |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`direct_table_dependencies(trend.trendstore)<materialization.direct_table_dependencies(trend.trendstore)>`                                                                                                                                                         | trend.trendstore                            |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`direct_view_dependencies(trend.trendstore)<materialization.direct_view_dependencies(trend.trendstore)>`                                                                                                                                                           | trend.trendstore                            |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`disable(materialization.type)<materialization.disable(materialization.type)>`                                                                                                                                                                                     | materialization.type                        |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`enable(materialization.type)<materialization.enable(materialization.type)>`                                                                                                                                                                                       | materialization.type                        |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`fragments(source_fragment_state[])<materialization.fragments(source_fragment_state[])>`                                                                                                                                                                           | source_fragment[]                           |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`materialization(src text, dst text, timestamp timestamp with time zone)<materialization.materialization(src text, dst text, timestamp timestamp with time zone)>`                                                                                                 | materialization.materialization_result      |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`materialize(src trend.trendstore, dst trend.trendstore, timestamp timestamp with time zone)<materialization.materialize(src trend.trendstore, dst trend.trendstore, timestamp timestamp with time zone)>`                                                         | materialization.materialization_result      |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`materialize(src_trendstore_id integer, dst_trendstore_id integer, timestamp timestamp with time zone)<materialization.materialize(src_trendstore_id integer, dst_trendstore_id integer, timestamp timestamp with time zone)>`                                     | materialization.materialization_result      |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`materialize(materialization text, timestamp timestamp with time zone)<materialization.materialize(materialization text, timestamp timestamp with time zone)>`                                                                                                     | materialization.materialization_result      |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`materialize(materialization.type, timestamp timestamp with time zone)<materialization.materialize(materialization.type, timestamp timestamp with time zone)>`                                                                                                     | materialization.materialization_result      |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`materialize(id integer, timestamp timestamp with time zone)<materialization.materialize(id integer, timestamp timestamp with time zone)>`                                                                                                                         | materialization.materialization_result      |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`missing_columns(src trend.trendstore, dst trend.trendstore)<materialization.missing_columns(src trend.trendstore, dst trend.trendstore)>`                                                                                                                         | TABLE(character varying, character varying) | The set of table columns (name, datatype) that exist in the source trendstore but not yet in the destination. |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`missing_columns(materialization.type)<materialization.missing_columns(materialization.type)>`                                                                                                                                                                     | TABLE(character varying, character varying) |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`modify_mismatching_trends(src trend.trendstore, dst trend.trendstore)<materialization.modify_mismatching_trends(src trend.trendstore, dst trend.trendstore)>`                                                                                                     | void                                        |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`modify_mismatching_trends(materialization.type)<materialization.modify_mismatching_trends(materialization.type)>`                                                                                                                                                 | void                                        |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`no_slave_lag()<materialization.no_slave_lag()>`                                                                                                                                                                                                                   | boolean                                     |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`open_job_slots(slot_count integer)<materialization.open_job_slots(slot_count integer)>`                                                                                                                                                                           | integer                                     |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`render_job_json(type_id integer, timestamp with time zone)<materialization.render_job_json(type_id integer, timestamp with time zone)>`                                                                                                                           | character varying                           |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`requires_update(materialization.state)<materialization.requires_update(materialization.state)>`                                                                                                                                                                   | boolean                                     |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`reset(type_id integer)<materialization.reset(type_id integer)>`                                                                                                                                                                                                   | materialization.state                       |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`reset(type_id integer, timestamp with time zone)<materialization.reset(type_id integer, timestamp with time zone)>`                                                                                                                                               | materialization.state                       |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`reset(materialization.type, timestamp with time zone)<materialization.reset(materialization.type, timestamp with time zone)>`                                                                                                                                     | materialization.state                       |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`reset_hard(materialization.type)<materialization.reset_hard(materialization.type)>`                                                                                                                                                                               | void                                        | Remove data (partitions) resulting from this materialization and the                                          |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`runnable(materialization.type, materialization.state)<materialization.runnable(materialization.type, materialization.state)>`                                                                                                                                     | boolean                                     |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`runnable(type materialization.type, timestamp timestamp with time zone, max_modified timestamp with time zone)<materialization.runnable(type materialization.type, timestamp timestamp with time zone, max_modified timestamp with time zone)>`                   | boolean                                     |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`runnable_materializations(tag character varying)<materialization.runnable_materializations(tag character varying)>`                                                                                                                                               | TABLE(integer, timestamp with time zone)    | Return table with all combinations (type_id, timestamp) that are ready to                                     |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`source_data_ready(type materialization.type, timestamp timestamp with time zone, max_modified timestamp with time zone)<materialization.source_data_ready(type materialization.type, timestamp timestamp with time zone, max_modified timestamp with time zone)>` | boolean                                     |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`tag(tag_name character varying, type_id integer)<materialization.tag(tag_name character varying, type_id integer)>`                                                                                                                                               | materialization.type_tag_link               | Add tag with name tag_name to materialization type with id type_id.                                           |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`tag(tag_name character varying, materialization.type)<materialization.tag(tag_name character varying, materialization.type)>`                                                                                                                                     | materialization.type                        | Add tag with name tag_name to materialization type. The tag must already exist.                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`to_char(materialization.type)<materialization.to_char(materialization.type)>`                                                                                                                                                                                     | text                                        |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`untag(materialization.type)<materialization.untag(materialization.type)>`                                                                                                                                                                                         | materialization.type                        | Remove all tags from the materialization                                                                      |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`update_modified_state()<materialization.update_modified_state()>`                                                                                                                                                                                                 | integer                                     |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+
| :ref:`update_state()<materialization.update_state()>`                                                                                                                                                                                                                   | text                                        |                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------+---------------------------------------------------------------------------------------------------------------+

.. _materialization.add_missing_trends(src trend.trendstore, dst trend.trendstore):

add_missing_trends(src trend.trendstore, dst trend.trendstore) -> bigint
````````````````````````````````````````````````````````````````````````
returns: bigint

Add trends and actual table columns to destination that exist in the source
trendstore but not yet in the destination.

.. _materialization.add_missing_trends(materialization.type):

add_missing_trends(materialization.type) -> materialization.type
````````````````````````````````````````````````````````````````
returns: :ref:`materialization.type<materialization.type>`



.. _materialization.add_new_state():

add_new_state() -> integer
``````````````````````````
returns: integer



.. _materialization.create_job(type_id integer, timestamp timestamp with time zone):

create_job(type_id integer, timestamp timestamp with time zone) -> integer
``````````````````````````````````````````````````````````````````````````
returns: integer



.. _materialization.create_jobs(tag character varying, job_limit integer):

create_jobs(tag character varying, job_limit integer) -> integer
````````````````````````````````````````````````````````````````
returns: integer



.. _materialization.create_jobs(tag character varying):

create_jobs(tag character varying) -> integer
`````````````````````````````````````````````
returns: integer



.. _materialization.create_jobs():

create_jobs() -> integer
````````````````````````
returns: integer



.. _materialization.create_jobs_limited(tag character varying, job_limit integer):

create_jobs_limited(tag character varying, job_limit integer) -> integer
````````````````````````````````````````````````````````````````````````
returns: integer

Deprecated function that just calls the overloaded create_jobs function.

.. _materialization.default_processing_delay(granularity character varying):

default_processing_delay(granularity character varying) -> interval
```````````````````````````````````````````````````````````````````
returns: interval



.. _materialization.default_stability_delay(granularity character varying):

default_stability_delay(granularity character varying) -> interval
``````````````````````````````````````````````````````````````````
returns: interval



.. _materialization.define(src_trendstore_id integer, dst_trendstore_id integer):

define(src_trendstore_id integer, dst_trendstore_id integer) -> materialization.type
````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`materialization.type<materialization.type>`



.. _materialization.define(src trend.trendstore, dst trend.trendstore):

define(src trend.trendstore, dst trend.trendstore) -> materialization.type
``````````````````````````````````````````````````````````````````````````
returns: :ref:`materialization.type<materialization.type>`



.. _materialization.define(text, text):

define(text, text) -> materialization.type
``````````````````````````````````````````
returns: :ref:`materialization.type<materialization.type>`



.. _materialization.define(trend.trendstore):

define(trend.trendstore) -> materialization.type
````````````````````````````````````````````````
returns: :ref:`materialization.type<materialization.type>`

Defines a new materialization with the convention that the datasource of
the source trendstore should start with a 'v' for views and that the
destination trendstore has the same properties except for a datasource with a
name without the leading 'v'. A new trendstore and datasource are created if
they do not exist.

.. _materialization.define(trend.view):

define(trend.view) -> materialization.type
``````````````````````````````````````````
returns: :ref:`materialization.type<materialization.type>`

Defines a new materialization with the convention that the datasource of
the source trendstore should start with a 'v' for views and that the
destination trendstore has the same properties except for a datasource with a
name without the leading 'v'. A new trendstore and datasource are created if
they do not exist.

.. _materialization.delete_obsolete_state():

delete_obsolete_state() -> integer
``````````````````````````````````
returns: integer



.. _materialization.dependencies(trend.trendstore, level integer):

dependencies(trend.trendstore, level integer) -> TABLE(trend.trendstore, integer)
`````````````````````````````````````````````````````````````````````````````````
returns: TABLE(trend.trendstore, integer)



.. _materialization.dependencies(trend.trendstore):

dependencies(trend.trendstore) -> TABLE(trend.trendstore, integer)
``````````````````````````````````````````````````````````````````
returns: TABLE(trend.trendstore, integer)



.. _materialization.dependencies(name text):

dependencies(name text) -> TABLE(trend.trendstore, integer)
```````````````````````````````````````````````````````````
returns: TABLE(trend.trendstore, integer)



.. _materialization.direct_dependencies(trend.trendstore):

direct_dependencies(trend.trendstore) -> SETOF trend.trendstore
```````````````````````````````````````````````````````````````
returns: :ref:`trend.trendstore<trend.trendstore>`



.. _materialization.direct_table_dependencies(trend.trendstore):

direct_table_dependencies(trend.trendstore) -> SETOF trend.trendstore
`````````````````````````````````````````````````````````````````````
returns: :ref:`trend.trendstore<trend.trendstore>`



.. _materialization.direct_view_dependencies(trend.trendstore):

direct_view_dependencies(trend.trendstore) -> SETOF trend.trendstore
````````````````````````````````````````````````````````````````````
returns: :ref:`trend.trendstore<trend.trendstore>`



.. _materialization.disable(materialization.type):

disable(materialization.type) -> materialization.type
`````````````````````````````````````````````````````
returns: :ref:`materialization.type<materialization.type>`



.. _materialization.enable(materialization.type):

enable(materialization.type) -> materialization.type
````````````````````````````````````````````````````
returns: :ref:`materialization.type<materialization.type>`



.. _materialization.fragments(source_fragment_state[]):

fragments(source_fragment_state[]) -> source_fragment[]
```````````````````````````````````````````````````````
returns: source_fragment[]



.. _materialization.materialization(src text, dst text, timestamp timestamp with time zone):

materialization(src text, dst text, timestamp timestamp with time zone) -> materialization.materialization_result
`````````````````````````````````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`materialization.materialization_result<materialization.materialization_result>`



.. _materialization.materialize(src trend.trendstore, dst trend.trendstore, timestamp timestamp with time zone):

materialize(src trend.trendstore, dst trend.trendstore, timestamp timestamp with time zone) -> materialization.materialization_result
`````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`materialization.materialization_result<materialization.materialization_result>`



.. _materialization.materialize(src_trendstore_id integer, dst_trendstore_id integer, timestamp timestamp with time zone):

materialize(src_trendstore_id integer, dst_trendstore_id integer, timestamp timestamp with time zone) -> materialization.materialization_result
```````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`materialization.materialization_result<materialization.materialization_result>`



.. _materialization.materialize(materialization text, timestamp timestamp with time zone):

materialize(materialization text, timestamp timestamp with time zone) -> materialization.materialization_result
```````````````````````````````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`materialization.materialization_result<materialization.materialization_result>`



.. _materialization.materialize(materialization.type, timestamp timestamp with time zone):

materialize(materialization.type, timestamp timestamp with time zone) -> materialization.materialization_result
```````````````````````````````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`materialization.materialization_result<materialization.materialization_result>`



.. _materialization.materialize(id integer, timestamp timestamp with time zone):

materialize(id integer, timestamp timestamp with time zone) -> materialization.materialization_result
`````````````````````````````````````````````````````````````````````````````````````````````````````
returns: :ref:`materialization.materialization_result<materialization.materialization_result>`



.. _materialization.missing_columns(src trend.trendstore, dst trend.trendstore):

missing_columns(src trend.trendstore, dst trend.trendstore) -> TABLE(character varying, character varying)
``````````````````````````````````````````````````````````````````````````````````````````````````````````
returns: TABLE(character varying, character varying)

The set of table columns (name, datatype) that exist in the source trendstore but not yet in the destination.

.. _materialization.missing_columns(materialization.type):

missing_columns(materialization.type) -> TABLE(character varying, character varying)
````````````````````````````````````````````````````````````````````````````````````
returns: TABLE(character varying, character varying)



.. _materialization.modify_mismatching_trends(src trend.trendstore, dst trend.trendstore):

modify_mismatching_trends(src trend.trendstore, dst trend.trendstore) -> void
`````````````````````````````````````````````````````````````````````````````
returns: void



.. _materialization.modify_mismatching_trends(materialization.type):

modify_mismatching_trends(materialization.type) -> void
```````````````````````````````````````````````````````
returns: void



.. _materialization.no_slave_lag():

no_slave_lag() -> boolean
`````````````````````````
returns: boolean



.. _materialization.open_job_slots(slot_count integer):

open_job_slots(slot_count integer) -> integer
`````````````````````````````````````````````
returns: integer



.. _materialization.render_job_json(type_id integer, timestamp with time zone):

render_job_json(type_id integer, timestamp with time zone) -> character varying
```````````````````````````````````````````````````````````````````````````````
returns: character varying



.. _materialization.requires_update(materialization.state):

requires_update(materialization.state) -> boolean
`````````````````````````````````````````````````
returns: boolean



.. _materialization.reset(type_id integer):

reset(type_id integer) -> SETOF materialization.state
`````````````````````````````````````````````````````
returns: :ref:`materialization.state<materialization.state>`



.. _materialization.reset(type_id integer, timestamp with time zone):

reset(type_id integer, timestamp with time zone) -> materialization.state
`````````````````````````````````````````````````````````````````````````
returns: :ref:`materialization.state<materialization.state>`



.. _materialization.reset(materialization.type, timestamp with time zone):

reset(materialization.type, timestamp with time zone) -> materialization.state
``````````````````````````````````````````````````````````````````````````````
returns: :ref:`materialization.state<materialization.state>`



.. _materialization.reset_hard(materialization.type):

reset_hard(materialization.type) -> void
````````````````````````````````````````
returns: void

Remove data (partitions) resulting from this materialization and the
corresponding state records, so materialization for all timestamps can be done
again

.. _materialization.runnable(materialization.type, materialization.state):

runnable(materialization.type, materialization.state) -> boolean
````````````````````````````````````````````````````````````````
returns: boolean



.. _materialization.runnable(type materialization.type, timestamp timestamp with time zone, max_modified timestamp with time zone):

runnable(type materialization.type, timestamp timestamp with time zone, max_modified timestamp with time zone) -> boolean
`````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````
returns: boolean



.. _materialization.runnable_materializations(tag character varying):

runnable_materializations(tag character varying) -> TABLE(integer, timestamp with time zone)
````````````````````````````````````````````````````````````````````````````````````````````
returns: TABLE(integer, timestamp with time zone)

Return table with all combinations (type_id, timestamp) that are ready to
run. This includes the check between the master and slave states.

.. _materialization.source_data_ready(type materialization.type, timestamp timestamp with time zone, max_modified timestamp with time zone):

source_data_ready(type materialization.type, timestamp timestamp with time zone, max_modified timestamp with time zone) -> boolean
``````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````````
returns: boolean



.. _materialization.tag(tag_name character varying, type_id integer):

tag(tag_name character varying, type_id integer) -> materialization.type_tag_link
`````````````````````````````````````````````````````````````````````````````````
returns: :ref:`materialization.type_tag_link<materialization.type_tag_link>`

Add tag with name tag_name to materialization type with id type_id.
The tag must already exist.

.. _materialization.tag(tag_name character varying, materialization.type):

tag(tag_name character varying, materialization.type) -> materialization.type
`````````````````````````````````````````````````````````````````````````````
returns: :ref:`materialization.type<materialization.type>`

Add tag with name tag_name to materialization type. The tag must already exist.

.. _materialization.to_char(materialization.type):

to_char(materialization.type) -> text
`````````````````````````````````````
returns: text



.. _materialization.untag(materialization.type):

untag(materialization.type) -> materialization.type
```````````````````````````````````````````````````
returns: :ref:`materialization.type<materialization.type>`

Remove all tags from the materialization

.. _materialization.update_modified_state():

update_modified_state() -> integer
``````````````````````````````````
returns: integer



.. _materialization.update_state():

update_state() -> text
``````````````````````
returns: text



