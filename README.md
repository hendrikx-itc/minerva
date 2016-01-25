# Minerva database interface library

This component is the Python interface to the Minerva database.

Minerva is an open-source ETL platform optimized for real-time big data processing. It relies on the advanced functionality and performance of PostgreSQL.

To access an existing Minerva instance from code, or to set up a new Minerva instance, this is the component you need to use.


## Dependencies and requirements

Minerva depends on the following software:

* postgresql-libs (at least 9.4)
* python3 (at least 3.4)
* python3-setuptools
* python3-yaml
* python3-pytz
* python3-psycopg2 (at least 2.2.1)

The PostgreSQL database server version must be at least 9.4.

Run `python2 setup.py install` inside the `python-package` directory to install Minerva.


## Minerva concepts

**Entities** represent objects. All data in Minerva is associated with an entity. Each entity belongs to an **entity type**.

Entities have any number of **aliases**. An alias is a name used to represent the entity, depending on the context.

**Data types** describe the kinds of data that can be associated with entities of a certain entity type.

Data types use a **data class**. Data classes provide the high-level behavior of data types.

The **trend** data class stores periodic data with a fixed granularity — for instance, number of requests per minute.

The **attribute** data class stores nonperiodic data — for instance, number of accounts.

The **notification** data class stores occurrences of data — for instance, a failure.

The **geospatial** data class stores nonperiodic data for a position — for instance, number of active connections at the interconnect at some coordinate.


### Partition size

The **partition size** is specified in units of time and is an important parameter for performance for large data sets. It determines the size of tables, allowing more recent data to be cached more easily.

The best partition size depends on many factors:

- the number of entities with this entity type;
- the number of trends for this granularity, entity type, and data source;
- the data access patterns of your users;
- the age of the data most often accessed;
- on the database server, disk IO performance;
- on the database server, memory available for disk caching.


### Other important objects

The **data source** is used to distinguish between data from multiple sources, where the same name can have a different meaning.

**Data packages** are used to supply your data to Minerva, grouped by timestamp, entity type and data source. Data from multiple groups cannot be in the same data package. Some data classes have additional grouping.


## Accessing an existing Minerva instance

### Example: Storing trend data

Suppose that you control two web servers. Every minute, each web server reports its request rate and error rate. In this example, the following data is stored:

Timestamp        | Entity      | Trend    | Value
---------------- | ----------- | -------- | -----:
2013-09-01 00:00 | WebServer=2 | requests |    42
2013-09-01 00:00 | WebServer=2 | errors   |     0
2013-09-01 00:00 | WebServer=3 | requests |    50
2013-09-01 00:00 | WebServer=3 | errors   |    10
2013-09-01 00:01 | WebServer=2 | requests |    68
2013-09-01 00:01 | WebServer=2 | errors   |     2
2013-09-01 00:01 | WebServer=3 | requests |    65
2013-09-01 00:01 | WebServer=3 | errors   |     5

Using the API, the data is stored in chunks ('data packages') per timestamp.


```python
from datetime import datetime

import minerva.db
from minerva.directory.helpers_v4 import dn_to_entity, name_to_datasource, \
    name_to_entitytype
from minerva.storage.trend.trendstore import TrendStore
from minerva.storage.trend.granularity import create_granularity
from minerva.storage.trend.datapackage import DataPackage

db = minerva.db.connect('postgresql://user:pass@host/minerva')

with db.cursor() as cursor:
    # dn_to_entity retrieves the entity, creating it if needed.
    entity_ws2 = dn_to_entity(cursor, 'WebServer=2')
    entity_ws3 = dn_to_entity(cursor, 'WebServer=3')

    # name_to_entitytype retrieves the entity type, creating it if needed.
    # In this case, it will already have been created by dn_to_entity.
    entity_type = name_to_entitytype(cursor, 'WebServer')

    # name_to_datasource retrieves the data source, creating it if needed.
    data_source = name_to_datasource(cursor, 'example')

    granularity = create_granularity('60')

    # The TrendStore contains all the database interface logic related to
    # trends.
    # There is one TrendStore per data source, entity type and granularity.
    trend_store = TrendStore.get(data_source, entity_type, granularity)
    if not trend_store:
        # A partition size of one day is often a reasonable default for a
        # one-minute granularity.
        partition_size = 86400

        # This is actual data; use table.
        store_type = 'table'

        trend_store = TrendStore(
            data_source, entity_type, granularity, partition_size, store_type)
        trend_store.create(cursor)

db.commit()

# DataPackages contain the trend data for a given timestamp and granularity.
# They can contain data for any number of trends and entities, but the entities
# must be of the same entity type as the TrendStore.

# Timestamps must have a time zone. They can be in local time, UTC, or a
# different time zone.

# First DataPackage, for 2013-09-01 00:00 local time
timestamp = data_source.tzinfo.localize(datetime(2013, 9, 1, 0, 0))
data_package = DataPackage(
    granularity=granularity,
    timestamp=timestamp,
    trend_names=['requests', 'errors'],
    rows=[
        (entity_ws2.id, [42, 0]),
        (entity_ws3.id, [50, 10]),
    ]
)

# Store the trend data and commit.
# store() doesn't touch the database; only run() does.
trend_store.store(data_package).run(db)

# Second DataPackage, for 2013-09-01 00:01 local time
timestamp = data_source.tzinfo.localize(datetime(2013, 9, 1, 0, 1))
data_package = DataPackage(
    granularity=granularity,
    timestamp=timestamp,
    trend_names=['requests', 'errors'],
    rows=[
        (entity_ws2.id, [68, 2]),
        (entity_ws3.id, [65, 5]),
    ]
)

trend_store.store(data_package).run(db)
```


### Example: retrieving trend data

To be written.


## Setting up a new Minerva instance

To be written.
