CREATE FUNCTION trend_directory.base_table_schema()
    RETURNS name
AS $$
    SELECT 'trend'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION trend_directory.partition_table_schema()
    RETURNS name
AS $$
    SELECT 'trend_partition'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION trend_directory.staging_table_schema()
    RETURNS name
AS $$
    SELECT 'trend'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION trend_directory.view_schema()
    RETURNS name
AS $$
    SELECT 'trend'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION trend_directory.granularity_to_text(interval)
    RETURNS text
AS $$
    SELECT CASE $1
        WHEN '300'::interval THEN
            '5m'
        WHEN '900'::interval THEN
            'qtr'
        WHEN '1 hour'::interval THEN
            'hr'
        WHEN '12 hours'::interval THEN
            '12hr'
        WHEN '1 day'::interval THEN
            'day'
        WHEN '1 week'::interval THEN
            'wk'
        WHEN '1 month'::interval THEN
            'month'
        ELSE
            $1::text
        END;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION trend_directory.base_object_name(trend_directory.trend_store)
    RETURNS name
AS $$
    SELECT $1.name;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION trend_directory.base_table_name(trend_directory.table_trend_store)
    RETURNS name
AS $$
    SELECT trend_directory.base_object_name($1);
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION trend_directory.view_name(trend_directory.view_trend_store)
    RETURNS name
AS $$
    SELECT trend_directory.base_object_name($1);
$$ LANGUAGE sql;


CREATE FUNCTION trend_directory.to_char(trend_directory.trend_store)
    RETURNS text
AS $$
    SELECT $1.name::text;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION trend_directory.to_char(trend_directory.table_trend_store)
    RETURNS text
AS $$
    SELECT $1.name::text;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION trend_directory.to_char(trend_directory.view_trend_store)
    RETURNS text
AS $$
    SELECT $1.name::text;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION trend_directory.get_table_trend_store(
        data_source_name text, entity_type_name text,
        granularity interval)
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT ts
    FROM trend_directory.table_trend_store ts
    JOIN directory.data_source ds ON ds.id = ts.data_source_id
    JOIN directory.entity_type et ON et.id = ts.entity_type_id
    WHERE
        lower(ds.name) = lower($1) AND
        lower(et.name) = lower($2) AND
        ts.granularity = $3;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.get_view_trend_store(
        data_source_name text, entity_type_name text,
        granularity interval)
    RETURNS trend_directory.view_trend_store
AS $$
    SELECT ts
    FROM trend_directory.view_trend_store ts
    JOIN directory.data_source ds ON ds.id = ts.data_source_id
    JOIN directory.entity_type et ON et.id = ts.entity_type_id
    WHERE lower(ds.name) = lower($1) AND lower(et.name) = lower($2) AND ts.granularity = $3;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.create_base_table_sql(name text, trend_directory.trend[])
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE TABLE %I.%I ('
        'entity_id integer NOT NULL, '
        '"timestamp" timestamp with time zone NOT NULL, '
        'modified timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP, '
        '%s'
        'PRIMARY KEY (entity_id, "timestamp") '
        ');',
        trend_directory.base_table_schema(),
        name,
        (
            SELECT string_agg(format('%I %s,', t.name, t.data_type), ' ')
            FROM unnest($2) t
        )
    ),
    format(
        'GRANT SELECT ON TABLE %I.%I TO minerva;',
        trend_directory.base_table_schema(),
        name
    ),
    format(
        'GRANT INSERT,DELETE,UPDATE ON TABLE %I.%I TO minerva_writer;',
        trend_directory.base_table_schema(),
        name
    ),
    format(
        'CREATE INDEX ON %I.%I USING btree (modified);',
        trend_directory.base_table_schema(),
        name
    ),
    format(
        'CREATE INDEX ON %I.%I USING btree (timestamp);',
        trend_directory.base_table_schema(),
        name
    )
];
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION trend_directory.create_base_table(name name, trend_directory.trend[])
    RETURNS name
AS $$
    SELECT public.action($1, trend_directory.create_base_table_sql($1, $2))
$$ LANGUAGE sql VOLATILE STRICT SECURITY DEFINER;


CREATE FUNCTION trend_directory.create_base_table(trend_directory.table_trend_store, trend_directory.trend[])
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT trend_directory.create_base_table(trend_directory.base_table_name($1), $2);
    SELECT $1;
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION trend_directory.get_trend_store_trends(trend_directory.trend_store)
    RETURNS trend_directory.trend[]
