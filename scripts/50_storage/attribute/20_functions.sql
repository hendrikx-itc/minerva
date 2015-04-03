CREATE TYPE attribute_directory.attribute_info AS (
    name name,
    data_type character varying
);


CREATE FUNCTION attribute_directory.to_char(attribute_directory.attribute_store)
    RETURNS text
AS $$
    SELECT data_source.name || '_' || entity_type.name
    FROM directory.data_source, directory.entity_type
    WHERE data_source.id = $1.data_source_id AND entity_type.id = $1.entity_type_id;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION attribute_directory.to_table_name(attribute_directory.attribute_store)
    RETURNS name
AS $$
    SELECT (attribute_directory.to_char($1))::name;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION attribute_directory.at_function_name(attribute_directory.attribute_store)
    RETURNS name
AS $$
    SELECT (attribute_directory.to_table_name($1) || '_at')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION attribute_directory.staging_new_view_name(attribute_directory.attribute_store)
    RETURNS name
AS $$
    SELECT (attribute_directory.to_table_name($1) || '_new')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.staging_modified_view_name(attribute_directory.attribute_store)
    RETURNS name
AS $$
    SELECT (attribute_directory.to_table_name($1) || '_modified')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.changes_view_name(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_changes')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.run_length_view_name(attribute_directory.attribute_store)
    RETURNS name
AS $$
    SELECT (attribute_directory.to_table_name($1) || '_run_length')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.compacted_view_name(attribute_directory.attribute_store)
    RETURNS name
AS $$
    SELECT (attribute_directory.to_table_name($1) || '_compacted')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.curr_ptr_view_name(attribute_directory.attribute_store)
    RETURNS name
AS $$
    SELECT (attribute_directory.to_table_name($1) || '_curr_selection')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.curr_view_name(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT attribute_directory.to_table_name($1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.curr_ptr_table_name(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_curr_ptr')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.greatest_data_type(data_type_a character varying, data_type_b character varying)
    RETURNS character varying
AS $$
BEGIN
    IF trend_directory.data_type_order(data_type_b) > trend_directory.data_type_order(data_type_a) THEN
        RETURN data_type_b;
    ELSE
        RETURN data_type_a;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE FUNCTION attribute_directory.dependees(attribute_directory.attribute_store)
    RETURNS dep_recurse.obj_ref[]
AS $$
SELECT ARRAY[
    dep_recurse.function_ref(
        'attribute_history'::name,
        attribute_directory.at_function_name($1)::name,
        ARRAY[
            'pg_catalog.timestamptz'
        ]::text[]
    ),
    dep_recurse.function_ref(
        'attribute_history'::name,
        attribute_directory.at_function_name($1)::name,
        ARRAY[
            'pg_catalog.int4',
            'pg_catalog.timestamptz'
        ]::text[]
    ),
    dep_recurse.function_ref(
        'attribute_history',
        'values_hash',
        ARRAY[
            format('attribute_history.%I', attribute_directory.to_table_name($1))
        ]
    ),
    dep_recurse.view_ref('attribute_staging', attribute_directory.staging_new_view_name($1)),
    dep_recurse.view_ref('attribute_staging', attribute_directory.staging_modified_view_name($1)),
    dep_recurse.view_ref('attribute_history', attribute_directory.changes_view_name($1)),
    dep_recurse.view_ref('attribute_history', attribute_directory.run_length_view_name($1)),
    dep_recurse.view_ref('attribute_history', attribute_directory.compacted_view_name($1)),
    dep_recurse.view_ref('attribute_history', attribute_directory.curr_ptr_view_name($1)),
    dep_recurse.view_ref('attribute', attribute_directory.curr_view_name($1))
]::dep_recurse.obj_ref[];
$$ LANGUAGE sql STABLE;

COMMENT ON FUNCTION attribute_directory.dependees(attribute_directory.attribute_store) IS
'Return array with all managed dependees of attribute_store base table\n'
'\n'
'This array is primarily used to alter the base table using dep_recurse.alter '
'so that the alter function can skip the database objects that are already '
'dynamically created and recreated';


CREATE FUNCTION attribute_directory.upgrade_attribute_table(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
BEGIN
    PERFORM attribute_directory.drop_curr_view($1);
    PERFORM attribute_directory.add_first_appearance_to_attribute_table($1);
    PERFORM attribute_directory.create_curr_view($1);

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.render_hash_query(attribute_directory.attribute_store)
    RETURNS text
AS $$
    SELECT COALESCE(
        'SELECT md5(' ||
        array_to_string(array_agg(format('COALESCE(($1.%I)::text, '''')', name)), ' || ') ||
        ')',
        'SELECT ''''::text')
    FROM attribute_directory.attribute
    WHERE attribute_store_id = $1.id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_hash_function_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $function$
SELECT ARRAY[
    format('CREATE FUNCTION attribute_history.values_hash(attribute_history.%I)
RETURNS text
AS $$
    %s
$$ LANGUAGE sql STABLE', attribute_directory.to_table_name($1), attribute_directory.render_hash_query($1)),
    format('ALTER FUNCTION attribute_history.values_hash(attribute_history.%I)
        OWNER TO minerva_writer', attribute_directory.to_table_name($1))
];
$function$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_hash_function(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.create_hash_function_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.materialize_curr_ptr(attribute_directory.attribute_store)
    RETURNS integer
AS $$
DECLARE
    table_name name := attribute_directory.curr_ptr_table_name($1);
    view_name name := attribute_directory.curr_ptr_view_name($1);
    row_count integer;
BEGIN
    IF attribute_directory.requires_compacting($1) THEN
        PERFORM attribute_directory.compact($1);
    END IF;

    EXECUTE format('TRUNCATE attribute_history.%I', table_name);
    EXECUTE format(
        'INSERT INTO attribute_history.%I (entity_id, timestamp) '
        'SELECT entity_id, timestamp '
        'FROM attribute_history.%I', table_name, view_name
    );

    GET DIAGNOSTICS row_count = ROW_COUNT;

    PERFORM attribute_directory.mark_curr_materialized($1.id);

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.changes_view_query(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format('SELECT entity_id, timestamp, COALESCE(hash <> lag(hash) OVER w, true) AS change FROM attribute_history.%I WINDOW w AS (PARTITION BY entity_id ORDER BY timestamp asc)', attribute_directory.to_table_name($1));
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_changes_view_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format('CREATE VIEW attribute_history.%I AS %s',
        attribute_directory.changes_view_name($1),
        attribute_directory.changes_view_query($1)
    ),
    format('ALTER TABLE attribute_history.%I OWNER TO minerva_writer',
        attribute_directory.changes_view_name($1)
    )
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_changes_view(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_changes_view_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.run_length_view_query(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format('SELECT
    public.first(entity_id) AS entity_id,
    min(timestamp) AS "start",
    max(timestamp) AS "end",
    min(first_appearance) AS first_appearance,
    max(modified) AS modified,
    count(*) AS run_length
FROM
(
    SELECT entity_id, timestamp, first_appearance, modified, sum(change) OVER w2 AS run
    FROM
    (
        SELECT entity_id, timestamp, first_appearance, modified, CASE WHEN hash <> lag(hash) OVER w THEN 1 ELSE 0 END AS change
        FROM attribute_history.%I
        WINDOW w AS (PARTITION BY entity_id ORDER BY timestamp asc)
    ) t
    WINDOW w2 AS (PARTITION BY entity_id ORDER BY timestamp ASC)
) runs
GROUP BY entity_id, run;', attribute_directory.to_table_name($1));
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_run_length_view_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE VIEW attribute_history.%I AS %s',
        attribute_directory.run_length_view_name($1),
        attribute_directory.run_length_view_query($1)
    ),
    format(
        'ALTER TABLE attribute_history.%I OWNER TO minerva_writer',
        attribute_directory.run_length_view_name($1)
    )
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_run_length_view(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_run_length_view_sql($1)
);
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION attribute_directory.create_run_length_view(attribute_directory.attribute_store) IS
'Create a view on an attribute_store''s history table that lists the runs of
duplicate attribute data records by their entity Id and start-end. This can
be used as a source for compacting actions.';


CREATE FUNCTION drop_changes_view(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
BEGIN
    EXECUTE format('DROP VIEW attribute_history.%I', attribute_directory.to_table_name($1) || '_history_changes');

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.curr_view_query(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'SELECT h.* FROM attribute_history.%I h JOIN attribute_history.%I c ON h.entity_id = c.entity_id AND h.timestamp = c.timestamp',
    attribute_directory.to_table_name($1),
    attribute_directory.curr_ptr_table_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_curr_view_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
    SELECT ARRAY[
        format(
            'CREATE VIEW attribute.%I AS %s',
            attribute_directory.curr_view_name($1),
            attribute_directory.curr_view_query($1)
        ),
        format(
            'ALTER TABLE attribute.%I OWNER TO minerva_writer',
            attribute_directory.curr_view_name($1)
        ),
        format(
            'GRANT SELECT ON TABLE attribute.%I TO minerva',
            attribute_directory.curr_view_name($1)
        )
    ];
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_curr_view(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.create_curr_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.drop_curr_view_sql(attribute_directory.attribute_store)
    RETURNS varchar
AS $$
    SELECT format('DROP VIEW attribute.%I', attribute_directory.to_table_name($1));
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.drop_curr_view(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.drop_curr_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_curr_ptr_table_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format('CREATE TABLE attribute_history.%I (
entity_id integer NOT NULL,
timestamp timestamp with time zone NOT NULL,
PRIMARY KEY (entity_id, timestamp))',
        attribute_directory.curr_ptr_table_name($1)
    ),
    format(
        'CREATE INDEX ON attribute_history.%I (entity_id, timestamp)',
        attribute_directory.curr_ptr_table_name($1)
    ),
    format(
        'ALTER TABLE attribute_history.%I OWNER TO minerva_writer',
        attribute_directory.curr_ptr_table_name($1)
    ),
    format(
        'GRANT SELECT ON TABLE attribute_history.%I TO minerva',
        attribute_directory.curr_ptr_table_name($1)
    )
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_curr_ptr_table(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_curr_ptr_table_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_curr_ptr_view_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
DECLARE
    table_name name := attribute_directory.to_table_name($1);
    view_name name := attribute_directory.curr_ptr_view_name($1);
    view_sql text;
BEGIN
    view_sql = format(
        'SELECT max(timestamp) AS timestamp, entity_id '
        'FROM attribute_history.%I '
        'GROUP BY entity_id',
        table_name
    );

    RETURN ARRAY[
        format('CREATE VIEW attribute_history.%I AS %s', view_name, view_sql),
        format(
            'ALTER TABLE attribute_history.%I '
            'OWNER TO minerva_writer',
            view_name
        ),
        format('GRANT SELECT ON TABLE attribute_history.%I TO minerva', view_name)
    ];
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.create_curr_ptr_view(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.create_curr_ptr_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.drop_curr_ptr_view_sql(attribute_directory.attribute_store)
    RETURNS varchar
AS $$
    SELECT format('DROP VIEW attribute_history.%I', attribute_directory.curr_ptr_view_name($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.drop_curr_ptr_view(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.drop_curr_ptr_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.base_columns()
    RETURNS text[]
AS $$
    SELECT ARRAY[
        'entity_id integer NOT NULL',
        '"timestamp" timestamp with time zone NOT NULL'
    ];
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION attribute_directory.column_specs(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
    SELECT attribute_directory.base_columns() || array_agg(format('%I %s', name, data_type))
    FROM attribute_directory.attribute
    WHERE attribute_store_id = $1.id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_base_table_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
    SELECT ARRAY[
        format(
            'CREATE TABLE attribute_base.%I (%s)',
            attribute_directory.to_table_name($1),
            array_to_string(attribute_directory.column_specs($1), ',')
        ),
        format(
            'ALTER TABLE attribute_base.%I OWNER TO minerva_writer',
            attribute_directory.to_table_name($1)
        ),
        format(
            'GRANT SELECT ON TABLE attribute_base.%I TO minerva',
            attribute_directory.to_table_name($1)
        )
    ]
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_base_table(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action($1, attribute_directory.create_base_table_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.add_first_appearance_to_attribute_table(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
DECLARE
    table_name name;
BEGIN
    table_name = attribute_directory.to_table_name($1);

    EXECUTE format('ALTER TABLE attribute_base.%I ADD COLUMN
        first_appearance timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP', table_name);

    EXECUTE format('UPDATE attribute_history.%I SET first_appearance = modified', table_name);

    EXECUTE format('CREATE INDEX ON attribute_history.%I (first_appearance)', table_name);

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.create_history_table_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
    SELECT ARRAY[
        format(
            'CREATE TABLE attribute_history.%I (
            first_appearance timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
            modified timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
            hash character varying,
            PRIMARY KEY (entity_id, timestamp)
            ) INHERITS (attribute_base.%I)', attribute_directory.to_table_name($1), attribute_directory.to_table_name($1)
        ),
        format(
            'CREATE INDEX ON attribute_history.%I (first_appearance)',
            attribute_directory.to_table_name($1)
        ),
        format(
            'CREATE INDEX ON attribute_history.%I (modified)',
            attribute_directory.to_table_name($1)
        ),
        format(
            'ALTER TABLE attribute_history.%I OWNER TO minerva_writer',
            attribute_directory.to_table_name($1)
        ),
        format(
            'GRANT SELECT ON TABLE attribute_history.%I TO minerva',
            attribute_directory.to_table_name($1)
        )
    ];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_history_table(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action($1, attribute_directory.create_history_table_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_staging_table_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE UNLOGGED TABLE attribute_staging.%I () INHERITS (attribute_base.%I)',
        attribute_directory.to_table_name($1),
        attribute_directory.to_table_name($1)
    ),
    format(
        'CREATE INDEX ON attribute_staging.%I USING btree (entity_id, timestamp)',
        attribute_directory.to_table_name($1)
    ),
    format(
        'ALTER TABLE attribute_staging.%I OWNER TO minerva_writer',
        attribute_directory.to_table_name($1)
    )
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_staging_table(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.create_staging_table_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_staging_new_view_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
DECLARE
    table_name name;
    view_name name;
    column_expressions text[];
    columns_part character varying;
BEGIN
    table_name = attribute_directory.to_table_name($1);
    view_name = attribute_directory.staging_new_view_name($1);

    SELECT
        array_agg(format('public.last(s.%I) AS %I', name, name)) INTO column_expressions
    FROM
        public.column_names('attribute_staging', table_name) name
    WHERE name NOT in ('entity_id', 'timestamp');

    SELECT array_to_string(
        ARRAY['s.entity_id', 's.timestamp'] || column_expressions,
        ', ')
    INTO columns_part;

    RETURN ARRAY[
        format('CREATE VIEW attribute_staging.%I
AS SELECT %s FROM attribute_staging.%I s
LEFT JOIN attribute_history.%I a
    ON a.entity_id = s.entity_id
    AND a.timestamp = s.timestamp
WHERE a.entity_id IS NULL
GROUP BY s.entity_id, s.timestamp', view_name, columns_part, table_name, table_name),
        format('ALTER TABLE attribute_staging.%I OWNER TO minerva_writer', view_name)
    ];
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION attribute_directory.create_staging_new_view(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.create_staging_new_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.drop_staging_new_view(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
BEGIN
    EXECUTE format('DROP VIEW attribute_staging.%I', attribute_directory.to_table_name($1) || '_new');

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.create_staging_modified_view_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
DECLARE
    table_name name;
    staging_table_name name;
    view_name name;
BEGIN
    table_name = attribute_directory.to_table_name($1);
    view_name = attribute_directory.staging_modified_view_name($1);

    RETURN ARRAY[
        format('CREATE VIEW attribute_staging.%I
AS SELECT s.* FROM attribute_staging.%I s
JOIN attribute_history.%I a ON a.entity_id = s.entity_id AND a.timestamp = s.timestamp', view_name, table_name, table_name),
        format('ALTER TABLE attribute_staging.%I
        OWNER TO minerva_writer', view_name)
    ];
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.create_staging_modified_view(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.create_staging_modified_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.drop_staging_modified_view_sql(attribute_directory.attribute_store)
    RETURNS varchar
AS $$
    SELECT format('DROP VIEW attribute_staging.%I', attribute_directory.staging_modified_view_name($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.drop_staging_modified_view(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.drop_staging_modified_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_hash_triggers_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format('CREATE TRIGGER set_hash_on_update
        BEFORE UPDATE ON attribute_history.%I
        FOR EACH ROW EXECUTE PROCEDURE attribute_directory.set_hash()', attribute_directory.to_table_name($1)
    ),
    format('CREATE TRIGGER set_hash_on_insert
        BEFORE INSERT ON attribute_history.%I
        FOR EACH ROW EXECUTE PROCEDURE attribute_directory.set_hash()', attribute_directory.to_table_name($1)
    )
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_hash_triggers(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_hash_triggers_sql($1)
);
$$ LANGUAGE sql VOLATILE;


-- Curr materialization log functions

CREATE FUNCTION attribute_directory.update_curr_materialized(attribute_store_id integer, materialized timestamp with time zone)
    RETURNS attribute_directory.attribute_store_curr_materialized
AS $$
    UPDATE attribute_directory.attribute_store_curr_materialized
    SET materialized = greatest(materialized, $2)
    WHERE attribute_store_id = $1
    RETURNING attribute_store_curr_materialized;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.store_curr_materialized(attribute_store_id integer, materialized timestamp with time zone)
    RETURNS attribute_directory.attribute_store_curr_materialized
AS $$
    INSERT INTO attribute_directory.attribute_store_curr_materialized (attribute_store_id, materialized)
    VALUES ($1, $2)
    RETURNING attribute_store_curr_materialized;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.mark_curr_materialized(attribute_store_id integer, materialized timestamp with time zone)
    RETURNS attribute_directory.attribute_store_curr_materialized
AS $$
    SELECT COALESCE(attribute_directory.update_curr_materialized($1, $2), attribute_directory.store_curr_materialized($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.mark_curr_materialized(attribute_store_id integer)
    RETURNS attribute_directory.attribute_store_curr_materialized
AS $$
    SELECT attribute_directory.mark_curr_materialized(attribute_store_id, modified)
    FROM attribute_directory.attribute_store_modified
    WHERE attribute_store_id = $1;
$$ LANGUAGE sql VOLATILE;


-- Compacting log functions

CREATE FUNCTION attribute_directory.update_compacted(attribute_store_id integer, compacted timestamp with time zone)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
    UPDATE attribute_directory.attribute_store_compacted
    SET compacted = greatest(compacted, $2)
    WHERE attribute_store_id = $1
    RETURNING attribute_store_compacted;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.store_compacted(attribute_store_id integer, compacted timestamp with time zone)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
    INSERT INTO attribute_directory.attribute_store_compacted (attribute_store_id, compacted)
    VALUES ($1, $2)
    RETURNING attribute_store_compacted;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.mark_compacted(attribute_store_id integer, compacted timestamp with time zone)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
    SELECT COALESCE(attribute_directory.update_compacted($1, $2), attribute_directory.store_compacted($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.mark_compacted(attribute_store_id integer)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
    SELECT attribute_directory.mark_compacted(attribute_store_id, modified)
    FROM attribute_directory.attribute_store_modified
    WHERE attribute_store_id = $1;
$$ LANGUAGE sql VOLATILE;


-- Modified log functions
CREATE FUNCTION attribute_directory.update_modified(attribute_store_id integer, modified timestamp with time zone)
    RETURNS attribute_directory.attribute_store_modified
AS $$
    UPDATE attribute_directory.attribute_store_modified
    SET modified = greatest(modified, $2)
    WHERE attribute_store_id = $1
    RETURNING attribute_store_modified;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.store_modified(attribute_store_id integer, modified timestamp with time zone)
    RETURNS attribute_directory.attribute_store_modified
AS $$
    INSERT INTO attribute_directory.attribute_store_modified (attribute_store_id, modified)
    VALUES ($1, $2)
    RETURNING attribute_store_modified;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.mark_modified(attribute_store_id integer, modified timestamp with time zone)
    RETURNS attribute_directory.attribute_store_modified
AS $$
    SELECT COALESCE(attribute_directory.update_modified($1, $2), attribute_directory.store_modified($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.mark_modified(attribute_store_id integer)
    RETURNS attribute_directory.attribute_store_modified
AS $$
    SELECT CASE
        WHEN current_setting('minerva.trigger_mark_modified') = 'off' THEN
            (SELECT asm FROM attribute_directory.attribute_store_modified asm WHERE asm.attribute_store_id = $1)

        ELSE
            attribute_directory.mark_modified($1, now())

        END;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_modified_trigger_function_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $function$
SELECT ARRAY[
    format('CREATE FUNCTION attribute_history.mark_modified_%s()
RETURNS TRIGGER
AS $$
BEGIN
    PERFORM attribute_directory.mark_modified(%s);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql', $1.id, $1.id),
    format('ALTER FUNCTION attribute_history.mark_modified_%s()
        OWNER TO minerva_writer', $1.id)
];
$function$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_modified_trigger_function(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_modified_trigger_function_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_modified_triggers_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format('CREATE TRIGGER mark_modified_on_update
        AFTER UPDATE ON attribute_history.%I
        FOR EACH STATEMENT EXECUTE PROCEDURE attribute_history.mark_modified_%s()',
        attribute_directory.to_table_name($1),
        $1.id
    ),
    format('CREATE TRIGGER mark_modified_on_insert
        AFTER INSERT ON attribute_history.%I
        FOR EACH STATEMENT EXECUTE PROCEDURE attribute_history.mark_modified_%s()',
        attribute_directory.to_table_name($1),
        $1.id
    )
];
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_modified_triggers(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_modified_triggers_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.drop_hash_function(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
BEGIN
    EXECUTE format('DROP FUNCTION attribute_history.values_hash(attribute_history.%I)', attribute_directory.to_table_name($1));

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.init(attribute_directory.attribute)
    RETURNS attribute_directory.attribute
AS $$
DECLARE
    table_name name;
    tmp_attribute_store attribute_directory.attribute_store;
    --generated_dependees dep_recurse.dep[];
BEGIN
    SELECT * INTO tmp_attribute_store
    FROM attribute_directory.attribute_store WHERE id = $1.attribute_store_id;

    table_name = attribute_directory.to_char(tmp_attribute_store);

    --generated_dependees = attribute_directory.dependees(tmp_attribute_store);

    PERFORM dep_recurse.alter(
        dep_recurse.table_ref('attribute_base', table_name),
        ARRAY[
            format('SELECT attribute_directory.add_attribute_column(attribute_store, %L, %L) FROM attribute_directory.attribute_store WHERE id = %s', $1.name, $1.data_type, $1.attribute_store_id)
        ],
        attribute_directory.dependees(tmp_attribute_store)
    );

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.add_attribute_column(attribute_directory.attribute_store, name, text)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        ARRAY[
            format('SELECT attribute_directory.drop_dependees(attribute_store) FROM attribute_directory.attribute_store WHERE id = %s', $1.id),
            format('ALTER TABLE attribute_base.%I ADD COLUMN %I %s', attribute_directory.to_char($1), $2, $3),
            format('SELECT attribute_directory.create_dependees(attribute_store) FROM attribute_directory.attribute_store WHERE id = %s', $1.id)
        ]
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.get_attribute_store(data_source_id integer, entity_type_id integer)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT attribute_store
    FROM attribute_directory.attribute_store
    WHERE data_source_id = $1 AND entity_type_id = $2;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.define_attribute_store(data_source_id integer, entity_type_id integer)
    RETURNS attribute_directory.attribute_store
AS $$
    INSERT INTO attribute_directory.attribute_store(data_source_id, entity_type_id)
    VALUES ($1, $2) RETURNING attribute_store;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.define_attribute_store(data_source_name text, entity_type_name text)
    RETURNS attribute_directory.attribute_store
AS $$
    INSERT INTO attribute_directory.attribute_store(data_source_id, entity_type_id)
    VALUES ((directory.name_to_data_source($1)).id, (directory.name_to_entity_type($2)).id)
    RETURNING attribute_store;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.add_attributes(attribute_directory.attribute_store, attributes attribute_directory.attribute_descr[])
    RETURNS attribute_directory.attribute_store
AS $$
BEGIN
    INSERT INTO attribute_directory.attribute(attribute_store_id, name, data_type, description) (
        SELECT $1.id, name, data_type, description
        FROM unnest($2) atts
    );

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.get_attribute(attribute_directory.attribute_store, name)
    RETURNS attribute_directory.attribute
AS $$
    SELECT attribute
    FROM attribute_directory.attribute
    WHERE attribute_store_id = $1.id AND name = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.define_attribute(attribute_directory.attribute_store, name name, data_type text, description text)
    RETURNS attribute_directory.attribute
AS $$
    INSERT INTO attribute_directory.attribute(attribute_store_id, name, data_type, description)
    VALUES ($1.id, $2, $3, $4)
    RETURNING attribute;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.to_attribute(attribute_directory.attribute_store, name name, data_type text, description text)
    RETURNS attribute_directory.attribute
AS $$
    SELECT COALESCE(
        attribute_directory.get_attribute($1, $2),
        attribute_directory.init(attribute_directory.define_attribute($1, $2, $3, $4))
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.check_attributes_exist(attribute_directory.attribute_store, attribute_directory.attribute_descr[])
    RETURNS SETOF attribute_directory.attribute
AS $$
    SELECT attribute_directory.to_attribute($1, n.name, n.data_type, n.description)
    FROM unnest($2) n
    LEFT JOIN attribute_directory.attribute
    ON attribute.attribute_store_id = $1.id AND n.name = attribute.name
    WHERE attribute.name IS NULL;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.check_attribute_types(attribute_directory.attribute_store, attribute_directory.attribute_descr[])
    RETURNS SETOF attribute_directory.attribute
AS $$
    UPDATE attribute_directory.attribute SET data_type = n.data_type
    FROM unnest($2) n
    WHERE attribute.name = n.name
    AND attribute.attribute_store_id = $1.id
    AND attribute.data_type <> attribute_directory.greatest_data_type(n.data_type, attribute.data_type)
    RETURNING attribute.*;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.modify_column_type(table_name name, column_name name, data_type text)
    RETURNS void
AS $$
BEGIN
    EXECUTE format('ALTER TABLE attribute_base.%I ALTER %I TYPE %s USING CAST(%I AS %s)', table_name, column_name, data_type, column_name, data_type);
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.modify_column_type(attribute_directory.attribute_store, column_name name, data_type text)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT attribute_directory.modify_column_type(
        attribute_directory.to_table_name($1), $2, $3
    );

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.transfer_staged(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
DECLARE
    table_name name;
    columns_part text;
    set_columns_part text;
    default_columns text[];
BEGIN
    table_name = attribute_directory.to_table_name($1);

    default_columns = ARRAY[
        'entity_id',
        '"timestamp"'];

    SELECT array_to_string(default_columns || array_agg(format('%I', name)), ', ') INTO columns_part
    FROM attribute_directory.attribute
    WHERE attribute_store_id = $1.id;

    EXECUTE format('INSERT INTO attribute_history.%I(%s) SELECT %s FROM attribute_staging.%I', table_name, columns_part, columns_part, table_name || '_new');

    SELECT array_to_string(array_agg(format('%I = m.%I', name, name)), ', ') INTO set_columns_part
    FROM attribute_directory.attribute
    WHERE attribute_store_id = $1.id;

    EXECUTE format('UPDATE attribute_history.%I a SET modified = now(), %s FROM attribute_staging.%I m WHERE m.entity_id = a.entity_id AND m.timestamp = a.timestamp', table_name, set_columns_part, table_name || '_modified');

    EXECUTE format('TRUNCATE attribute_staging.%I', table_name);

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.compacted_tmp_table_name(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_compacted_tmp')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_compacted_tmp_table_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE UNLOGGED TABLE attribute_history.%I ('
        '    "end" timestamp with time zone,'
        '    modified timestamp with time zone,'
        '    hash text'
        ') INHERITS (attribute_base.%I)',
        attribute_directory.compacted_tmp_table_name($1),
        attribute_directory.to_table_name($1)
    ),
    format(
        'CREATE INDEX ON attribute_history.%I '
        'USING btree (entity_id, timestamp)',
        attribute_directory.compacted_tmp_table_name($1)
    ),
    format(
        'ALTER TABLE attribute_history.%I '
        'OWNER TO minerva_writer',
        attribute_directory.compacted_tmp_table_name($1)
    )
];
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_compacted_tmp_table(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_compacted_tmp_table_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.compacted_view_query(attribute_directory.attribute_store)
    RETURNS text
AS $$
    SELECT format(
        'SELECT %s '
        'FROM attribute_history.%I rl '
        'JOIN attribute_history.%I history ON history.entity_id = rl.entity_id AND history.timestamp = rl.start '
        'WHERE run_length > 1',
        array_to_string(
            ARRAY['rl.entity_id', 'rl.start AS timestamp', 'rl."end"', 'rl.modified', 'history.hash'] || array_agg(quote_ident(name)),
            ', '
        ),
        attribute_directory.run_length_view_name($1),
        attribute_directory.to_table_name($1)
    )
    FROM attribute_directory.attribute
    WHERE attribute_store_id = $1.id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_compacted_view_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
    SELECT ARRAY[
        format(
            'CREATE VIEW attribute_history.%I AS %s',
            attribute_directory.compacted_view_name($1),
            attribute_directory.compacted_view_query($1)
        ),
        format(
            'ALTER TABLE attribute_history.%I OWNER TO minerva_writer',
            attribute_directory.compacted_view_name($1)
        )
    ];
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_compacted_view(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.create_compacted_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.drop_compacted_view_sql(attribute_directory.attribute_store)
    RETURNS text
AS $$
    SELECT format('DROP VIEW attribute_history.%I', attribute_directory.compacted_view_name($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.drop_compacted_view(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.drop_compacted_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.requires_compacting(attribute_store_id integer)
    RETURNS boolean
AS $$
    SELECT modified <> compacted OR compacted IS NULL
    FROM attribute_directory.attribute_store_modified mod
    LEFT JOIN attribute_directory.attribute_store_compacted cmp ON mod.attribute_store_id = cmp.attribute_store_id
    WHERE mod.attribute_store_id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.requires_compacting(attribute_directory.attribute_store)
    RETURNS boolean
AS $$
    SELECT attribute_directory.requires_compacting($1.id);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.compact(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
DECLARE
    table_name name := attribute_directory.to_table_name($1);
    compacted_tmp_table_name name := table_name || '_compacted_tmp';
    compacted_view_name name := attribute_directory.compacted_view_name($1);
    default_columns text[] := ARRAY['entity_id', 'timestamp', '"end"', 'hash', 'modified'];
    attribute_columns text[];
    columns_part text;
    row_count integer;
BEGIN
    SELECT array_agg(quote_ident(name)) INTO attribute_columns
    FROM attribute_directory.attribute
    WHERE attribute_store_id = $1.id;

    columns_part = array_to_string(default_columns || attribute_columns, ',');

    EXECUTE format(
        'TRUNCATE attribute_history.%I',
        compacted_tmp_table_name
    );

    EXECUTE format(
        'INSERT INTO attribute_history.%I(%s) '
        'SELECT %s FROM attribute_history.%I;',
        compacted_tmp_table_name, columns_part,
        columns_part, compacted_view_name
    );

    GET DIAGNOSTICS row_count = ROW_COUNT;

    RAISE NOTICE 'compacted % rows', row_count;

    EXECUTE format(
        'DELETE FROM attribute_history.%I history '
        'USING attribute_history.%I tmp '
        'WHERE '
        '	history.entity_id = tmp.entity_id AND '
        '	history.timestamp >= tmp.timestamp AND '
        '	history.timestamp <= tmp."end";',
        table_name, compacted_tmp_table_name
    );

    columns_part = array_to_string(
        ARRAY['entity_id', 'timestamp', 'modified', 'hash'] || attribute_columns,
        ','
    );

    EXECUTE format(
        'INSERT INTO attribute_history.%I(%s) '
        'SELECT %s '
        'FROM attribute_history.%I',
        table_name, columns_part,
        columns_part,
        compacted_tmp_table_name
    );

    PERFORM attribute_directory.mark_compacted($1.id);

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION attribute_directory.compact(attribute_directory.attribute_store) IS
'Remove all subsequent records with duplicate attribute values and update the modified of the first';


CREATE FUNCTION attribute_directory.direct_dependers(name text)
    RETURNS SETOF name
AS $$
    SELECT dependee.relname AS name
    FROM pg_depend
    JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
    JOIN pg_class as dependee ON pg_rewrite.ev_class = dependee.oid
    JOIN pg_class as dependent ON pg_depend.refobjid = dependent.oid
    JOIN pg_namespace as n ON dependent.relnamespace = n.oid
    JOIN pg_attribute ON
            pg_depend.refobjid = pg_attribute.attrelid
            AND
            pg_depend.refobjsubid = pg_attribute.attnum
    WHERE pg_attribute.attnum > 0 AND dependent.relname = $1;
$$ LANGUAGE sql STABLE;


-- Stub function to be able to create a recursive one.
CREATE FUNCTION attribute_directory.dependers(name name, level integer)
    RETURNS TABLE(name name, level integer)
AS $$
    SELECT $1, $2;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION attribute_directory.dependers(name name, level integer)
    RETURNS TABLE(name name, level integer)
AS $$
    SELECT (d.dependers).* FROM (
        SELECT attribute_directory.dependers(depender, $2 + 1)
        FROM attribute_directory.direct_dependers($1) depender
    ) d
    UNION ALL
    SELECT depender, $2
    FROM attribute_directory.direct_dependers($1) depender;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.dependers(name name)
    RETURNS TABLE(name name, level integer)
AS $$
    SELECT * FROM attribute_directory.dependers($1, 1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.at_ptr_function_name(attribute_directory.attribute_store)
    RETURNS name
AS $$
    SELECT (attribute_directory.to_table_name($1) || '_at_ptr')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION attribute_directory.create_at_func_ptr_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $function$
    SELECT ARRAY[
        format(
            'CREATE FUNCTION attribute_history.%I(timestamp with time zone)
RETURNS TABLE(entity_id integer, "timestamp" timestamp with time zone)
AS $$
    SELECT entity_id, max(timestamp)
    FROM
        attribute_history.%I
    WHERE timestamp <= $1
    GROUP BY entity_id;
$$ LANGUAGE sql STABLE',
            attribute_directory.at_ptr_function_name($1),
            attribute_directory.to_table_name($1)
        ),
        format(
            'ALTER FUNCTION attribute_history.%I(timestamp with time zone) '
            'OWNER TO minerva_writer',
            attribute_directory.at_ptr_function_name($1)
        )
    ];
$function$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_at_func_ptr(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.create_at_func_ptr_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_entity_at_func_ptr_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $function$
    SELECT ARRAY[
        format(
            'CREATE FUNCTION attribute_history.%I(entity_id integer, timestamp with time zone)
    RETURNS timestamp with time zone
    AS $$
        SELECT max(timestamp)
        FROM
            attribute_history.%I
        WHERE timestamp <= $2 AND entity_id = $1;
    $$ LANGUAGE sql STABLE',
            attribute_directory.at_ptr_function_name($1),
            attribute_directory.to_table_name($1)
        ),
        format(
            'ALTER FUNCTION attribute_history.%I(entity_id integer, timestamp with time zone) '
            'OWNER TO minerva_writer',
            attribute_directory.at_ptr_function_name($1)
        )
    ];
$function$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_entity_at_func_ptr(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.create_entity_at_func_ptr_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_at_func(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $function$
    SELECT public.action(
        $1,
        format(
            'CREATE FUNCTION attribute_history.%I(timestamp with time zone)
    RETURNS SETOF attribute_history.%I
AS $$
SELECT a.*
FROM
    attribute_history.%I a
JOIN
    attribute_history.%I($1) at
ON at.entity_id = a.entity_id AND at.timestamp = a.timestamp;
$$ LANGUAGE sql STABLE;',
            attribute_directory.at_function_name($1),
            attribute_directory.to_table_name($1),
            attribute_directory.to_table_name($1),
            attribute_directory.at_ptr_function_name($1)
        )
    );

    SELECT public.action(
        $1,
        format(
            'ALTER FUNCTION attribute_history.%I(timestamp with time zone) '
            'OWNER TO minerva_writer',
            attribute_directory.at_function_name($1)
        )
    );
$function$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.drop_entity_at_func_sql(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION attribute_history.%I(integer, timestamp with time zone)',
    attribute_directory.at_function_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.drop_entity_at_func(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT public.action(
        $1,
        attribute_directory.drop_entity_at_func_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_entity_at_func_sql(attribute_directory.attribute_store)
    RETURNS text[]
AS $function$
    SELECT ARRAY[
        format(
            'CREATE FUNCTION attribute_history.%I(entity_id integer, timestamp with time zone)
    RETURNS attribute_history.%I
AS $$
SELECT *
FROM
    attribute_history.%I
WHERE timestamp = attribute_history.%I($1, $2) AND entity_id = $1;
$$ LANGUAGE sql STABLE;',
            attribute_directory.at_function_name($1),
            attribute_directory.to_table_name($1),
            attribute_directory.to_table_name($1),
            attribute_directory.at_ptr_function_name($1)
        ),
        format(
            'ALTER FUNCTION attribute_history.%I(entity_id integer, timestamp with time zone) '
            'OWNER TO minerva_writer',
            attribute_directory.at_function_name($1)
        )
    ];
$function$ LANGUAGE sql STABLE;


CREATE FUNCTION attribute_directory.create_entity_at_func(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $function$
    SELECT public.action(
        $1,
        attribute_directory.create_entity_at_func_sql($1)
    );
$function$ LANGUAGE sql VOLATILE;



CREATE FUNCTION attribute_directory.create_dependees(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT
        attribute_directory.create_compacted_view(
            attribute_directory.create_curr_view(
                attribute_directory.create_curr_ptr_view(
                    attribute_directory.create_staging_modified_view(
                        attribute_directory.create_staging_new_view(
                            attribute_directory.create_hash_function($1)
                        )
                    )
                )
            )
        );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.drop_dependees(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT
        attribute_directory.drop_hash_function(
            attribute_directory.drop_staging_new_view(
                attribute_directory.drop_staging_modified_view(
                    attribute_directory.drop_curr_ptr_view(
                        attribute_directory.drop_curr_view(
                            attribute_directory.drop_compacted_view($1)
                        )
                    )
                )
            )
        );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.modify_data_type(attribute_directory.attribute)
    RETURNS attribute_directory.attribute
AS $$
    SELECT
        attribute_directory.create_dependees(
            attribute_directory.modify_column_type(
                attribute_directory.drop_dependees(attribute_store),
                $1.name,
                $1.data_type
            )
        )
    FROM attribute_directory.attribute_store
    WHERE id = $1.attribute_store_id;

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.init(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
    -- Base/parent table
    SELECT attribute_directory.create_base_table($1);

    -- Inherited table definitions
    SELECT attribute_directory.create_history_table($1);
    SELECT attribute_directory.create_staging_table($1);
    SELECT attribute_directory.create_compacted_tmp_table($1);

    -- Separate table
    SELECT attribute_directory.create_curr_ptr_table($1);

    -- Other
    SELECT attribute_directory.create_at_func_ptr($1);
    SELECT attribute_directory.create_at_func($1);

    SELECT attribute_directory.create_entity_at_func_ptr($1);
    SELECT attribute_directory.create_entity_at_func($1);

    SELECT attribute_directory.create_hash_triggers($1);

    SELECT attribute_directory.create_modified_trigger_function($1);
    SELECT attribute_directory.create_modified_triggers($1);

    SELECT attribute_directory.create_changes_view($1);

    SELECT attribute_directory.create_run_length_view($1);

    SELECT attribute_directory.create_dependees($1);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_attribute_store(data_source_name text, entity_type_name text)
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT attribute_directory.init(attribute_directory.define_attribute_store($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_attribute_store(data_source_name text, entity_type_name text, attributes attribute_directory.attribute_descr[])
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT attribute_directory.init(
    attribute_directory.add_attributes(attribute_directory.define_attribute_store($1, $2), $3)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.create_attribute_store(data_source_id integer, entity_type_id integer, attributes attribute_directory.attribute_descr[])
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT attribute_directory.init(
        attribute_directory.add_attributes(attribute_directory.define_attribute_store($1, $2), $3)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION attribute_directory.to_attribute_store(data_source_id integer, entity_type_id integer, attribute_directory.attribute_descr[])
    RETURNS attribute_directory.attribute_store
AS $$
    SELECT COALESCE(
        attribute_directory.get_attribute_store($1, $2),
        attribute_directory.create_attribute_store($1, $2, $3)
    );
$$ LANGUAGE sql VOLATILE;
