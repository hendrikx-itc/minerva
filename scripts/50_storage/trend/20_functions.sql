CREATE OR REPLACE FUNCTION trend.granularity_to_text(granularity varchar)
    RETURNS text
AS $$
    SELECT CASE $1
        WHEN '300' THEN
            '5m'
        WHEN '900' THEN
            'qtr'
        WHEN '3600' THEN
            'hr'
        WHEN '43200' THEN
            '12hr'
        WHEN '86400' THEN
            'day'
        WHEN '604800' THEN
            'wk'
        WHEN 'month' THEN
        'month'
        ELSE
            $1
        END;
$$ LANGUAGE SQL IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION trend.to_char(trend.trendstore)
    RETURNS text
AS $$
    SELECT datasource.name || '_' || entitytype.name || '_' || trend.granularity_to_text($1.granularity)
        FROM directory.datasource, directory.entitytype
        WHERE datasource.id = $1.datasource_id AND entitytype.id = $1.entitytype_id;
$$ LANGUAGE SQL STABLE STRICT;


CREATE OR REPLACE FUNCTION trend.to_char(trend.view)
    RETURNS text
AS $$
    SELECT trendstore::text FROM trend.trendstore WHERE id = $1.trendstore_id;
$$ LANGUAGE SQL STABLE STRICT;


CREATE OR REPLACE FUNCTION trend.to_base_table_name(trendstore trend.trendstore)
    RETURNS text
AS $$
    SELECT datasource.name || '_' || entitytype.name || '_' || trend.granularity_to_text($1.granularity)
        FROM directory.datasource, directory.entitytype
        WHERE datasource.id = $1.datasource_id AND entitytype.id = $1.entitytype_id;
$$ LANGUAGE SQL STABLE STRICT;


CREATE OR REPLACE FUNCTION trend.get_trendstore_by_attributes(datasource_name character varying, entitytype_name character varying, granularity character varying)
    RETURNS trend.trendstore
AS $$
    SELECT ts
    FROM trend.trendstore ts
    JOIN directory.datasource ds ON ds.id = ts.datasource_id
    JOIN directory.entitytype et ON et.id = ts.entitytype_id
    WHERE lower(ds.name) = lower($1) AND lower(et.name) = lower($2) AND ts.granularity = $3;
$$ LANGUAGE SQL STABLE;


CREATE TYPE trend.trend_with_type AS (id integer, name character varying, data_type character varying);


CREATE OR REPLACE FUNCTION trend.add_trend_to_trendstore(trendstore_obj trend.trendstore, trend trend.trend_with_type)
    RETURNS VOID
AS $$
DECLARE
    base_table_name character varying;
    link_exists boolean;
BEGIN
    EXECUTE 'SELECT exists(SELECT 1 FROM trend.trendstore_trend_link WHERE trend_id=$1 AND trendstore_id = $2)' INTO link_exists USING trend.id, trendstore_obj.id;

    IF NOT link_exists THEN
        INSERT INTO trend.trendstore_trend_link (trend_id, trendstore_id)
            VALUES (trend.id, trendstore_obj.id);
    END IF;

    base_table_name = trend.to_base_table_name(trendstore_obj);

    IF NOT trend.column_exists(base_table_name, trend.name) THEN
        PERFORM dep_recurse.alter(
            dep_recurse.table_ref('trend', base_table_name),
            ARRAY[
                format('ALTER TABLE trend.%I ADD COLUMN %I %s;', base_table_name, trend.name, trend.data_type)
            ]
        );
    END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trend.add_trend_to_trendstore(trendstore trend.trendstore, trend_name name, data_type character varying)
    RETURNS trend.trend
AS $$
DECLARE
    base_table_name character varying;
    new_trend trend.trend;
BEGIN
    new_trend = trend.attributes_to_trend(trendstore, trend_name);

    base_table_name = trend.to_base_table_name(trendstore);

    IF NOT trend.column_exists(base_table_name, new_trend.name) THEN
        PERFORM dep_recurse.alter(
            dep_recurse.table_ref('trend', base_table_name),
            ARRAY[
                format('ALTER TABLE trend.%I ADD COLUMN %I %s;', base_table_name, new_trend.name, data_type)
            ]
        );
    END IF;

    RETURN new_trend;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trend.create_trends(trend.trendstore, trend.trend_descr[])
    RETURNS SETOF trend.trend
AS $$
    SELECT trend.add_trend_to_trendstore($1, t.name::character varying, t.datatype) FROM unnest($2) t;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.create_partition_table(name text)
    RETURNS void
AS $$
DECLARE
    sql text;
    full_table_name text;
BEGIN
    EXECUTE format('CREATE TABLE %I.%I (
        entity_id integer NOT NULL,
        "timestamp" timestamp with time zone NOT NULL,
        modified timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (entity_id, "timestamp")
        );', 'trend', name);

    EXECUTE format('ALTER TABLE %I.%I OWNER TO minerva_writer;', 'trend', name);

    EXECUTE format('GRANT SELECT ON TABLE %I.%I TO minerva;', 'trend', name);
    EXECUTE format('GRANT INSERT,DELETE,UPDATE ON TABLE %I.%I TO minerva_writer;', 'trend', name);

    EXECUTE format('CREATE INDEX ON %I.%I USING btree (modified);', 'trend', name);

    EXECUTE format('CREATE INDEX ON %I.%I USING btree (timestamp);', 'trend', name);
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;


