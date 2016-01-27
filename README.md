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