AS $$
    SELECT COALESCE(array_agg(trend), ARRAY[]::trend_directory.trend[])
    FROM trend_directory.trend
    WHERE trend_store_id = $1.id
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.create_base_table(trend_directory.table_trend_store)
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT trend_directory.create_base_table(
        $1,
        trend_directory.get_trend_store_trends($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.staging_table_name(trend_directory.table_trend_store)
    RETURNS name
AS $$
    SELECT (trend_directory.base_table_name($1) || '_staging')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.create_staging_table_sql(trend_directory.table_trend_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE UNLOGGED TABLE %I.%I () INHERITS (%I.%I);',
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name($1),
        trend_directory.staging_table_schema(),
        trend_directory.base_table_name($1)
    ),
    format(
        'ALTER TABLE ONLY %I.%I ADD PRIMARY KEY (entity_id, "timestamp");',
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name($1)
    ),
    format(
        'GRANT SELECT ON TABLE %I.%I TO minerva;',
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name($1)
    ),
    format(
        'GRANT INSERT,DELETE,UPDATE ON TABLE %I.%I TO minerva_writer;',
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name($1)
    )
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.create_staging_table(trend_directory.table_trend_store)
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT public.action($1, trend_directory.create_staging_table_sql($1));
$$ LANGUAGE sql VOLATILE STRICT SECURITY DEFINER;


CREATE FUNCTION trend_directory.initialize_table_trend_store(trend_directory.table_trend_store)
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT trend_directory.create_base_table($1);
    SELECT trend_directory.create_staging_table($1);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION trend_directory.initialize_table_trend_store(trend_directory.table_trend_store) IS
'Create all database objects required for the trend store to be fully functional
and capable of storing data.';


CREATE FUNCTION trend_directory.create_view(trend_directory.trend_store, name)
    RETURNS trend_directory.trend_store
AS $$
   SELECT public.action(
        $1,
        format('CREATE VIEW trend.%I AS SELECT * FROM trend.%I', trend_directory.base_object_name($1))
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.get_default_partition_size(granularity interval)
    RETURNS integer
AS $$
    SELECT CASE $1
        WHEN '300'::interval THEN
            3 * 3600
        WHEN '900'::interval THEN
            6 * 3600
        WHEN '1800'::interval THEN
            6 * 3600
        WHEN '1 hour'::interval THEN
            24 * 3600
        WHEN '12 hours'::interval THEN
            24 * 3600 * 7
        WHEN '1 day'::interval THEN
            24 * 3600 * 7
        WHEN '1 week'::interval THEN
            24 * 3600 * 7 * 4
        WHEN '1 month'::interval THEN
            24 * 3600 * 7 * 24
        END;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION trend_directory.define_table_trend_store(
        name name, data_source_name text, entity_type_name text,
        granularity interval, partition_size integer)
    RETURNS trend_directory.table_trend_store
AS $$
    INSERT INTO trend_directory.table_trend_store (
        name,
        data_source_id,
        entity_type_id,
        granularity,
        partition_size
    )
    VALUES (
        $1,
        (directory.name_to_data_source($2)).id,
        (directory.name_to_entity_type($3)).id,
        $4,
        $5
    ) RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.define_table_trend(
        trend_store_id integer, name name, data_type text, description text)
    RETURNS trend_directory.table_trend
AS $$
    INSERT INTO trend_directory.table_trend (trend_store_id, name, data_type, description)
    VALUES ($1, $2, $3, $4)
    RETURNING table_trend;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.define_view_trend(
        trend_store_id integer, name name, data_type text, description text)
    RETURNS trend_directory.view_trend
AS $$
    INSERT INTO trend_directory.view_trend (trend_store_id, name, data_type, description)
    VALUES ($1, $2, $3, $4)
    RETURNING view_trend;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.define_view_trend_store(
        name name, data_source_name text, entity_type_name text,
        granularity interval
    )
    RETURNS trend_directory.view_trend_store
AS $$
    INSERT INTO trend_directory.view_trend_store (
        name,
        data_source_id,
        entity_type_id,
        granularity
    )
    VALUES (
        $1,
        (directory.name_to_data_source($2)).id,
        (directory.name_to_entity_type($3)).id,
        $4
    ) RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.create_view_sql(trend_directory.view_trend_store, sql text)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format('CREATE VIEW %I.%I AS %s;', trend_directory.view_schema(), trend_directory.view_name($1), $2),
    format('GRANT SELECT ON TABLE %I.%I TO minerva;', trend_directory.view_schema(), trend_directory.view_name($1))
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.get_view_trends(view_name name)
    RETURNS SETOF trend_directory.trend_descr
AS $$
    SELECT (a.attname, format_type(a.atttypid, a.atttypmod), 'deduced from view')::trend_directory.trend_descr
    FROM pg_class c
    JOIN pg_attribute a ON a.attrelid = c.oid
    WHERE c.relname = $1 AND a.attnum >= 0 AND NOT a.attisdropped;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.show_trends(trend_directory.trend_store)
    RETURNS SETOF trend_directory.trend_descr
AS $$
    SELECT
        trend.name::name,
        format_type(a.atttypid, a.atttypmod)::text,
        trend.description
    FROM trend_directory.trend
    JOIN pg_catalog.pg_class c ON c.relname = $1::text
    JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
    JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid AND a.attname = trend.name
    WHERE
        n.nspname = 'trend' AND
        a.attisdropped = false AND
        a.attnum > 0 AND trend.trend_store_id = $1.id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.create_view_trends(view trend_directory.view_trend_store)
    RETURNS SETOF trend_directory.view_trend
AS $$
    SELECT
        trend_directory.define_view_trend(
            $1.id,
            vt.name,
            vt.data_type,
            vt.description
        )
    FROM trend_directory.get_view_trends(trend_directory.view_name($1)) vt
    WHERE vt.name NOT IN ('entity_id', 'timestamp', 'modified');
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.initialize_view_trend_store(trend_directory.view_trend_store, query text)
    RETURNS trend_directory.view_trend_store
AS $$
    SELECT public.action($1, trend_directory.create_view_sql($1, $2));

    SELECT trend_directory.create_view_trends($1);

    SELECT $1;
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION trend_directory.create_view_trend_store(
        name name, data_source_name text, entity_type_name text,
        granularity interval, query text)
    RETURNS trend_directory.view_trend_store
AS $$
    SELECT trend_directory.initialize_view_trend_store(
        trend_directory.define_view_trend_store($1, $2, $3, $4), $5
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.define_table_trends(
        trend_directory.table_trend_store,
        trend_directory.trend_descr[])
    RETURNS trend_directory.table_trend_store
AS $$
    INSERT INTO trend_directory.table_trend(name, data_type, trend_store_id, description) (
        SELECT name, data_type, $1.id, description FROM unnest($2)
    );

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.define_table_trend_store(
        name name, data_source_name text, entity_type_name text,
        granularity interval, partition_size integer,
        trends trend_directory.trend_descr[])
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT trend_directory.define_table_trends(
        trend_directory.define_table_trend_store($1, $2, $3, $4, $5),
        $6
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.create_table_trend_store(
        name name, data_source_name text, entity_type_name text,
        granularity interval, partition_size integer,
        trends trend_directory.trend_descr[])
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT trend_directory.initialize_table_trend_store(
        trend_directory.define_table_trend_store($1, $2, $3, $4, $5, $6)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.create_table_trend_store(
        name name, data_source_name text, entity_type_name text,
        granularity interval, partition_size integer,
        trend_directory.view_trend_store)
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT trend_directory.create_table_trend_store(
        $1, $2, $3, $4, $5, array_agg(trends)
    )
    FROM trend_directory.show_trends($6) trends;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.partition_name(base_table_name name, index integer)
    RETURNS name
AS $$
    SELECT ($1 || '_' || $2)::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION trend_directory.partition_name(trend_directory.table_trend_store, index integer)
    RETURNS name
AS $$
    SELECT trend_directory.partition_name(trend_directory.base_table_name($1), $2);
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION trend_directory.timestamp_to_index(
        partition_size integer, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    unix_timestamp integer;
    div integer;
    modulo integer;
BEGIN
    unix_timestamp = extract(EPOCH FROM "timestamp")::integer;
    div = unix_timestamp / partition_size;
    modulo = mod(unix_timestamp, partition_size);

    IF modulo > 0 THEN
        return div;
    ELSE
        return div - 1;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE FUNCTION trend_directory.partition_name(
        trend_directory.table_trend_store, timestamp with time zone)
    RETURNS name
AS $$
    SELECT trend_directory.partition_name(
        $1, trend_directory.timestamp_to_index($1.partition_size, $2)
    );
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION trend_directory.table_name(trend_directory.partition)
    RETURNS name
AS $$
    SELECT trend_directory.partition_name(table_trend_store, $1.index)
    FROM trend_directory.table_trend_store
    WHERE id = $1.table_trend_store_id;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION trend_directory.rename_table_trend_store(trend_directory.table_trend_store, name)
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT public.action(
        $1,
        format(
            'ALTER TABLE %I.%I RENAME TO %I',
            trend_directory.base_table_schema(),
            $1.name,
            $2
        )
    );

    SELECT public.action(
        $1,
        format(
            'ALTER TABLE %I.%I RENAME TO %I',
            trend_directory.partition_table_schema(),
            trend_directory.table_name(partition),
            trend_directory.partition_name($2, partition.index)
        )
    )
    FROM trend_directory.partition
    WHERE table_trend_store_id = $1.id;

    UPDATE trend_directory.table_trend_store
    SET name = $2
    WHERE id = $1.id;

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.get_index_on(name, name)
    RETURNS name
AS $$
    SELECT
            i.relname
    FROM
            pg_class t,
            pg_class i,
            pg_index ix,
            pg_attribute a
    WHERE
            t.oid = ix.indrelid
            and i.oid = ix.indexrelid
            and a.attrelid = t.oid
            and a.attnum = ANY(ix.indkey)
            and t.relkind = 'r'
            and t.relname = $1
            and a.attname = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.table_trend_store(trend_directory.partition)
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT * FROM trend_directory.table_trend_store WHERE id = $1.table_trend_store_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.staged_timestamps(trend_store trend_directory.table_trend_store)
    RETURNS SETOF timestamp with time zone
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT timestamp FROM %I.%I GROUP BY timestamp',
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name(trend_store)
    );
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION trend_directory.transfer_staged(
        trend_store trend_directory.table_trend_store,
        "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    row_count integer;
BEGIN
    EXECUTE format(
        'INSERT INTO %I.%I SELECT * FROM %I.%I WHERE timestamp = $1',
        trend_directory.partition_table_schema(),
        trend_directory.table_name(trend_directory.attributes_to_partition(
            trend_store,
            trend_directory.timestamp_to_index(trend_store.partition_size, timestamp)
        )),
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name(trend_store)
    ) USING timestamp;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION trend_directory.transfer_staged(trend_store trend_directory.table_trend_store)
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT
        trend_directory.transfer_staged(trend_store, timestamp)
    FROM trend_directory.staged_timestamps(trend_store) timestamp;

    SELECT public.action(
        $1,
        format(
            'TRUNCATE %I.%I',
            trend_directory.staging_table_schema(),
            trend_directory.staging_table_name(trend_store)
        )
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.cluster_partition_table_on_timestamp_sql(name text)
    RETURNS text
AS $$
    SELECT format(
        'CLUSTER %I.%I USING %I',
        trend_directory.partition_table_schema(),
        $1,
        trend_directory.get_index_on($1, 'timestamp')
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.cluster_partition_table_on_timestamp(name text)
    RETURNS text
AS $$
    SELECT public.action(
        $1,
        trend_directory.cluster_partition_table_on_timestamp_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.modify_trend_store_column(
        trend_directory.table_trend_store, column_name name, data_type text)
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT dep_recurse.alter(
        dep_recurse.table_ref(
            trend_directory.base_table_schema(),
            trend_directory.base_table_name($1)
        ),
        ARRAY[
            format(
                'ALTER TABLE %I.%I ALTER %I TYPE %s USING CAST(%I AS %s);',
                trend_directory.base_table_schema(),
                trend_directory.base_table_name($1),
                $2, $3, $2, $3
            )
        ]
    );

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.modify_trend_store_column(
        trend_store_id integer, column_name name, data_type text)
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT trend_directory.modify_trend_store_column(
        table_trend_store, $2, $3
    )
    FROM trend_directory.table_trend_store
    WHERE table_trend_store.id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.alter_trend_name(
        trend_directory.table_trend_store, trend_name name, new_name name)
    RETURNS trend_directory.table_trend_store
AS $$
    UPDATE trend_directory.table_trend
    SET name = $3
    WHERE trend_store_id = $1.id AND name = $2;

    SELECT public.action(
        $1,
        format(
            'ALTER TABLE %I.%I RENAME %I TO %I',
            trend_directory.base_table_schema(),
            trend_directory.base_table_name($1),
            $2,
            $3
        )
    );
$$ LANGUAGE sql VOLATILE;


CREATE TYPE trend_directory.column_info AS (
    name name,
    data_type text
);


CREATE FUNCTION trend_directory.table_columns(namespace name, "table" name)
    RETURNS SETOF trend_directory.column_info
AS $$
    SELECT
        a.attname,
        format_type(a.atttypid, a.atttypmod)
    FROM
        pg_catalog.pg_class c
    JOIN
        pg_catalog.pg_namespace n ON c.relnamespace = n.oid
    JOIN
        pg_catalog.pg_attribute a ON a.attrelid = c.oid
    WHERE
        n.nspname = $1 AND
        c.relname = $2 AND
        a.attisdropped = false AND
        a.attnum > 0;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.table_columns(oid)
    RETURNS SETOF trend_directory.column_info
AS $$
    SELECT
        a.attname,
        format_type(a.atttypid, a.atttypmod)
    FROM
        pg_catalog.pg_class c
    JOIN
        pg_catalog.pg_attribute a ON a.attrelid = c.oid
    WHERE
        c.oid = $1 AND
        a.attisdropped = false AND
        a.attnum > 0;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.alter_column_types(
        namespace_name name, table_name name, columns trend_directory.column_info[])
    RETURNS dep_recurse.obj_ref
AS $$
    SELECT dep_recurse.alter(
        dep_recurse.table_ref('trend', table_name),
        ARRAY[
            format(
                'ALTER TABLE %I.%I %s',
                namespace_name,
                table_name,
                array_to_string(
                    array_agg(
                        format(
                            'ALTER %I TYPE %s USING CAST (%I AS %s)',
                            c.name,
                            c.data_type,
                            c.name,
                            c.data_type
                        )
                    ),
                    ', '
                )
            )
        ]
    )
    FROM unnest(columns) AS c;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.modify_trend_store_columns(
        trend_directory.table_trend_store, columns trend_directory.column_info[])
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT trend_directory.alter_column_types(
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1),
        $2
    );

    SELECT $1;
$$ LANGUAGE sql;


CREATE FUNCTION trend_directory.modify_trend_store_columns(
        trend_store_id integer, columns trend_directory.column_info[])
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT trend_directory.modify_trend_store_columns(
        table_trend_store,
        columns
    )
    FROM trend_directory.table_trend_store
    WHERE table_trend_store.id = trend_store_id;
$$ LANGUAGE sql;


CREATE FUNCTION trend_directory.drop_view_sql(trend_directory.view_trend_store)
    RETURNS text
AS $$
    SELECT format(
        'DROP VIEW IF EXISTS %I.%I',
        trend_directory.view_schema(),
        trend_directory.view_name($1)
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.delete_view_trends(trend_directory.view_trend_store)
    RETURNS trend_directory.view_trend_store
AS $$
    DELETE FROM trend_directory.trend
    WHERE trend_store_id = $1.id;

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.drop_view(trend_directory.view_trend_store)
    RETURNS trend_directory.view_trend_store
AS $$
    SELECT public.action($1, trend_directory.drop_view_sql($1));

    SELECT trend_directory.delete_view_trends($1);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.alter_view(trend_directory.view_trend_store, text)
    RETURNS trend_directory.view_trend_store
AS $$
    SELECT dep_recurse.alter(
        dep_recurse.view_ref(trend_directory.view_schema(), $1::name),
        ARRAY[
            format(
                'SELECT trend_directory.drop_view(view_trend_store) '
                'FROM trend_directory.view_trend_store '
                'WHERE id = %L',
                $1.id
            ),
            format(
                'SELECT trend_directory.initialize_view_trend_store(view_trend_store, %L) '
                'FROM trend_directory.view_trend_store '
                'WHERE id = %L',
                $2,
                $1.id
            )
        ]
    );

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.add_trend_to_trend_store(
        trend_directory.table_trend_store, trend_directory.table_trend)
    RETURNS trend_directory.table_trend
AS $$
    SELECT dep_recurse.alter(
        dep_recurse.table_ref(trend_directory.base_table_schema(), trend_directory.base_table_name($1)),
        ARRAY[
            format(
                'ALTER TABLE %I.%I ADD COLUMN %I %s;',
                trend_directory.base_table_schema(),
                trend_directory.base_table_name($1),
                $2.name,
                $2.data_type
            )
        ]
    );

    SELECT $2;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.add_trend_to_trend_store(
         trend_directory.table_trend_store, name,
        data_type text, description text)
    RETURNS trend_directory.table_trend
AS $$
    SELECT trend_directory.add_trend_to_trend_store(
        $1,
        trend_directory.define_table_trend($1.id, $2, $3, $4)
    )
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.create_table_trend(trend_directory.table_trend_store, trend_directory.trend_descr)
    RETURNS trend_directory.table_trend
AS $$
    SELECT trend_directory.add_trend_to_trend_store($1, $2.name, $2.data_type, $2.description);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.create_table_trends(trend_directory.table_trend_store, trend_directory.trend_descr[])
    RETURNS SETOF trend_directory.table_trend
AS $$
    SELECT trend_directory.create_table_trend($1, descr)
    FROM unnest($2) descr;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.missing_table_trends(trend_directory.table_trend_store, required trend_directory.trend_descr[])
    RETURNS SETOF trend_directory.trend_descr
AS $$
    SELECT required
    FROM unnest($2) required
    LEFT JOIN trend_directory.table_trend ON table_trend.name = required.name AND table_trend.trend_store_id = $1.id
    WHERE table_trend.id IS NULL;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.assure_table_trends_exist(trend_directory.table_trend_store, trend_directory.trend_descr[])
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT trend_directory.create_table_trend($1, t)
    FROM trend_directory.missing_table_trends($1, $2) t;

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.modify_data_type(trend_directory.table_trend_store, trend_directory.trend, required_data_type text)
    RETURNS trend_directory.table_trend_store
AS $$
    UPDATE trend_directory.trend SET data_type = $3;

    SELECT trend_directory.modify_trend_store_column($1, $2.name, $3);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.assure_data_types(trend_directory.table_trend_store, trend_directory.trend_descr[])
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT trend_directory.modify_data_type($1, trend, required.data_type)
    FROM unnest($2) required
    JOIN trend_directory.trend ON
        trend.name = required.name
            AND
        trend.trend_store_id = $1.id
            AND
        trend.data_type <> required.data_type;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.get_most_recent_timestamp(
        dest_granularity interval, ts timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
DECLARE
    minute integer;
    rounded_minutes integer;
BEGIN
    IF dest_granularity < '1 hour'::interval THEN
        minute := extract(minute FROM ts);
        rounded_minutes := minute - (minute % (dest_granularity / 60));

        return date_trunc('hour', ts) + (rounded_minutes || 'minutes')::INTERVAL;
    ELSIF dest_granularity = '1 hour'::interval THEN
        return date_trunc('hour', ts);
    ELSIF dest_granularity = '1 day'::interval THEN
        return date_trunc('day', ts);
    ELSIF dest_granularity = '1 week'::interval THEN
        return date_trunc('week', ts);
    ELSE
        RAISE EXCEPTION 'Invalid granularity: %', dest_granularity;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE FUNCTION trend_directory.is_integer(varchar)
    RETURNS boolean
AS $$
    SELECT $1 ~ '^[1-9][0-9]*$'
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION trend_directory.get_most_recent_timestamp(
        dest_granularity varchar, ts timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
DECLARE
    minute integer;
    rounded_minutes integer;
    seconds integer;
BEGIN
    IF trend_directory.is_integer(dest_granularity) THEN
        seconds = cast(dest_granularity as integer);

        return trend_directory.get_most_recent_timestamp(seconds, ts);
    ELSIF dest_granularity = 'month' THEN
        return date_trunc('month', ts);
    ELSE
        RAISE EXCEPTION 'Invalid granularity: %', dest_granularity;
    END IF;

    return seconds;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE FUNCTION trend_directory.get_timestamp_for(
        granularity interval, ts timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
DECLARE
    most_recent_timestamp timestamp with time zone;
BEGIN
    most_recent_timestamp = trend_directory.get_most_recent_timestamp($1, $2);

    IF most_recent_timestamp != ts THEN
        IF granularity = 86400 THEN
            return most_recent_timestamp + ('1 day')::INTERVAL;
        ELSE
            return most_recent_timestamp + ($1 || ' seconds')::INTERVAL;
        END IF;
    ELSE
        return most_recent_timestamp;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE FUNCTION trend_directory.get_timestamp_for(
        granularity varchar, ts timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
DECLARE
    most_recent_timestamp timestamp with time zone;
BEGIN
    most_recent_timestamp = trend_directory.get_most_recent_timestamp($1, $2);

    IF most_recent_timestamp != ts THEN
        IF trend_directory.is_integer(granularity) THEN
            IF granularity = '86400' THEN
                return most_recent_timestamp + ('1 day')::INTERVAL;
            ELSE
                return most_recent_timestamp + ($1 || ' seconds')::INTERVAL;
            END IF;
        ELSIF granularity = 'month' THEN
            return most_recent_timestamp + '1 month'::INTERVAL;
        END IF;
    ELSE
        return most_recent_timestamp;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE FUNCTION trend_directory.index_to_timestamp(partition_size integer, index integer)
    RETURNS timestamp with time zone
AS $$
    SELECT to_timestamp($1 * $2 + 1);
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION trend_directory.data_start(trend_directory.partition)
    RETURNS timestamp with time zone
AS $$
    SELECT trend_directory.index_to_timestamp(
        (trend_directory.table_trend_store($1)).partition_size, $1.index
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.data_end(trend_directory.partition)
    RETURNS timestamp with time zone
AS $$
    SELECT trend_directory.index_to_timestamp(
        (trend_directory.table_trend_store($1)).partition_size, $1.index + 1
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.create_partition_table_sql(trend_directory.partition)
    RETURNS text[]
AS $$
    SELECT ARRAY[
        format(
            'CREATE TABLE %I.%I ('
            'CHECK ("timestamp" > %L AND "timestamp" <= %L)'
            ') INHERITS (trend.%I);',
            trend_directory.partition_table_schema(),
            trend_directory.table_name($1),
            trend_directory.data_start($1),
            trend_directory.data_end($1),
            trend_directory.base_table_name(trend_directory.table_trend_store($1))
        ),
        format(
            'ALTER TABLE ONLY %I.%I '
            'ADD PRIMARY KEY (entity_id, "timestamp");',
            trend_directory.partition_table_schema(),
            trend_directory.table_name($1)
        ),
        format(
            'CREATE INDEX ON %I.%I USING btree (modified);',
            trend_directory.partition_table_schema(),
            trend_directory.table_name($1)
        ),
        format(
            'CREATE INDEX ON %I.%I USING btree (timestamp);',
            trend_directory.partition_table_schema(),
            trend_directory.table_name($1)
        ),
        format(
            'GRANT SELECT ON TABLE %I.%I TO minerva;',
            trend_directory.partition_table_schema(),
            trend_directory.table_name($1)
        ),
        format(
            'GRANT INSERT,DELETE,UPDATE ON TABLE %I.%I TO minerva_writer;',
            trend_directory.partition_table_schema(),
            trend_directory.table_name($1)
        ),
        format(
            'SELECT trend_directory.cluster_partition_table_on_timestamp(%L)',
            trend_directory.table_name($1)
        )
    ];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.create_partition_table(trend_directory.partition)
    RETURNS trend_directory.partition
AS $$
    SELECT public.action($1, trend_directory.create_partition_table_sql($1));
$$ LANGUAGE sql VOLATILE STRICT SECURITY DEFINER;


CREATE FUNCTION trend_directory.get_table_trend(
        trend_directory.table_trend_store, name)
    RETURNS trend_directory.table_trend
AS $$
    SELECT table_trend
    FROM trend_directory.table_trend
    WHERE trend_store_id = $1.id AND name = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.get_trends_for_trend_store(trend_store_id integer)
    RETURNS SETOF trend_directory.trend
AS $$
    SELECT * FROM trend_directory.trend WHERE trend.trend_store_id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.get_trends_for_trend_store(trend_directory.trend_store)
    RETURNS SETOF trend_directory.trend
AS $$
    SELECT trend_directory.get_trends_for_trend_store($1.id);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.trend_store_has_trend_with_name(
        trend_store trend_directory.trend_store, trend_name name)
    RETURNS boolean
AS $$
    SELECT exists(
        SELECT 1
        FROM trend_directory.trend
        WHERE trend_store_id = $1.id AND name = $2
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.attributes_to_table_trend(trend_directory.table_trend_store, name name, data_type text)
    RETURNS trend_directory.table_trend
AS $$
    SELECT COALESCE(
        trend_directory.get_table_trend($1, $2),
        trend_directory.define_table_trend($1.id, $2, $3, '')
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.remove_trend_from_trend_store(
        trend_store trend_directory.table_trend_store, trend_name name)
    RETURNS trend_directory.table_trend_store
AS $$
    DELETE FROM trend_directory.table_trend
    WHERE trend_store_id = $1.id AND name = $2;

    SELECT public.action(
        $1,
        format(
            'ALTER TABLE %I.%I DROP COLUMN %I;',
            trend_directory.base_table_schema(),
            trend_directory.base_table_name(trend_store),
            trend_name
        )
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.remove_trend_from_trend_store(
        trend_store text, trend_name name)
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT trend_directory.remove_trend_from_trend_store(trend_store, $2)
    FROM trend_directory.table_trend_store
    WHERE trend_store::text = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.column_exists(
        table_name name, column_name name)
    RETURNS boolean
AS $$
    SELECT EXISTS(
        SELECT 1
        FROM pg_attribute a
        JOIN pg_class c ON c.oid = a.attrelid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE c.relname = table_name AND a.attname = column_name AND n.nspname = 'trend'
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.data_type_order(data_type text)
    RETURNS integer
AS $$
BEGIN
    CASE data_type
        WHEN 'smallint' THEN
            RETURN 1;
        WHEN 'integer' THEN
            RETURN 2;
        WHEN 'bigint' THEN
            RETURN 3;
        WHEN 'real' THEN
            RETURN 4;
        WHEN 'double precision' THEN
            RETURN 5;
        WHEN 'numeric' THEN
            RETURN 6;
        WHEN 'timestamp without time zone' THEN
            RETURN 7;
        WHEN 'smallint[]' THEN
            RETURN 8;
        WHEN 'integer[]' THEN
            RETURN 9;
        WHEN 'text[]' THEN
            RETURN 10;
        WHEN 'text' THEN
            RETURN 11;
        WHEN NULL THEN
            RETURN NULL;
        ELSE
            RAISE EXCEPTION 'Unsupported data type: %', data_type;
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE FUNCTION trend_directory.greatest_data_type(
        data_type_a text, data_type_b text)
    RETURNS text
AS $$
    SELECT
        CASE WHEN trend_directory.data_type_order($2) > trend_directory.data_type_order($1) THEN
            $2
        ELSE
            $1
        END;
$$ LANGUAGE sql IMMUTABLE;


CREATE AGGREGATE trend_directory.max_data_type (text)
(
    sfunc = trend_directory.greatest_data_type,
    stype = text,
    initcond = 'smallint'
);

CREATE TYPE trend_directory.upgrade_record AS (
    timestamp timestamp with time zone,
    number_of_rows integer
);


CREATE FUNCTION trend_directory.get_partition(trend_store trend_directory.table_trend_store, index integer)
    RETURNS trend_directory.partition
AS $$
    SELECT partition
    FROM trend_directory.partition
    WHERE table_trend_store_id = $1.id AND index = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.define_partition(trend_store trend_directory.table_trend_store, index integer)
    RETURNS trend_directory.partition
AS $$
    INSERT INTO trend_directory.partition(
        table_trend_store_id,
        index
    )
    VALUES (
        $1.id,
        $2
    )
    RETURNING partition;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.create_partition(trend_store trend_directory.table_trend_store, index integer)
    RETURNS trend_directory.partition
AS $$
    SELECT trend_directory.create_partition_table(
        trend_directory.define_partition($1, $2)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.attributes_to_partition(
        trend_directory.table_trend_store, index integer)
    RETURNS trend_directory.partition
AS $$
    SELECT COALESCE(
        trend_directory.get_partition($1, $2),
        trend_directory.create_partition($1, $2)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.attributes_to_partition(
        trend_directory.table_trend_store, timestamp with time zone)
    RETURNS trend_directory.partition
AS $$
    SELECT trend_directory.attributes_to_partition(
        $1,
        trend_directory.timestamp_to_index($1.partition_size, $2)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.partition_exists(trend_directory.partition)
    RETURNS boolean
AS $$
    SELECT public.table_exists(
        trend_directory.partition_table_schema(),
        trend_directory.table_name($1)
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.get_trend_store(id integer)
    RETURNS trend_directory.trend_store
AS $$
    SELECT * FROM trend_directory.trend_store WHERE id = $1
$$ LANGUAGE sql;


CREATE FUNCTION trend_directory.get_max_modified(
        trend_directory.trend_store, timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
DECLARE
    max_modified timestamp with time zone;
BEGIN
    EXECUTE format(
        'SELECT max(modified) FROM trend_directory.%I WHERE timestamp = $1',
        trend_directory.base_table_name($1)
    ) INTO max_modified USING $2;

    RETURN max_modified;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION trend_directory.update_modified(
        table_trend_store_id integer, "timestamp" timestamp with time zone,
        modified timestamp with time zone)
    RETURNS trend_directory.modified
AS $$
    UPDATE trend_directory.modified
    SET "end" = greatest("end", $3)
    WHERE "timestamp" = $2 AND table_trend_store_id = $1
    RETURNING modified;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.store_modified(
        table_trend_store_id integer, "timestamp" timestamp with time zone,
        modified timestamp with time zone)
    RETURNS trend_directory.modified
AS $$
    INSERT INTO trend_directory.modified(
        table_trend_store_id, "timestamp", start, "end"
    ) VALUES (
        $1, $2, $3, $3
    ) RETURNING modified;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.mark_modified(
        table_trend_store_id integer, "timestamp" timestamp with time zone,
        modified timestamp with time zone)
    RETURNS trend_directory.modified
AS $$
    SELECT COALESCE(
        trend_directory.update_modified($1, $2, $3),
        trend_directory.store_modified($1, $2, $3)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.mark_modified(
        table_trend_store_id integer, "timestamp" timestamp with time zone)
    RETURNS trend_directory.modified
AS $$
    SELECT COALESCE(
        trend_directory.update_modified($1, $2, now()),
        trend_directory.store_modified($1, $2, now())
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.populate_modified(partition trend_directory.partition)
    RETURNS SETOF trend_directory.modified
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT (trend_directory.mark_modified($1, "timestamp", max(modified))).* '
        'FROM trend_directory.%I GROUP BY timestamp',
        partition.trend_store_id, partition.table_name
    );
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION trend_directory.populate_modified(partition trend_directory.partition) IS
'Populate trend_directory.modified table with modified records from one
partition. This function should only be used in recovery scenarios where the
trend_directory.modified table has become corrupt or records are missing for
some reason.';


CREATE FUNCTION trend_directory.populate_modified(trend_directory.table_trend_store)
    RETURNS SETOF trend_directory.modified
AS $$
    SELECT
        trend_directory.populate_modified(partition)
    FROM trend_directory.partition
    WHERE table_trend_store_id = $1.id;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION trend_directory.populate_modified(trend_directory.table_trend_store) IS
'Populate trend_directory.modified table with modified records from a whole
trend store. This function should only be used in recovery scenarios where the
trend_directory.modified table has become corrupt or records are missing for
some reason.';


CREATE FUNCTION trend_directory.available_timestamps(partition trend_directory.partition)
    RETURNS SETOF timestamp with time zone
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT timestamp FROM %I.%I GROUP BY timestamp',
        trend_directory.partition_table_schema(),
        trend_directory.table_name(partition)
    );
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TYPE trend_directory.transfer_result AS (
    row_count int,
    max_modified timestamp with time zone
);


CREATE FUNCTION trend_directory.transfer(
        source trend_directory.trend_store, target trend_directory.trend_store,
        "timestamp" timestamp with time zone, trend_names text[])
    RETURNS trend_directory.transfer_result
AS $$
DECLARE
    columns_part text;
    dst_partition trend_directory.partition;
    result trend_directory.transfer_result;
BEGIN
    SELECT
        array_to_string(array_agg(quote_ident(trend_name)), ',') INTO columns_part
    FROM unnest(
        ARRAY['entity_id', 'timestamp', 'modified'] || trend_names
    ) AS trend_name;

    dst_partition = trend_directory.attributes_to_partition(target, timestamp);

    EXECUTE format(
        'INSERT INTO trend_directory.%I (%s) SELECT %s FROM trend_directory.%I WHERE timestamp = $1',
        dst_partition.table_name,
        columns_part,
        columns_part,
        trend_directory.base_table_name(source)
    ) USING timestamp;

    GET DIAGNOSTICS result.row_count = ROW_COUNT;

    SELECT (
        trend_directory.mark_modified(
            target.id,
            timestamp,
            trend_directory.get_max_modified(target, timestamp)
        )
    ).end INTO result.max_modified;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION trend_directory.show_trends(trend_store_id integer)
    RETURNS SETOF trend_directory.trend_descr
AS $$
    SELECT trend_directory.show_trends(trend_store) FROM trend_directory.trend_store WHERE id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.clear(trend_directory.table_trend_store, timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    row_count integer;
BEGIN
    EXECUTE format(
        'DELETE FROM %I.%I WHERE timestamp = $1',
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1)
    ) USING $2;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


-- ###############
-- Materialization
-- ###############

CREATE FUNCTION trend_directory.to_char(trend_directory.materialization)
    RETURNS text
AS $$
    SELECT table_trend_store::name::text
    FROM trend_directory.table_trend_store
    WHERE table_trend_store.id = $1.dst_trend_store_id
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION trend_directory.add_new_state()
    RETURNS integer
AS $$
DECLARE
    count integer;
BEGIN
    INSERT INTO trend_directory.state(materialization_id, timestamp, max_modified, source_states)
    SELECT materialization_id, timestamp, max_modified, source_states
    FROM trend_directory.new_materializables;

    GET DIAGNOSTICS count = ROW_COUNT;

    RETURN count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION trend_directory.update_modified_state()
    RETURNS integer
AS $$
DECLARE
    count integer;
BEGIN
    UPDATE trend_directory.state
    SET
        max_modified = mzb.max_modified,
        source_states = mzb.source_states
    FROM trend_directory.modified_materializables mzb
    WHERE
        state.materialization_id = mzb.materialization_id AND
        state.timestamp = mzb.timestamp;

    GET DIAGNOSTICS count = ROW_COUNT;

    RETURN count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION trend_directory.delete_obsolete_state()
    RETURNS integer
AS $$
DECLARE
    count integer;
BEGIN
    DELETE FROM trend_directory.state
    USING trend_directory.obsolete_state
    WHERE
        state.materialization_id = obsolete_state.materialization_id AND
        state.timestamp = obsolete_state.timestamp;

    GET DIAGNOSTICS count = ROW_COUNT;

    RETURN count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION trend_directory.update_state()
    RETURNS text
AS $$
    SELECT 'added: ' || trend_directory.add_new_state() || ', updated: ' || trend_directory.update_modified_state() || ', deleted: ' || trend_directory.delete_obsolete_state();
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.dst_trend_store(trend_directory.materialization)
    RETURNS trend_directory.table_trend_store
AS $$
    SELECT * FROM trend_directory.table_trend_store WHERE id = $1.dst_trend_store_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.columns_part(trend_directory.view_materialization)
    RETURNS text
AS $$
    SELECT
        array_to_string(array_agg(quote_ident(name)), ', ')
    FROM
        trend_directory.table_columns(
            $1.src_view::oid
        );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.transfer_sql(trend_directory.view_materialization, timestamp with time zone)
    RETURNS text
AS $$
    SELECT format(
        'INSERT INTO %I.%I (%s) %s',
        trend_directory.partition_table_schema(),
        trend_directory.table_name(
            trend_directory.attributes_to_partition(
                trend_directory.dst_trend_store($1),
                $2
            )
        ),
        trend_directory.columns_part($1),
        format(
            'SELECT %s FROM %s WHERE timestamp = %L',
            trend_directory.columns_part($1),
            $1.src_view::name,
            $2
        )
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.transfer_sql(trend_directory.function_materialization, timestamp with time zone)
    RETURNS text
AS $$
    SELECT 'foo'::text;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.transfer(trend_directory.materialization, timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    row_count integer;
BEGIN
    CASE
    WHEN EXISTS(SELECT id FROM trend_directory.view_materialization WHERE id = $1.id) THEN
        EXECUTE trend_directory.transfer_sql(view_materialization, $2) FROM trend_directory.view_materialization WHERE id = $1.id;
    WHEN EXISTS(SELECT id FROM trend_directory.function_materialization WHERE id = $1.id) THEN
        EXECUTE trend_directory.transfer_sql(function_materialization, $2) FROM trend_directory.function_materialization WHERE id = $1.id;
    ELSE
        RAISE EXCEPTION 'No such materialization: %', $1;
    END CASE;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    PERFORM trend_directory.mark_modified($1.dst_trend_store_id, $2);

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION trend_directory.clear(trend_directory.materialization, timestamp with time zone)
    RETURNS trend_directory.materialization
AS $$
    SELECT trend_directory.clear(
        trend_directory.dst_trend_store($1),
        $2
    );

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.materialize(materialization trend_directory.materialization, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
    SELECT trend_directory.clear(materialization, timestamp);
    SELECT trend_directory.transfer(materialization, timestamp);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.materialize(materialization text, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
    SELECT trend_directory.materialize(materialization, $2)
    FROM trend_directory.materialization
    WHERE trend_directory.to_char(materialization) = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.materialize(materialization_id integer, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
    SELECT trend_directory.materialize(materialization, $2)
    FROM trend_directory.materialization
    WHERE id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.default_processing_delay(granularity interval)
    RETURNS interval
AS $$
    SELECT CASE
        WHEN $1 < '1 hour'::interval THEN
            interval '0 seconds'
        WHEN $1 = '1 hour'::interval THEN
            interval '15 minutes'
        ELSE
            interval '3 hours'
        END;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.default_stability_delay(granularity interval)
    RETURNS interval
AS $$
    SELECT CASE
        WHEN $1 < '1 hour'::interval THEN
            interval '180 seconds'
        WHEN $1 = '1 hour'::interval THEN
            interval '5 minutes'
        ELSE
            interval '15 minutes'
        END;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.define_materialization(view regclass, dst_trend_store_id integer)
    RETURNS trend_directory.view_materialization
AS $$
    INSERT INTO trend_directory.view_materialization (
        src_view,
        dst_trend_store_id,
        processing_delay,
        stability_delay,
        reprocessing_period
    )
    SELECT
        $1,
        $2,
        trend_directory.default_processing_delay(granularity),
        trend_directory.default_stability_delay(granularity),
        interval '3 days'
    FROM trend_directory.table_trend_store
    WHERE id = $2
    RETURNING view_materialization.*;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION public.raise_notice(anyelement, text)
    RETURNS anyelement
AS $$
BEGIN
    RAISE NOTICE '%', $2;

    RETURN $1;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE FUNCTION trend_directory.define_materialization(src regclass, dst trend_directory.table_trend_store)
    RETURNS trend_directory.view_materialization
AS $$
    SELECT trend_directory.define_materialization($1, $2.id);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.define_materialization(trend_directory.view_trend_store, dst trend_directory.table_trend_store)
    RETURNS trend_directory.view_materialization
AS $$
    SELECT raise_notice($1, trend_directory.view_name($1)::text);
    SELECT trend_directory.define_materialization(
        ('trend.' || quote_ident(trend_directory.view_name($1)))::regclass,
        $2.id
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.materialized_data_source_name(name text)
  RETURNS text
AS $$
BEGIN
  IF NOT name ~ '^v.*' THEN
    RAISE EXCEPTION '% does not start with a ''v''', name;
  ELSE
    RETURN substring(name, '^v(.*)');
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE FUNCTION trend_directory.render_job_json(materialization_id integer, timestamp with time zone)
    RETURNS json
AS $$
    SELECT format('{"materialization_id": %s, "timestamp": "%s"}', $1, $2)::json;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION trend_directory.source_data_ready(
        trend_directory.materialization, "timestamp" timestamp with time zone,
        max_modified timestamp with time zone)
    RETURNS boolean
AS $$
    SELECT
        $2 < now() - $1.processing_delay AND
        $3 < now() - $1.stability_delay;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.runnable(
        trend_directory.materialization, "timestamp" timestamp with time zone,
        max_modified timestamp with time zone)
    RETURNS boolean
AS $$
    SELECT
        $1.enabled AND
        trend_directory.source_data_ready($1, $2, $3) AND
        ($1.reprocessing_period IS NULL OR now() - $2 < $1.reprocessing_period);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION trend_directory.runnable(trend_directory.materialization, trend_directory.state)
    RETURNS boolean
AS $$
    SELECT trend_directory.runnable($1, $2.timestamp, $2.max_modified);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION trend_directory.open_job_slots(slot_count integer)
    RETURNS integer
AS $$
    SELECT greatest($1 - COUNT(*), 0)::integer
    FROM system.job
    WHERE type = 'materialize' AND (state = 'running' OR state = 'queued');
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.tag(tag_name text, materialization_id integer)
    RETURNS trend_directory.materialization_tag_link
AS $$
    INSERT INTO trend_directory.materialization_tag_link (materialization_id, tag_id)
    SELECT $2, tag.id FROM directory.tag WHERE name = $1
    RETURNING *;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION trend_directory.tag(text, materialization_id integer)
IS 'Add tag with name tag_name to materialization with id materialization_id.
The tag must already exist.';


CREATE FUNCTION trend_directory.tag(tag_name text, trend_directory.materialization)
    RETURNS trend_directory.materialization
AS $$
    INSERT INTO trend_directory.materialization_tag_link (materialization_id, tag_id)
    SELECT $2.id, tag.id FROM directory.tag WHERE name = $1
    RETURNING $2;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION trend_directory.tag(text, trend_directory.materialization)
IS 'Add tag with name tag_name to materialization. The tag must already exist.';


CREATE FUNCTION trend_directory.untag(trend_directory.materialization)
    RETURNS trend_directory.materialization
AS $$
    DELETE FROM trend_directory.materialization_tag_link WHERE materialization_id = $1.id RETURNING $1;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION trend_directory.untag(trend_directory.materialization)
IS 'Remove all tags from the materialization';


CREATE FUNCTION trend_directory.reset(materialization_id integer)
    RETURNS SETOF trend_directory.state
AS $$
    UPDATE trend_directory.state SET processed_states = NULL
    WHERE
        materialization_id = $1 AND
        source_states = processed_states
    RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.reset_hard(trend_directory.materialization)
    RETURNS void
AS $$
    DELETE FROM trend_directory.partition WHERE table_trend_store_id = $1.dst_trend_store_id;
    DELETE FROM trend_directory.state WHERE materialization_id = $1.id;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION trend_directory.reset_hard(trend_directory.materialization)
IS 'Remove data (partitions) resulting from this materialization and the
corresponding state records, so materialization for all timestamps can be done
again';


CREATE FUNCTION trend_directory.reset(materialization_id integer, timestamp with time zone)
    RETURNS trend_directory.state
AS $$
    UPDATE trend_directory.state SET processed_states = NULL
    WHERE materialization_id = $1 AND timestamp = $2
    RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.reset(trend_directory.materialization, timestamp with time zone)
    RETURNS trend_directory.state
AS $$
    SELECT trend_directory.reset($1.id, $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.enable(trend_directory.materialization)
    RETURNS trend_directory.materialization
AS $$
    UPDATE trend_directory.materialization SET enabled = true
    WHERE id = $1.id
    RETURNING materialization;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.disable(trend_directory.materialization)
    RETURNS trend_directory.materialization
AS $$
    UPDATE trend_directory.materialization SET enabled = false
    WHERE id = $1.id
    RETURNING materialization;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION trend_directory.fragments(trend_directory.source_fragment_state[])
    RETURNS trend_directory.source_fragment[]
AS $$
    SELECT array_agg(fragment) FROM unnest($1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION trend_directory.requires_update(trend_directory.state)
    RETURNS boolean
AS $$
    SELECT (
        $1.source_states <> $1.processed_states AND
        trend_directory.fragments($1.source_states) @> trend_directory.fragments($1.processed_states)
    )
    OR $1.processed_states IS NULL;
$$ LANGUAGE sql STABLE;


-- View 'runnable_materializations'

CREATE VIEW trend_directory.runnable_materializations AS
SELECT materialization, state
FROM trend_directory.state
JOIN trend_directory.materialization ON materialization.id = state.materialization_id
WHERE
    trend_directory.requires_update(state)
    AND
    trend_directory.runnable(materialization, trend_directory.state."timestamp", trend_directory.state.max_modified);


-- View 'next_up_materializations'

CREATE VIEW trend_directory.next_up_materializations AS
SELECT
    materialization_id,
    timestamp,
    (tag).name,
    cost,
    cumsum,
    resources AS group_resources,
    (job.id IS NOT NULL AND job.state IN ('queued', 'running')) AS job_active
FROM
(
    SELECT
        (rm.materialization).id AS materialization_id,
        (rm.state).timestamp,
        tag,
        (rm.materialization).cost,
        sum((rm.materialization).cost) over (partition by tag.name order by ts.granularity asc, (rm.state).timestamp desc, rm.materialization) as cumsum,
        (rm.state).job_id
    FROM trend_directory.runnable_materializations rm
    JOIN trend_directory.table_trend_store ts ON ts.id = (rm.materialization).dst_trend_store_id
    JOIN trend_directory.materialization_tag_link ttl ON ttl.materialization_id = (rm.materialization).id
    JOIN directory.tag ON tag.id = ttl.tag_id
) summed
JOIN trend_directory.group_priority ON (summed.tag).id = group_priority.tag_id
LEFT JOIN system.job ON job.id = job_id
WHERE cumsum <= group_priority.resources;

