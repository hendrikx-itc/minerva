trend
=====

Stores information with fixed interval and format, like periodic measurements.

Tables
------

.. _trend.weather_staging:

weather_staging
```````````````



+-------------+-------------+---------------+
| Name        | Type        |   Description |
+=============+=============+===============+
| entity_id   | int4        |               |
+-------------+-------------+---------------+
| timestamp   | timestamptz |               |
+-------------+-------------+---------------+
| temperature | float8      |               |
+-------------+-------------+---------------+
| modified    | timestamptz |               |
+-------------+-------------+---------------+


.. _trend.weather:

weather
```````



+-------------+-------------+---------------+
| Name        | Type        |   Description |
+=============+=============+===============+
| entity_id   | int4        |               |
+-------------+-------------+---------------+
| timestamp   | timestamptz |               |
+-------------+-------------+---------------+
| temperature | float8      |               |
+-------------+-------------+---------------+
| modified    | timestamptz |               |
+-------------+-------------+---------------+

Functions
---------

+--------+---------------+---------------+
| Name   | Return Type   | Description   |
+========+===============+===============+
+--------+---------------+---------------+

