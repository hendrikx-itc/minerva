BEGIN;

SELECT plan(2);

SELECT attribute_directory.create_attribute_store(
    'ds',
    'entitytype',
    ARRAY[
        ('x', 'integer', 'first column'),
	('y', 'integer', 'second column'),
	('z', 'integer', 'third column')
    ]::attribute_directory.attribute_descr[]
);

SELECT attribute_directory.check_attribute_types(
        attribute_store,
	ARRAY[
	    ('x', 'bigint', 'first column changed'),
	    ('y', 'smallint', 'second column should not change')
	    ]::attribute_directory.attribute_descr[]
    )
FROM attribute_directory.attribute_store
WHERE attribute_store::text = 'ds_entitytype';

SELECT col_type_is(
    'attribute_history'::name,
    'ds_entitytype'::name,
    'x'::name,
    'pg_catalog'::name,
    'bigint'::name,
    'type has been changed upward'
    );

SELECT col_type_is(
    'attribute_history'::name,
    'ds_entitytype'::name,
    'y'::name,
    'pg_catalog'::name,
    'integer'::name,
    'type has not been changed downward'
    );


SELECT * FROM finish();
ROLLBACK;
