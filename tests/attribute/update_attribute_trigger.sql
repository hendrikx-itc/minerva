BEGIN;

SELECT plan(21);

CALL attribute_directory.create_attribute_store(
    'ds',
    'type',
    ARRAY[
        ('x', 'integer', 'some column with integer values'),
	('y', 'integer', 'another column with integer values')
    ]::attribute_directory.attribute_descr[]
);

SELECT col_type_is(
    'attribute_history',
    'ds_type',
    'x',
    'pg_catalog',
    'integer',
    'attribute history table should have correct type'
);

SELECT col_type_is(
    'attribute_base',
    'ds_type',
    'x',
    'pg_catalog',
    'integer',
    'attribute base table should have correct type'
);

SELECT col_type_is(
    'attribute_staging',
    'ds_type',
    'x',
    'pg_catalog',
    'integer',
    'attribute staging table should have correct type'
);

SELECT col_type_is(
    'attribute_history',
    'ds_type_compacted_tmp',
    'x',
    'pg_catalog',
    'integer',
    'compacted temporary table should have correct type'
);

SELECT col_type_is(
    'attribute_staging',
    'ds_type_new',
    'x',
    'pg_catalog',
    'integer',
    'staging new view should have correct type'
);

SELECT col_type_is(
    'attribute_staging',
    'ds_type_modified',
    'x',
    'pg_catalog',
    'integer',
    'staging modified view should have correct type'
);

SELECT col_type_is(
    'attribute',
    'ds_type',
    'x',
    'pg_catalog',
    'integer',
    'attribute view should have correct type'
);

SELECT col_type_is(
    'attribute_history',
    'ds_type_compacted',
    'x',
    'pg_catalog',
    'integer',
    'compacted view should have correct type'
);

SELECT lives_ok(
    $$ UPDATE attribute_directory.attribute SET data_type = 'bigint' WHERE name = 'x'; $$,
    'Change of attribute type should be possible'
);

SELECT col_type_is(
    'attribute_history',
    'ds_type',
    'x',
    'pg_catalog',
    'bigint',
    'attribute history table should have changed type'
);

SELECT col_type_is(
    'attribute_base',
    'ds_type',
    'x',
    'pg_catalog',
    'bigint',
    'attribute base table should have changed type'
);

SELECT col_type_is(
    'attribute_staging',
    'ds_type',
    'x',
    'pg_catalog',
    'bigint',
    'attribute staging table should have changed type'
);

SELECT col_type_is(
    'attribute_history',
    'ds_type_compacted_tmp',
    'x',
    'pg_catalog',
    'bigint',
    'compacted temporary table should have changed type'
);

SELECT col_type_is(
    'attribute_staging',
    'ds_type_new',
    'x',
    'pg_catalog',
    'bigint',
    'staging new view should have changed type'
);

SELECT col_type_is(
    'attribute_staging',
    'ds_type_modified',
    'x',
    'pg_catalog',
    'bigint',
    'staging modified view should have changed type'
);

SELECT col_type_is(
    'attribute',
    'ds_type',
    'x',
    'pg_catalog',
    'bigint',
    'attribute view should have changed type'
);

SELECT col_type_is(
    'attribute_history',
    'ds_type_compacted',
    'x',
    'pg_catalog',
    'bigint',
    'compacted view should have changed type'
);


SELECT col_type_is(
    'attribute_history',
    'ds_type',
    'y',
    'pg_catalog',
    'integer',
    'attribute history table should not change type for different attribute'
);

SELECT col_type_is(
    'attribute_base',
    'ds_type',
    'y',
    'pg_catalog',
    'integer',
    'attribute base table should not change type for different attribute'
);

SELECT col_type_is(
    'attribute_staging',
    'ds_type',
    'y',
    'pg_catalog',
    'integer',
    'attribute staging table should not change type for different attribute'
);

SELECT col_type_is(
    'attribute_history',
    'ds_type_compacted_tmp',
    'y',
    'pg_catalog',
    'integer',
    'compacted temporary table should not change type for different attribute'
);


SELECT * FROM finish();
ROLLBACK;
