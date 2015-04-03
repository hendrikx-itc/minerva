CREATE FUNCTION notification_directory.notification_store_schema()
    RETURNS name
AS $$
    SELECT 'notification'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION notification_directory.to_char(notification_directory.notification_store)
    RETURNS text
AS $$
    SELECT data_source.name
    FROM directory.data_source
    WHERE data_source.id = $1.data_source_id;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION notification_directory.get_notification_store(data_source_name name)
    RETURNS notification_directory.notification_store
AS $$
    SELECT ns
    FROM notification_directory.notification_store ns
    JOIN directory.data_source ds ON ds.id = ns.data_source_id
    WHERE ds.name = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION notification_directory.table_name(notification_directory.notification_store)
    RETURNS name
AS $$
    SELECT name::name
    FROM directory.data_source
    WHERE id = $1.data_source_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION notification_directory.staging_table_name(notification_directory.notification_store)
    RETURNS name
AS $$
    SELECT (notification_directory.table_name($1) || '_staging')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION notification_directory.create_table_sql(notification_directory.notification_store)
    RETURNS text[]
AS $$
    SELECT ARRAY[
        format(
            'CREATE TABLE %I.%I ('
            '  id serial PRIMARY KEY,'
            '  entity_id integer NOT NULL,'
            '  "timestamp" timestamp with time zone NOT NULL'
            '%s'
            ');',
            notification_directory.notification_store_schema(),
            notification_directory.table_name($1),
            (SELECT array_to_string(array_agg(format(',%I %s', name, data_type)), ' ') FROM notification_directory.attribute WHERE notification_store_id = $1.id)
        ),
        format(
            'ALTER TABLE %I.%I OWNER TO minerva_writer;',
            notification_directory.notification_store_schema(),
            notification_directory.table_name($1)
        ),
        format(
            'GRANT SELECT ON TABLE %I.%I TO minerva;',
            notification_directory.notification_store_schema(),
            notification_directory.table_name($1)
        ),
        format(
            'GRANT INSERT,DELETE,UPDATE '
            'ON TABLE %I.%I TO minerva_writer;',
            notification_directory.notification_store_schema(),
            notification_directory.table_name($1)
        ),
        format(
            'CREATE INDEX %I ON %I.%I USING btree (timestamp);',
            'idx_notification_' || notification_directory.table_name($1) || '_timestamp',
            notification_directory.notification_store_schema(),
            notification_directory.table_name($1)
        )
    ];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION notification_directory.create_table(notification_directory.notification_store)
    RETURNS notification_directory.notification_store