CREATE OR REPLACE FUNCTION trend.staging_table_name(trend.trendstore)
    RETURNS name
AS $$
    SELECT (trend.to_base_table_name($1) || '_staging')::name;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.create_staging_table_sql(trendstore trend.trendstore)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format('CREATE UNLOGGED TABLE trend.%I () INHERITS (trend.%I);', trend.staging_table_name($1), trend.to_base_table_name(trendstore)),
    format('ALTER TABLE ONLY trend.%I ADD PRIMARY KEY (entity_id, "timestamp");', trend.staging_table_name($1)),
    format('ALTER TABLE trend.%I OWNER TO minerva_writer;', trend.staging_table_name($1)),
    format('GRANT SELECT ON TABLE trend.%I TO minerva;', trend.staging_table_name($1)),
    format('GRANT INSERT,DELETE,UPDATE ON TABLE trend.%I TO minerva_writer;', trend.staging_table_name($1))
];
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trend.create_staging_table(trendstore trend.trendstore)
    RETURNS trend.trendstore
AS $$
    SELECT public.action($1, trend.create_staging_table_sql($1));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE OR REPLACE FUNCTION trend.initialize_trendstore(trend.trendstore)
    RETURNS trend.trendstore
AS $$
    SELECT trend.create_partition_table(trend.to_base_table_name($1));

    SELECT trend.create_staging_table($1);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION trend.initialize_trendstore(trend.trendstore) IS
'Create all database objects required for the trendstore to be fully functional
and capable of storing data.';


CREATE OR REPLACE FUNCTION trend.define_trendstore(datasource_name character varying, entitytype_name character varying, granularity character varying)
    RETURNS trend.trendstore
AS $$
    INSERT INTO trend.trendstore (
        datasource_id,
        entitytype_id,
        granularity)
    VALUES (
        (directory.name_to_datasource($1)).id,
        (directory.name_to_entitytype($2)).id,
        $3
    ) RETURNING *;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION trend.define_trendstore(character varying, character varying, character varying) IS 
'Add a new trendstore record, initialize the trendstore base table, and return
the new record.\n
Later on, the definition and initialization will be split into separate steps,
but the old mechanism still uses triggers that automatically initialize the trendstore.';


CREATE OR REPLACE FUNCTION trend.create_trendstore(datasource_name character varying, entitytype_name character varying, granularity character varying)
    RETURNS trend.trendstore
AS $$
    SELECT trend.define_trendstore($1, $2, $3);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.define_trendstore(datasource_name character varying, entitytype_name character varying, granularity character varying, type trend.storetype)
    RETURNS trend.trendstore
AS $$
    INSERT INTO trend.trendstore (
        datasource_id,
        entitytype_id,
        granularity,
        type
    )
    VALUES (
        (directory.name_to_datasource($1)).id,
        (directory.name_to_entitytype($2)).id,
        $3,
        $4
    ) RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trend.create_trendstore(datasource_name character varying, entitytype_name character varying, granularity character varying, type trend.storetype)
    RETURNS trend.trendstore
AS $$
    SELECT trend.define_trendstore($1, $2, $3, $4);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.attributes_to_trendstore(datasource_name character varying, entitytype_name character varying, granularity character varying)
    RETURNS trend.trendstore
AS $$
    SELECT COALESCE(trend.get_trendstore_by_attributes($1, $2, $3), trend.create_trendstore($1, $2, $3));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.attributes_to_view_trendstore(datasource_name character varying, entitytype_name character varying, granularity character varying)
    RETURNS trend.trendstore
AS $$
    SELECT COALESCE(trend.get_trendstore_by_attributes($1, $2, $3), trend.define_trendstore($1, $2, $3, 'view'::trend.storetype));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.get_default_partition_size(granularity varchar)
    RETURNS integer
AS $$
    SELECT CASE $1
        WHEN '300' THEN
            3 * 3600
        WHEN '900' THEN
            6 * 3600
        WHEN '1800' THEN
            6 * 3600
        WHEN '3600' THEN
            24 * 3600
        WHEN '43200' THEN
            24 * 3600 * 7
        WHEN '86400' THEN
            24 * 3600 * 7
        WHEN 'day' THEN
            24 * 3600 * 7
        WHEN '604800' THEN
            24 * 3600 * 7 * 4
        WHEN 'week' THEN
            24 * 3600 * 7 * 4
        WHEN 'month' THEN
            24 * 3600 * 7 * 24
        END;
$$ LANGUAGE SQL IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION trend.generate_table_name(datasource_id integer, entitytype_id integer, granularity varchar, data_start timestamp with time zone)
    RETURNS text
AS $$
DECLARE
   entitytype_name text;
   datasource_name text;
   granularity_txt text;
   start_txt text;
