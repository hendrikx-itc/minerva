# Existence New

Existence tracking functionality specifically for trend based data with a
granularity of 1 day.

This specific form of existence storage is designed as a more efficient replacement for the current attribute based storage. We use a fixed interval to be able to store a sequence of boolean markers (bits) with a known offset as existence markers. A bigint column type is chosen to encode 64 days of existence information in one value:

    minerva=# select 15::bigint::bit(64);
                                   bit                                
    ------------------------------------------------------------------
     0000000000000000000000000000000000000000000000000000000000001111
    (1 row)


Here the last 4 days are marked as existing using this encoding scheme. When we add the knowledge that the first bit encodes day with timestamp 2018-07-12 00:00:

    minerva=# select * from unnest(gis.existence_to_array('2108-07-12 00:00', 115));                                                                                                                                                                          
           timestamp        | exists
    ------------------------+--------
     2108-07-12 00:00:00+02 | f
     2108-07-13 00:00:00+02 | f
     2108-07-14 00:00:00+02 | f
     2108-07-15 00:00:00+02 | f
     2108-07-16 00:00:00+02 | f
     2108-07-17 00:00:00+02 | f
     2108-07-18 00:00:00+02 | f
     2108-07-19 00:00:00+02 | f
     2108-07-20 00:00:00+02 | f
     2108-07-21 00:00:00+02 | f
     2108-07-22 00:00:00+02 | f
     2108-07-23 00:00:00+02 | f
     2108-07-24 00:00:00+02 | f
     2108-07-25 00:00:00+02 | f
     2108-07-26 00:00:00+02 | f
     2108-07-27 00:00:00+02 | f
     2108-07-28 00:00:00+02 | f
     2108-07-29 00:00:00+02 | f
     2108-07-30 00:00:00+02 | f
     2108-07-31 00:00:00+02 | f
     2108-08-01 00:00:00+02 | f
     2108-08-02 00:00:00+02 | f
     2108-08-03 00:00:00+02 | f
     2108-08-04 00:00:00+02 | f
     2108-08-05 00:00:00+02 | f
     2108-08-06 00:00:00+02 | f
     2108-08-07 00:00:00+02 | f
     2108-08-08 00:00:00+02 | f
     2108-08-09 00:00:00+02 | f
     2108-08-10 00:00:00+02 | f
     2108-08-11 00:00:00+02 | f
     2108-08-12 00:00:00+02 | f
     2108-08-13 00:00:00+02 | f
     2108-08-14 00:00:00+02 | f
     2108-08-15 00:00:00+02 | f
     2108-08-16 00:00:00+02 | f
     2108-08-17 00:00:00+02 | f
     2108-08-18 00:00:00+02 | f
     2108-08-19 00:00:00+02 | f
     2108-08-20 00:00:00+02 | f
     2108-08-21 00:00:00+02 | f
     2108-08-22 00:00:00+02 | f
     2108-08-23 00:00:00+02 | f
     2108-08-24 00:00:00+02 | f
     2108-08-25 00:00:00+02 | f
     2108-08-26 00:00:00+02 | f
     2108-08-27 00:00:00+02 | f
     2108-08-28 00:00:00+02 | f
     2108-08-29 00:00:00+02 | f
     2108-08-30 00:00:00+02 | f
     2108-08-31 00:00:00+02 | f
     2108-09-01 00:00:00+02 | f
     2108-09-02 00:00:00+02 | f
     2108-09-03 00:00:00+02 | f
     2108-09-04 00:00:00+02 | f
     2108-09-05 00:00:00+02 | f
     2108-09-06 00:00:00+02 | f
     2108-09-07 00:00:00+02 | f
     2108-09-08 00:00:00+02 | f
     2108-09-09 00:00:00+02 | f
     2108-09-10 00:00:00+02 | t
     2108-09-11 00:00:00+02 | t
     2108-09-12 00:00:00+02 | t
     2108-09-13 00:00:00+02 | t
    (64 rows)


Calling example:

    select gis.update_existence(existence_store, trendstore, '2018-09-07 00:00')
    from gis.existence_store, trend.trendstore
    where existence_store.entity_type_id = 305
    and trendstore::text = 'transform-retainability_HandoverRelation_day';


timestamp