AS $$
    SELECT public.action($1, notification_directory.create_table_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.initialize_notification_store(notification_directory.notification_store)
    RETURNS notification_directory.notification_store
AS $$
    SELECT notification_directory.create_table($1);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.create_staging_table_sql(notification_directory.notification_store)
    RETURNS text[]
AS $$
    SELECT ARRAY[
        format(
            'CREATE UNLOGGED TABLE %I.%I ('
            '  entity_id integer NOT NULL,'
            '  "timestamp" timestamp with time zone NOT NULL'
            ');',
            notification_directory.notification_store_schema(),
            notification_directory.staging_table_name($1)
        ),
        format(
            'ALTER TABLE %I.%I OWNER TO minerva_writer;',
            notification_directory.notification_store_schema(),
            notification_directory.staging_table_name($1)
        ),
        format(
            'GRANT SELECT ON TABLE %I.%I TO minerva;',
            notification_directory.notification_store_schema(),
            notification_directory.staging_table_name($1)
        ),
        format(
            'GRANT INSERT,DELETE,UPDATE '
            'ON TABLE %I.%I TO minerva_writer;',
            notification_directory.notification_store_schema(),
            notification_directory.staging_table_name($1)
        )
    ];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION notification_directory.create_staging_table(notification_directory.notification_store)
    RETURNS notification_directory.notification_store
AS $$
    SELECT public.action($1, notification_directory.create_staging_table_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.define_attribute(notification_directory.notification_store, name, name, text)
    RETURNS SETOF notification_directory.attribute
AS $$
    INSERT INTO notification_directory.attribute(notification_store_id, name, data_type, description)
    VALUES($1.id, $2, $3, $4) RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.define_attributes(
        notification_directory.notification_store,
        notification_directory.attr_def[])
    RETURNS notification_directory.notification_store
AS $$
    SELECT notification_directory.define_attribute($1, name, data_type, description)
    FROM unnest($2);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.define_notification_store(data_source_id integer)
    RETURNS notification_directory.notification_store
AS $$
    INSERT INTO notification_directory.notification_store(data_source_id)
    VALUES ($1)
    RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.define_notification_store(data_source_id integer, notification_directory.attr_def[])
    RETURNS notification_directory.notification_store
AS $$
    SELECT notification_directory.define_attributes(
        notification_directory.define_notification_store($1),
        $2
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.create_notification_store(data_source_id integer, notification_directory.attr_def[])
    RETURNS notification_directory.notification_store
AS $$
    SELECT notification_directory.initialize_notification_store(
        notification_directory.define_notification_store($1, $2)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.create_notification_store(data_source_name text, notification_directory.attr_def[])
    RETURNS notification_directory.notification_store
AS $$
    SELECT notification_directory.create_notification_store(
        (directory.name_to_data_source($1)).id, $2
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.create_notification_store(data_source_id integer)
    RETURNS notification_directory.notification_store
AS $$
    SELECT notification_directory.create_notification_store(
        $1, ARRAY[]::notification_directory.attr_def[]
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.create_notification_store(data_source_name text)
    RETURNS notification_directory.notification_store
AS $$
    SELECT notification_directory.create_notification_store(
        (directory.name_to_data_source($1)).id
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.define_notification_set_store(name name, notification_store_id integer)
    RETURNS notification_directory.notification_set_store
AS $$
    INSERT INTO notification_directory.notification_set_store(name, notification_store_id)
    VALUES ($1, $2)
    RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.notification_store(notification_directory.notification_set_store)
    RETURNS notification_directory.notification_store
AS $$
    SELECT notification_store FROM notification_directory.notification_store WHERE id = $1.notification_store_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION notification_directory.init_notification_set_store(notification_directory.notification_set_store)
    RETURNS notification_directory.notification_set_store
AS $$
BEGIN
    EXECUTE format(
        'CREATE TABLE %I.%I('
        '  id serial PRIMARY KEY'
        ')',
        notification_directory.notification_store_schema(),
        $1.name
    );

    EXECUTE format(
        'CREATE TABLE %I.%I('
        '  notification_id integer REFERENCES %I.%I ON DELETE CASCADE,'
        '  set_id integer REFERENCES %I.%I ON DELETE CASCADE'
        ')',
        notification_directory.notification_store_schema(),
        $1.name || '_link',
        notification_directory.notification_store_schema(),
        notification_directory.table_name(notification_directory.notification_store($1)),
        notification_directory.notification_store_schema(),
        $1.name
    );

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION notification_directory.create_notification_set_store(name name, notification_store_id integer)
    RETURNS notification_directory.notification_set_store
AS $$
    SELECT notification_directory.init_notification_set_store(
        notification_directory.define_notification_set_store($1, $2)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.create_notification_set_store(name name, notification_directory.notification_store)
    RETURNS notification_directory.notification_set_store
AS $$
    SELECT notification_directory.create_notification_set_store($1, $2.id);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.get_column_type_name(namespace_name name, table_name name, column_name name)
    RETURNS name
AS $$
    SELECT typname
    FROM pg_type
    JOIN pg_attribute ON pg_attribute.atttypid = pg_type.oid
    JOIN pg_class ON pg_class.oid = pg_attribute.attrelid
    JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE nspname = $1 AND relname = $2 AND typname = $3 AND attnum > 0 AND not pg_attribute.attisdropped;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION notification_directory.get_column_type_name(notification_directory.notification_store, name)
    RETURNS name
AS $$
    SELECT notification_directory.get_column_type_name(
        notification_directory.notification_store_schema(),
        notification_directory.table_name($1),
        $2
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION notification_directory.add_attribute_column_sql(name, notification_directory.attribute)
    RETURNS text
AS $$
    SELECT format(
        'ALTER TABLE %I.%I ADD COLUMN %I %s',
        notification_directory.notification_store_schema(),
        $1, $2.name, $2.data_type
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION notification_directory.add_staging_attribute_column_sql(notification_directory.attribute)
    RETURNS text
AS $$
    SELECT
        format(
            'ALTER TABLE %I.%I ADD COLUMN %I %s',
            notification_directory.notification_store_schema(),
            notification_directory.staging_table_name(notification_store), $1.name, $1.data_type
        )
    FROM notification_directory.notification_store WHERE id = $1.notification_store_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION notification_directory.create_attribute_column(notification_directory.attribute)
    RETURNS notification_directory.attribute
AS $$
SELECT
    public.action(
        $1,
        notification_directory.add_attribute_column_sql(
            notification_directory.table_name(notification_store),
            $1
        )
    )
FROM notification_directory.notification_store WHERE id = $1.notification_store_id;

SELECT
    public.action(
        $1,
        notification_directory.add_attribute_column_sql(
            notification_directory.staging_table_name(notification_store),
            $1
        )
    )
FROM notification_directory.notification_store WHERE id = $1.notification_store_id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION notification_directory.get_attr_defs(notification_directory.notification_store)
    RETURNS SETOF notification_directory.attr_def AS
$$
    SELECT (attname, typname, '')::notification_directory.attr_def
    FROM pg_type
    JOIN pg_attribute ON pg_attribute.atttypid = pg_type.oid
    JOIN pg_class ON pg_class.oid = pg_attribute.attrelid
    JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE
    nspname = notification_directory.notification_store_schema() AND
    relname = notification_directory.table_name($1) AND
    attnum > 0 AND
    NOT attname IN ('id', 'entity_id', 'timestamp') AND
    NOT pg_attribute.attisdropped;
$$ LANGUAGE sql STABLE;