BEGIN
   SELECT name INTO entitytype_name FROM directory.entitytype WHERE id = entitytype_id;
   SELECT name INTO datasource_name FROM directory.datasource WHERE id = datasource_id;

   granularity_txt = trend.granularity_to_text(granularity);

   start_txt = to_char(data_start, 'YYYYMMDD');

   RETURN lower(datasource_name) || '_' || lower(entitytype_name) || '_' || granularity_txt || '_' || start_txt;
END;
$$ LANGUAGE plpgsql STABLE STRICT;


CREATE OR REPLACE FUNCTION trend.to_table_name_v3(partition trend.partition)
    RETURNS text
AS $$
DECLARE
    entitytype_name text;
    datasource_name text;
    granularity_txt text;
    start_txt text;
BEGIN
    SELECT name INTO entitytype_name FROM directory.entitytype WHERE id = partition.entitytype_id;
    SELECT name INTO datasource_name FROM directory.datasource WHERE id = partition.datasource_id;

    granularity_txt = trend.granularity_to_text(partition.granularity);

    start_txt = to_char(partition.data_start, 'YYYYMMDD');

    RETURN lower(datasource_name) || '_' || lower(entitytype_name) || '_' || granularity_txt || '_' || start_txt;
END;
$$ LANGUAGE plpgsql STABLE STRICT;


CREATE OR REPLACE FUNCTION trend.parse_granularity(character varying)
    RETURNS interval
AS $$
    SELECT CASE
        WHEN $1 = 'month' THEN
            interval '1 month'
        WHEN $1 = 'week' THEN
            interval '1 week'
        WHEN $1 ~ '^[0-9]+$' THEN
            $1::interval
        END;
$$ LANGUAGE SQL IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION trend.partition_name(trendstore trend.trendstore, index integer)
    RETURNS name
AS $$
    SELECT CAST((trend.to_base_table_name($1) || '_' || $2) AS name);
$$ LANGUAGE SQL STABLE STRICT;


CREATE OR REPLACE FUNCTION trend.timestamp_to_index(partition_size integer, "timestamp" timestamp with time zone)
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


CREATE OR REPLACE FUNCTION trend.partition_name(trendstore trend.trendstore, timestamp with time zone)
    RETURNS name
AS $$
    SELECT trend.partition_name($1, trend.timestamp_to_index($1.partition_size, $2));
$$ LANGUAGE SQL STABLE STRICT;


CREATE OR REPLACE FUNCTION trend.to_table_name_v4(partition trend.partition)
    RETURNS text
AS $$
    -- Use partition data_end because this is a valid Minerva timestamp within
    -- the range of the partition, data_start is not.
    SELECT trend.partition_name(trendstore, $1.data_end)::text
    FROM trend.trendstore
    WHERE id = $1.trendstore_id;
$$ LANGUAGE SQL STABLE STRICT;


CREATE OR REPLACE FUNCTION trend.get_index_on(character varying, character varying)
    RETURNS name
AS $$
    SELECT
            i.relname
    FROM
            pg_class t,
            pg_class i,
            pg_index ix,
            pg_attribute a
    where
            t.oid = ix.indrelid
            and i.oid = ix.indexrelid
            and a.attrelid = t.oid
            and a.attnum = ANY(ix.indkey)
            and t.relkind = 'r'
            and t.relname = $1
            and a.attname = $2;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.create_partition_table_v4(base_name text, name text, data_start timestamp with time zone, data_end timestamp with time zone)
    RETURNS void
AS $$
DECLARE
    sql text;
    full_table_name text;
    index_name text;
