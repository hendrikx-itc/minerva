BEGIN;

SELECT plan(2);

CREATE TYPE test_kpi_data_x AS (
    entity_id integer,
    timestamp timestamp with time zone,
    x integer
);

SELECT is(
    trigger.kpi_def_arr_from_type('public', 'test_kpi_data_x'),
    ARRAY[('x', 'integer')]::trigger.kpi_def[]
);


CREATE TYPE test_kpi_data_xyz AS (
    entity_id integer,
    timestamp timestamp with time zone,
    x integer,
    y double precision,
    z text[]
);

SELECT is(
    trigger.kpi_def_arr_from_type('public', 'test_kpi_data_xyz'),
    ARRAY[
        ('x', 'integer'),
        ('y', 'double precision'),
        ('z', 'text[]')
    ]::trigger.kpi_def[]
);

SELECT * FROM finish();
ROLLBACK;