BEGIN
    EXECUTE format('CREATE TABLE %I.%I (
    CHECK ("timestamp" > %L AND "timestamp" <= %L)
    ) INHERITS (%I.%I);', 'trend', name, data_start, data_end, 'trend', base_name);

    EXECUTE format('ALTER TABLE ONLY %I.%I
    ADD PRIMARY KEY (entity_id, "timestamp");', 'trend', name);

    EXECUTE format('CREATE INDEX ON %I.%I USING btree (modified);', 'trend', name);

    EXECUTE format('CREATE INDEX ON %I.%I USING btree (timestamp);', 'trend', name);

    EXECUTE format('ALTER TABLE %I.%I OWNER TO minerva_writer;', 'trend', name);

    EXECUTE format('GRANT SELECT ON TABLE %I.%I TO minerva;', 'trend', name);
    EXECUTE format('GRANT INSERT,DELETE,UPDATE ON TABLE %I.%I TO minerva_writer;', 'trend', name);

    index_name = trend.get_index_on(name, 'timestamp');

    PERFORM trend.cluster_table_on_timestamp(name);
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;


CREATE OR REPLACE FUNCTION trend.transfer_staged(trendstore trend.trendstore)
    RETURNS void
    LANGUAGE plpgsql
AS $$
DECLARE
    ts timestamp with time zone;
    partition trend.partition;
BEGIN
    FOR ts IN EXECUTE format('SELECT timestamp FROM trend.%I GROUP BY timestamp', trend.staging_table_name(trendstore))
    LOOP
        partition = trend.attributes_to_partition(trendstore, trend.timestamp_to_index(trendstore.partition_size, ts));

        EXECUTE format('INSERT INTO trend.%I SELECT * FROM trend.%I WHERE timestamp = $1', partition.table_name, trend.staging_table_name(trendstore)) USING ts;
    END LOOP;

    EXECUTE format('TRUNCATE trend.%I', trend.staging_table_name(trendstore));
END;
$$;


CREATE OR REPLACE FUNCTION trend.cluster_table_on_timestamp(name text)
    RETURNS void
AS $$
BEGIN
    EXECUTE format('CLUSTER %I.%I USING %I', 'trend', name, trend.get_index_on(name, 'timestamp'));
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trend.create_partition_column(partition_name varchar, trend_id integer, datatype varchar)
    RETURNS void
AS $$
DECLARE
    trend_name varchar;
BEGIN
    SELECT name INTO trend_name FROM trend WHERE id = trend_id;

    EXECUTE format('ALTER TABLE %I ADD COLUMN %I %I;', partition_name, trend_name, datatype);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION trend.render_view_query(view_id integer)
    RETURNS text
AS $$
    SELECT sql FROM trend.view WHERE id = view_id;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION trend.modify_partition_column(partition_name varchar, column_name varchar, datatype varchar)
    RETURNS void
AS $$
BEGIN
    PERFORM dep_recurse.alter(
        dep_recurse.table_ref('trend', base_table_name),
        ARRAY[
            format('ALTER TABLE trend.%I ALTER %I TYPE %s USING CAST(%I AS %s);', partition_name, column_name, datatype, column_name, datatype)
        ]
    );
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION trend.modify_trendstore_column(trendstore_id integer, column_name varchar, datatype varchar)
    RETURNS void
AS $$
DECLARE
    base_table_name varchar;
BEGIN
    SELECT trend.to_base_table_name(trendstore) INTO base_table_name
        FROM trend.trendstore
        WHERE trendstore.id = trendstore_id;

    PERFORM dep_recurse.alter(
        dep_recurse.table_ref('trend', base_table_name),
        ARRAY[
            format('ALTER TABLE trend.%I ALTER %I TYPE %s USING CAST(%I AS %s);', base_table_name, column_name, datatype, column_name, datatype)
        ]
    );
END;
$$ LANGUAGE plpgsql;


CREATE TYPE trend.column_info AS (
    name varchar,
    datatype varchar
);


CREATE OR REPLACE FUNCTION trend.table_columns(namespace name, "table" name)
    RETURNS SETOF trend.column_info
AS $$
    SELECT
        a.attname::character varying, format_type(a.atttypid, a.atttypmod)::character varying
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
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.alter_column_types(namespace_name name, table_name name, columns trend.column_info[])
    RETURNS void
AS $$
DECLARE
    column_alterations varchar;
BEGIN
    IF array_length(columns, 1) IS NULL THEN
        RETURN;
    END IF;

    SELECT
        array_to_string(array_agg(format('ALTER %I TYPE %s USING CAST (%I AS %s)', cs.name, cs.datatype, cs.name, cs.datatype)), ', ') INTO column_alterations
    FROM unnest(columns) AS cs;

    PERFORM dep_recurse.alter(
        dep_recurse.table_ref('trend', table_name),
        ARRAY[
            format('ALTER TABLE %I.%I %s', namespace_name, table_name, column_alterations)
        ]
    );
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION trend.modify_trendstore_columns(trendstore_id integer, columns trend.column_info[])
    RETURNS void
AS $$
    SELECT trend.alter_column_types('trend', trend.to_base_table_name(trendstore), $2)
    FROM trend.trendstore
    WHERE trendstore.id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trend.view_name(trend.view)
    RETURNS varchar
AS $$
    SELECT trend.to_base_table_name(trendstore)
    FROM trend.trendstore
    WHERE trendstore.id = $1.trendstore_id;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION trend.drop_view(view trend.view)
    RETURNS trend.view
AS $$
BEGIN
    EXECUTE format('DROP VIEW IF EXISTS trend.%I', trend.view_name(view));

    PERFORM trend.unlink_view_dependencies(view);

    PERFORM trend.delete_view_trends(view);

    RETURN view;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trend.update_view_sql(trend.view, text)
    RETURNS trend.view
AS $$
    UPDATE trend.view SET sql = $2 WHERE id = $1.id RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trend.alter_view(trend.view, text)
    RETURNS trend.view
AS $$
DECLARE
    result trend.view;
BEGIN
    result = trend.update_view_sql($1, $2);

    PERFORM dep_recurse.alter(
        dep_recurse.view_ref('trend', $1::text),
        ARRAY[
            format('SELECT trend.recreate_view(view) FROM trend.view WHERE id = %L', $1.id)
        ]
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trend.create_view_sql(trend.view)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format('CREATE VIEW trend.%I AS %s;', trend.view_name($1), $1.sql),
    format('ALTER TABLE trend.%I OWNER TO minerva_writer;', trend.view_name($1)),
    format('GRANT SELECT ON TABLE trend.%I TO minerva;', trend.view_name($1))
];
$$ LANGUAGE sql STABLE;


-- View required by function 'link_view_dependencies'
CREATE VIEW trend.view_dependencies AS
    SELECT dependent.relname AS src, pg_attribute.attname column_name, dependee.relname AS dst
    FROM pg_depend
    JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
    JOIN pg_class as dependee ON pg_rewrite.ev_class = dependee.oid
    JOIN pg_class as dependent ON pg_depend.refobjid = dependent.oid
    JOIN pg_namespace as n ON dependent.relnamespace = n.oid
    JOIN pg_attribute ON
            pg_depend.refobjid = pg_attribute.attrelid
            AND
            pg_depend.refobjsubid = pg_attribute.attnum
    WHERE n.nspname = 'trend' AND pg_attribute.attnum > 0;

ALTER VIEW trend.view_dependencies OWNER TO minerva_admin;

GRANT SELECT ON TABLE trend.view_dependencies TO minerva;


CREATE OR REPLACE FUNCTION trend.link_view_dependencies(trend.view)
    RETURNS trend.view
AS $$
    INSERT INTO trend.view_trendstore_link (view_id, trendstore_id)
    SELECT $1.id, ts.id
    FROM trend.view_dependencies vdeps
    JOIN trend.trendstore ts ON trend.to_base_table_name(ts) = vdeps.src
    LEFT JOIN trend.view_trendstore_link vtl ON vtl.view_id = $1.id AND vtl.trendstore_id = ts.id
    WHERE vdeps.dst = trend.view_name($1) AND vtl.view_id IS NULL
    GROUP BY ts.id
    RETURNING $1;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trend.get_view_column_names(view_name character varying)
    RETURNS SETOF name
AS $$
    SELECT a.attname FROM pg_class c
        JOIN pg_attribute a ON a.attrelid = c.oid
    WHERE c.relname = $1 AND a.attnum >= 0 AND NOT a.attisdropped;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trend.create_trend_for_trendstore(trendstore trend.trendstore, trend_name character varying)
    RETURNS trend.trend
AS $$
DECLARE
    new_trend trend.trend;
BEGIN
    new_trend = trend.create_trend($2, '');

    INSERT INTO trend.trendstore_trend_link (trendstore_id, trend_id) SELECT trendstore.id, new_trend.id;

    RETURN new_trend;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trend.get_trendstore(view trend.view)
    RETURNS trend.trendstore
AS $$
    SELECT trendstore FROM trend.trendstore WHERE id = $1.trendstore_id;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trend.create_view_trends(view trend.view)
    RETURNS SETOF trend.trend
AS $$
    SELECT trend.create_trend_for_trendstore(trend.get_trendstore($1), v.column_name::character varying)
    FROM (SELECT trend.get_view_column_names(trend.view_name($1)) column_name) v
    WHERE v.column_name::character varying NOT IN ('entity_id', 'timestamp', 'samples', 'function_set_ids');
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trend.create_view(trend.view)
    RETURNS trend.view
AS $$
    SELECT public.action($1, trend.create_view_sql($1));

    SELECT trend.link_view_dependencies($1);

    SELECT trend.create_view_trends($1);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trend.create_view(text)
    RETURNS trend.view
AS $$
    SELECT trend.create_view(view) FROM trend.view WHERE view::text = $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.recreate_view(view trend.view)
    RETURNS trend.view
AS $$
    SELECT trend.create_view(trend.drop_view($1));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.recreate_view(text)
    RETURNS trend.view
AS $$
    SELECT trend.create_view(trend.drop_view(view)) FROM trend.view WHERE view::text = $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.delete_view_trends(view trend.view)
    RETURNS void
AS $$
    DELETE FROM trend.trend USING trend.trendstore_trend_link ttl WHERE trend.id = ttl.trend_id AND ttl.trendstore_id = $1.trendstore_id;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.unlink_view_dependencies(trend.view)
    RETURNS trend.view
AS $$
    DELETE FROM trend.view_trendstore_link WHERE view_id = $1.id RETURNING $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.get_most_recent_timestamp(dest_granularity integer, ts timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
DECLARE
    minute integer;
    rounded_minutes integer;
BEGIN
    IF dest_granularity < 3600 THEN
        minute := extract(minute FROM ts);
        rounded_minutes := minute - (minute % (dest_granularity / 60));

        return date_trunc('hour', ts) + (rounded_minutes || 'minutes')::INTERVAL;
    ELSIF dest_granularity = 3600 THEN
        return date_trunc('hour', ts);
    ELSIF dest_granularity = 86400 THEN
        return date_trunc('day', ts);
    ELSIF dest_granularity = 604800 THEN
        return date_trunc('week', ts);
    ELSE
        RAISE EXCEPTION 'Invalid granularity: %', dest_granularity;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION trend.is_integer(varchar)
    RETURNS boolean
AS $$
    SELECT $1 ~ '^[1-9][0-9]*$'
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trend.get_most_recent_timestamp(dest_granularity varchar, ts timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
DECLARE
    minute integer;
    rounded_minutes integer;
    seconds integer;
BEGIN
    IF trend.is_integer(dest_granularity) THEN
        seconds = cast(dest_granularity as integer);

        return trend.get_most_recent_timestamp(seconds, ts);
    ELSIF dest_granularity = 'month' THEN
        return date_trunc('month', ts);
    ELSE
        RAISE EXCEPTION 'Invalid granularity: %', dest_granularity;
    END IF;

    return seconds;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION trend.get_timestamp_for(granularity integer, ts timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
DECLARE
    most_recent_timestamp timestamp with time zone;
BEGIN
    most_recent_timestamp = trend.get_most_recent_timestamp($1, $2);

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


CREATE OR REPLACE FUNCTION trend.get_timestamp_for(granularity varchar, ts timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
DECLARE
    most_recent_timestamp timestamp with time zone;
BEGIN
    most_recent_timestamp = trend.get_most_recent_timestamp($1, $2);

    IF most_recent_timestamp != ts THEN
        IF trend.is_integer(granularity) THEN
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


CREATE OR REPLACE FUNCTION trend.index_to_timestamp(partition_size integer, index integer)
    RETURNS timestamp with time zone
AS $$
    SELECT to_timestamp($1 * $2 + 1);
$$ LANGUAGE SQL IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION trend.get_trends(trendstore_id integer)
    RETURNS SETOF trend.trend_with_type
AS $$
DECLARE
    trendstore_obj trend.trendstore;
BEGIN
    SELECT * INTO trendstore_obj FROM trendstore WHERE id = trendstore_id;

    RETURN QUERY SELECT * FROM get_trends_for_v4_trendstore(trendstore_obj);
END;
$$ LANGUAGE plpgsql STABLE;


CREATE OR REPLACE FUNCTION trend.get_trend(trendstore trend.trendstore, trend_name character varying)
    RETURNS trend.trend
AS $$
    SELECT t
    FROM trend.trend t
    JOIN trend.trendstore_trend_link ttl ON ttl.trend_id = t.id
    WHERE ttl.trendstore_id = $1.id AND t.name = $2;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.get_trends_for_v3_trendstore(trendstore_obj trend.trendstore)
    RETURNS SETOF trend.trend_with_type
AS $$
DECLARE
    r trend.trend_with_type%rowtype;
BEGIN
    FOR r IN SELECT t.id, t.name, trend.max_datatype(pg_catalog.format_type(a.atttypid, a.atttypmod))
        FROM trend.trend t
        JOIN trend.trend_partition_link tpl
            ON tpl.trend_id = t.id
        JOIN trend.partition p
            ON tpl.partition_table_name = p.table_name
        JOIN pg_class c
            ON c.relname = p.table_name
        JOIN pg_attribute a
            ON a.attrelid = c.oid AND a.attname = t.name
        WHERE
            p.datasource_id = trendstore_obj.datasource_id AND
            p.entitytype_id = trendstore_obj.entitytype_id AND
            p.granularity = trendstore_obj.granularity
        GROUP BY t.id, t.name LOOP

        RETURN NEXT r;
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE OR REPLACE FUNCTION trend.get_trends_for_v4_trendstore(trendstore_obj trend.trendstore)
    RETURNS SETOF trend.trend_with_type
AS $$
DECLARE
    r trend.trend_with_type%rowtype;
BEGIN
    FOR r IN SELECT t.* FROM trend.trendstore_trend_link ttl
        JOIN trend.trend t ON t.id = ttl.trend_id
        WHERE ttl.trendstore_id = trendstore_obj.id LOOP

        RETURN NEXT r;
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE OR REPLACE FUNCTION trend.create_trend(name character varying, description character varying)
    RETURNS trend.trend
AS $$
    INSERT INTO trend.trend (name, description) VALUES ($1, $2) RETURNING trend;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.trendstore_has_trend_with_name(trendstore trend.trendstore, trend_name character varying)
    RETURNS boolean
AS $$
    SELECT exists(SELECT 1 FROM trend.trendstore_trend_link ttl JOIN trend.trend t ON ttl.trend_id = t.id WHERE ttl.trendstore_id = $1.id AND t.name = $2);
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.attributes_to_trend(trend.trendstore, name)
    RETURNS trend.trend
AS $$
    SELECT COALESCE(trend.get_trend($1, $2::character varying), trend.create_trend_for_trendstore($1, $2::character varying));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.remove_trend_from_trendstore(trendstore trend.trendstore, trend_name character varying)
    RETURNS void
AS $$
DECLARE
BEGIN
    DELETE FROM trend.trend USING trend.trendstore_trend_link ttl WHERE ttl.trend_id = trend.id AND trend.name = trend_name AND ttl.trendstore_id = trendstore.id;
    EXECUTE format('ALTER TABLE trend.%I DROP COLUMN %I;', trend.to_base_table_name(trendstore), trend_name);
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trend.remove_trend_from_trendstore(trendstore text, trend_name character varying)
    RETURNS void
AS $$
    SELECT trend.remove_trend_from_trendstore(trendstore, $2) from trend.trendstore where trendstore::text = $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.column_exists(table_name character varying, column_name character varying)
    RETURNS boolean
AS $$
DECLARE
    result boolean;
BEGIN
    SELECT EXISTS(
        SELECT 1
        FROM pg_attribute a
        JOIN pg_class c ON c.oid = a.attrelid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE c.relname = table_name AND a.attname = column_name AND n.nspname = 'trend'
    ) INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trend.datatype_order (datatype character varying)
    RETURNS integer
AS $$
BEGIN
    CASE datatype
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
            RAISE EXCEPTION 'Unsupported data type: %', datatype;
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION trend.greatest_datatype(datatype_a character varying, datatype_b character varying)
    RETURNS character varying
AS $$
BEGIN
    IF trend.datatype_order(datatype_b) > trend.datatype_order(datatype_a) THEN
        RETURN datatype_b;
    ELSE
        RETURN datatype_a;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE AGGREGATE trend.max_datatype (character varying)
(
    sfunc = trend.greatest_datatype,
    stype = character varying,
    initcond = 'smallint'
);

CREATE TYPE trend.upgrade_record AS (
    timestamp timestamp with time zone,
    number_of_rows integer
);


CREATE OR REPLACE FUNCTION trend.get_partition(trendstore trend.trendstore, index integer)
    RETURNS trend.partition
AS $$
    SELECT partition FROM trend.partition WHERE trendstore_id = $1.id AND table_name = trend.partition_name($1, $2);
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.create_partition(trendstore trend.trendstore, index integer)
    RETURNS trend.partition
AS $$
    INSERT INTO trend.partition (table_name, trendstore_id, data_start, data_end, version)
        VALUES (trend.partition_name($1, $2), $1.id, trend.index_to_timestamp($1.partition_size, $2), trend.index_to_timestamp($1.partition_size, $2 + 1), 4)
        RETURNING partition;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.attributes_to_partition(trendstore trend.trendstore, index integer)
    RETURNS trend.partition
AS $$
    SELECT COALESCE(trend.get_partition($1, $2), trend.create_partition($1, $2));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.partition_exists(table_name character varying)
    RETURNS boolean
AS $$
    SELECT exists(select relname from pg_class where relname=$1 and (relkind IN ('r', 'v')));
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.infer_trendstore_type(trend.trendstore)
    RETURNS trend.storetype
AS $$
    SELECT
        CASE relkind
            WHEN 'r' THEN 'table'::trend.storetype
            WHEN 'v' THEN 'view'::trend.storetype
            ELSE NULL
        END
    FROM pg_class
    WHERE relname = trend.to_base_table_name($1);
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.get_column_names(table_name character varying)
    RETURNS character varying[]
AS $$
    SELECT array_agg(format('%I', a.attname)::character varying) FROM pg_class c
        JOIN pg_attribute a ON a.attrelid = c.oid
    WHERE c.relname = $1 AND a.attnum >= 0 AND NOT a.attisdropped;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.get_trendstore(id integer)
    RETURNS trend.trendstore
AS $$
    SELECT * FROM trend.trendstore WHERE id = $1
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION trend.get_max_modified(trend.trendstore, timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
DECLARE
    max_modified timestamp with time zone;
BEGIN
    EXECUTE format('SELECT max(modified) FROM trend.%I WHERE timestamp = $1', trend.to_base_table_name($1)) INTO max_modified USING $2;

    RETURN max_modified;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE OR REPLACE FUNCTION trend.update_modified(table_name name, "timestamp" timestamp with time zone, modified timestamp with time zone)
    RETURNS trend.modified
AS $$
    UPDATE trend.modified SET "end" = greatest("end", $3) WHERE "timestamp" = $2 AND table_name = $1::character varying RETURNING modified;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.store_modified(table_name name, "timestamp" timestamp with time zone, modified timestamp with time zone)
    RETURNS trend.modified
AS $$
    INSERT INTO trend.modified (table_name, "timestamp", start, "end") VALUES ($1::character varying, $2, $3, $3) RETURNING modified;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.mark_modified(table_name name, "timestamp" timestamp with time zone, modified timestamp with time zone)
    RETURNS trend.modified
AS $$
    SELECT COALESCE(trend.update_modified($1, $2, $3), trend.store_modified($1, $2, $3));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.mark_modified(table_name name, "timestamp" timestamp with time zone)
    RETURNS trend.modified
AS $$
    SELECT COALESCE(trend.update_modified($1, $2, now()), trend.store_modified($1, $2, now()));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.populate_modified(partition trend.partition)
    RETURNS SETOF trend.modified
AS $$
BEGIN
    RETURN QUERY EXECUTE format('
        SELECT (trend.mark_modified(%L, "timestamp", max(modified))).*
            FROM trend.%I GROUP BY timestamp',
        partition.table_name, partition.table_name);
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trend.populate_modified(trend.trendstore)
    RETURNS SETOF trend.modified
AS $$
    SELECT trend.populate_modified(partition) FROM trend.partition WHERE trendstore_id = $1.id;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.available_timestamps(partition trend.partition)
    RETURNS SETOF timestamp with time zone
AS $$
BEGIN
    RETURN QUERY EXECUTE format('SELECT "timestamp" FROM trend.%I GROUP BY timestamp', partition.table_name);
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trend.populate_modified(character varying)
    RETURNS SETOF trend.modified
AS $$
    SELECT trend.populate_modified(partition) FROM trend.partition WHERE table_name = $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.get_dependent_view_names(table_name name)
    RETURNS SETOF name
AS $$
    SELECT dst
    FROM trend.view_dependencies
    WHERE src = $1
    GROUP BY dst;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.get_dependent_views(table_name name)
    RETURNS SETOF trend.view
AS $$
    SELECT view
    FROM trend.get_dependent_view_names($1) AS view_name
    JOIN trend.view ON trend.view_name(view) = view_name;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.get_dependent_views(trend.trendstore)
    RETURNS SETOF trend.view
AS $$
    SELECT trend.get_dependent_views(trend.to_base_table_name($1));
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION trend.get_dependent_views(trendstore_id integer)
    RETURNS SETOF trend.view
AS $$
    SELECT trend.get_dependent_views(trendstore)
    FROM trend.trendstore
    WHERE id = $1;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION trend.get_dependent_view_names(table_name name, column_name name)
    RETURNS SETOF name
AS $$
    SELECT dst
    FROM trend.view_dependencies
    WHERE src = $1 AND column_name = $2
    GROUP BY dst;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.get_dependent_views(table_name name, column_name name)
    RETURNS SETOF trend.view
AS $$
    SELECT view
    FROM trend.get_dependent_view_names($1, $2) AS view_name
    JOIN trend.view ON trend.view_name(view) = view_name;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.get_dependent_view_names(table_name name, column_names name[])
    RETURNS SETOF name
AS $$
    SELECT dst
    FROM trend.view_dependencies
    WHERE src = $1 AND ARRAY[column_name] <@ $2
    GROUP BY dst;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.get_dependent_views(table_name name, column_names name[])
    RETURNS SETOF trend.view
AS $$
    SELECT view
    FROM trend.get_dependent_view_names($1, $2) AS view_name
    JOIN trend.view ON trend.view_name(view) = view_name;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trend.define_view(trendstore_id integer, sql text)
    RETURNS trend.view
AS $$
    INSERT INTO trend.view (trendstore_id, description, sql)
    (SELECT $1, trendstore::text, $2 FROM trend.trendstore WHERE id = $1)
    RETURNING view;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.define_view(trend.trendstore, sql text)
    RETURNS trend.view
AS $$
    INSERT INTO trend.view (trendstore_id, description, sql)
    VALUES ($1.id, $1::text, $2)
    RETURNING view;
$$ LANGUAGE SQL VOLATILE;


CREATE TYPE trend.transfer_result AS (
    row_count int,
    max_modified timestamp with time zone
);


CREATE OR REPLACE FUNCTION trend.transfer(source trend.trendstore, target trend.trendstore, "timestamp" timestamp with time zone, trend_names text[])
    RETURNS trend.transfer_result
AS $$
DECLARE
    columns_part text;
    dst_partition trend.partition;
    result trend.transfer_result;
BEGIN
    SELECT
        array_to_string(array_agg(quote_ident(trend_name)), ',') INTO columns_part
    FROM unnest(ARRAY['entity_id', 'timestamp', 'modified'] || trend_names) AS trend_name;

    dst_partition = trend.attributes_to_partition(target, trend.timestamp_to_index(target.partition_size, timestamp));

    EXECUTE format('INSERT INTO trend.%I (%s) SELECT %s FROM trend.%I WHERE timestamp = $1', dst_partition.table_name, columns_part, columns_part, trend.to_base_table_name(source)) USING timestamp;

    GET DIAGNOSTICS result.row_count = ROW_COUNT;

    SELECT (trend.mark_modified(dst_partition.table_name, timestamp, trend.get_max_modified(target, timestamp))).end INTO result.max_modified;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trend.granularity_seconds(text)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE
AS $function$SELECT CASE
    WHEN $1 = '300' THEN 300
    WHEN $1 = '900' THEN 900
    WHEN $1 = '3600' THEN 3600
    WHEN $1 = '43200' THEN 43200
    WHEN $1 = '86400' THEN 86400
    WHEN $1 = '604800' THEN 604800
    WHEN $1 = 'month' THEN 2419200
END;$function$;


CREATE OR REPLACE FUNCTION trend.create_trendstore(datasource_name character varying, entitytype_name character varying, granularity character varying, trends trend.trend_descr[])
    RETURNS trend.trendstore
AS $$
DECLARE
    result trend.trendstore;
BEGIN
    result = trend.create_trendstore($1, $2, $3);

    PERFORM trend.create_trends(result, $4);

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trend.show_trends(trend.trendstore)
    RETURNS SETOF trend.trend_descr
AS $$
    SELECT trend.name::name, format_type(a.atttypid, a.atttypmod)::character varying, trend.description
    FROM trend.trend
    JOIN trend.trendstore_trend_link ON trendstore_trend_link.trend_id = trend.id
    JOIN pg_catalog.pg_class c ON c.relname = $1::text
    JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
    JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid AND a.attname = trend.name
    WHERE
        n.nspname = 'trend' AND
        a.attisdropped = false AND
        a.attnum > 0 AND trendstore_trend_link.trendstore_id = $1.id;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trend.show_trends(trendstore_id integer)
    RETURNS SETOF trend.trend_descr
AS $$
    SELECT trend.show_trends(trendstore) FROM trend.trendstore WHERE id = $1;
$$ LANGUAGE sql STABLE;
