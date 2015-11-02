CREATE TYPE trend.fingerprint AS (
    body text,
    modified timestamp with time zone
);


CREATE OR REPLACE FUNCTION trend.aggregation_timestamps(src_granularity interval, dst_granularity interval, timestamp with time zone)
    RETURNS SETOF timestamp with time zone
AS $$
    SELECT generate_series($3 - $2 + $1, $3, $1);
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trend.aggregation_timestamps(src_granularity character varying, dst_granularity character varying, timestamp with time zone)
    RETURNS SETOF timestamp with time zone
AS $$
    SELECT trend.aggregation_timestamps(trend.parse_granularity($1), trend.parse_granularity($2), $3);
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trend.fingerprint(trend.trendstore, trend.trendstore, timestamp with time zone)
    RETURNS trend.fingerprint
AS $$
    SELECT
        string_agg(
            format('%s: %s', t, modified),
            E'\n'
        ),
        max(modified)
    FROM (
        SELECT t, trend.modified($1, t) modified
        FROM trend.aggregation_timestamps($1.granularity, $2.granularity, $3) t
    ) m;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION materialization.fingerprint_function_name(materialization.type)
    RETURNS name
AS $$
    SELECT (trend.to_base_table_name(dst) || '_fingerprint')::name
    FROM trend.trendstore dst
    WHERE dst.id = $1.dst_trendstore_id;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION materialization.fingerprint_fn_sql(materialization.type)
    RETURNS text
AS $$
    select format('CREATE FUNCTION trend.%I(timestamp with time zone) RETURNS trend.fingerprint AS $body$', materialization.fingerprint_function_name($1)) ||
    string_agg(
        format(
            E'SELECT trend.fingerprint(src_trendstore, dst_trendstore, $1)\n'
            'FROM trend.trendstore src_trendstore, trend.trendstore dst_trendstore\n'
            'WHERE src_trendstore.id = %s AND dst_trendstore.id = %s\n',
            src_trendstore.id,
            view.trendstore_id
        ),
        E'UNION ALL\n'
    ) || '$body$ LANGUAGE sql STABLE;'
    FROM trend.view
    join trend.view_trendstore_link vtl on vtl.view_id = view.id
    join trend.trendstore src_trendstore on src_trendstore.id = vtl.trendstore_id
    where view.trendstore_id = $1.src_trendstore_id;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION materialization.create_fingerprint_fn(materialization.type)
    RETURNS materialization.type
AS $$
    SELECT public.action($1, materialization.fingerprint_fn_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION materialization.drop_fingerprint_fn_sql(materialization.type)
    RETURNS text
AS $$
    SELECT format(
        'DROP FUNCTION trend.%I(timestamp with time zone)',
        materialization.fingerprint_function_name($1)
    );
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION materialization.drop_fingerprint_fn(materialization.type)
    RETURNS materialization.type
AS $$
    SELECT public.action($1, materialization.drop_fingerprint_fn_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION materialization.fingerprint(materialization.type, timestamp with time zone)
    RETURNS trend.fingerprint
AS $$
DECLARE
    result trend.fingerprint;
BEGIN
    EXECUTE format('SELECT * FROM trend.%I($1)', materialization.fingerprint_function_name($1)) INTO result USING $2;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION materialization.processable_timestamps(materialization.type)
    RETURNS SETOF timestamp with time zone
AS $$
    SELECT generate_series(
        trend.get_most_recent_timestamp(dst_trendstore.granularity, now() - $1.reprocessing_period) + trend.parse_granularity(dst_trendstore.granularity),
        trend.get_most_recent_timestamp(dst_trendstore.granularity, now() - $1.processing_delay),
        trend.parse_granularity(dst_trendstore.granularity)
    )
    FROM trend.trendstore dst_trendstore
    WHERE dst_trendstore.id = $1.dst_trendstore_id;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION materialization.changed_fragments(timestamp with time zone)
    RETURNS SETOF materialization.fragment
AS $$
    SELECT type, timestamp FROM (
        SELECT
            mt AS "type",
            trend.get_timestamp_for(dst.granularity, mdf.timestamp) AS timestamp
        FROM trend.modified mdf
        JOIN trend.partition p ON
                mdf.table_name = p.table_name
        JOIN trend.view_trendstore_link vtl ON
                vtl.trendstore_id = p.trendstore_id
        JOIN trend.view v ON
        v.id = vtl.view_id
        JOIN materialization.type mt ON
                mt.src_trendstore_id = v.trendstore_id
        JOIN trend.trendstore dst ON
                dst.id = mt.dst_trendstore_id
        WHERE mdf.end >= $1
    ) f GROUP BY type, timestamp;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION materialization.changed_fingerprints(timestamp with time zone)
    RETURNS TABLE (
        "type" materialization.type,
        "timestamp" timestamp with time zone,
        fingerprint trend.fingerprint
)
AS $$
    SELECT type, timestamp, materialization.fingerprint(type, timestamp)
    FROM materialization.changed_fragments($1);
$$ LANGUAGE sql STABLE;


CREATE TYPE materialization.update_state_result AS (
    new integer,
    updated integer
);


CREATE OR REPLACE FUNCTION materialization.update_state_fingerprint(timestamp with time zone)
    RETURNS materialization.update_state_result
AS $$
DECLARE
    result materialization.update_state_result;
BEGIN
    INSERT INTO materialization.state_fingerprint_staging(type_id, timestamp, fingerprint, modified)
    (
        SELECT (type).id, timestamp, (fingerprint).body, (fingerprint).modified
        FROM materialization.changed_fingerprints($1)
    );

    INSERT INTO materialization.state_fingerprint(type_id, timestamp, fingerprint, modified)
    (
        SELECT type_id, timestamp, fingerprint, modified
        FROM materialization.new_state_fingerprint
    );

    GET DIAGNOSTICS result.new = ROW_COUNT;

    UPDATE materialization.state_fingerprint state
    SET
        fingerprint = modified.fingerprint,
        modified = modified.modified
    FROM materialization.modified_state_fingerprint modified
    WHERE
        state.type_id = modified.type_id AND
        state.timestamp = modified.timestamp;

    GET DIAGNOSTICS result.updated = ROW_COUNT;

    DELETE FROM materialization.state_fingerprint_staging;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION materialization.to_char(materialization.type)
    RETURNS text
AS $$
    SELECT trend.to_base_table_name(src) || ' -> ' || trend.to_base_table_name(dst)
    FROM trend.trendstore src, trend.trendstore dst
    WHERE src.id = $1.src_trendstore_id AND dst.id = $1.dst_trendstore_id
$$ LANGUAGE SQL STABLE STRICT;


CREATE OR REPLACE FUNCTION materialization.add_new_state()
    RETURNS integer
AS $$
DECLARE
    count integer;
BEGIN
    INSERT INTO materialization.state(type_id, timestamp, max_modified, source_states)
    SELECT type_id, timestamp, max_modified, source_states
    FROM materialization.new_materializables;

    GET DIAGNOSTICS count = ROW_COUNT;

    RETURN count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION materialization.update_modified_state()
    RETURNS integer
AS $$
DECLARE
    count integer;
BEGIN
    UPDATE materialization.state
    SET
        max_modified = mzb.max_modified,
        source_states = mzb.source_states
    FROM materialization.modified_materializables mzb
    WHERE
        state.type_id = mzb.type_id AND
        state.timestamp = mzb.timestamp;

    GET DIAGNOSTICS count = ROW_COUNT;

    RETURN count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION materialization.delete_obsolete_state()
    RETURNS integer
AS $$
DECLARE
    count integer;
BEGIN
    DELETE FROM materialization.state
    USING materialization.obsolete_state
    WHERE
        state.type_id = obsolete_state.type_id AND
        state.timestamp = obsolete_state.timestamp;

    GET DIAGNOSTICS count = ROW_COUNT;

    RETURN count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION materialization.update_state()
    RETURNS text
AS $$
    SELECT 'added: ' || materialization.add_new_state() || ', updated: ' || materialization.update_modified_state() || ', deleted: ' || materialization.delete_obsolete_state();
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.has_function(materialization.type)
    RETURNS boolean
AS $$
    SELECT EXISTS(SELECT pg_proc.oid
    FROM pg_proc
    JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
    WHERE nspname = 'trend_transform' AND proname = (SELECT trendstore::text FROM trend.trendstore WHERE id = $1.dst_trendstore_id));
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION materialization.function(materialization.type)
    RETURNS oid
AS $$
    SELECT pg_proc.oid
    FROM pg_proc
    JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
    WHERE nspname = 'trend_transform' AND proname = (SELECT trendstore::text FROM trend.trendstore WHERE id = $1.dst_trendstore_id);
$$ LANGUAGE sql STABLE;


CREATE TYPE materialization.materialization_result AS (processed_max_modified timestamp with time zone, row_count integer);


CREATE OR REPLACE FUNCTION materialization.missing_columns(src trend.trendstore, dst trend.trendstore)
    RETURNS TABLE (name character varying, datatype character varying)
AS $$
    SELECT name, datatype
    FROM trend.table_columns('trend', trend.to_base_table_name($1))
    WHERE name NOT IN (
        SELECT name FROM trend.table_columns('trend', trend.to_base_table_name($2))
    );
$$ LANGUAGE SQL STABLE;

COMMENT ON FUNCTION materialization.missing_columns(src trend.trendstore, dst trend.trendstore)
IS 'The set of table columns (name, datatype) that exist in the source trendstore but not yet in the destination.';


CREATE OR REPLACE FUNCTION materialization.missing_columns(regprocedure, trend.trendstore)
    RETURNS TABLE (name character varying, datatype character varying)
AS $$
    SELECT rc.name::character varying, rc.data_type::character varying
    FROM materialization.function_return_columns($1::oid) rc
    WHERE rc.name NOT IN (
        SELECT name FROM trend.table_columns('trend', trend.to_base_table_name($2))
    );
$$ LANGUAGE SQL STABLE;

COMMENT ON FUNCTION materialization.missing_columns(regprocedure, dst trend.trendstore) IS
'The set of table columns (name, datatype) that exist in the return type of
the function, but not yet in the destination trendstore.';


CREATE OR REPLACE FUNCTION materialization.missing_columns(materialization.type)
    RETURNS TABLE (name character varying, datatype character varying)
AS $$
    SELECT CASE
    WHEN materialization.has_function($1) THEN
        (
            SELECT materialization.missing_columns(materialization.function($1)::regprocedure, dst)
            FROM trend.trendstore dst
            WHERE dst.id = $1.dst_trendstore_id
        )
    ELSE
        (
            SELECT materialization.missing_columns(src, dst)
            FROM trend.trendstore src, trend.trendstore dst
            WHERE src.id = $1.src_trendstore_id AND dst.id = $1.dst_trendstore_id
        )
    END;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION materialization.add_missing_trends(src trend.trendstore, dst trend.trendstore)
    RETURNS bigint
AS $$
    SELECT count(trend.add_trend_to_trendstore($2, name, datatype))
    FROM materialization.missing_columns($1, $2);
$$ LANGUAGE SQL VOLATILE;

COMMENT ON FUNCTION materialization.add_missing_trends(src trend.trendstore, dst trend.trendstore)
IS 'Add trends and actual table columns to destination that exist in the source
trendstore but not yet in the destination.';


CREATE OR REPLACE FUNCTION materialization.add_missing_trends(regprocedure, trend.trendstore)
    RETURNS bigint
AS $$
    SELECT count(trend.add_trend_to_trendstore($2, name, datatype))
    FROM materialization.missing_columns($1, $2);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.add_missing_trends(materialization.type)
    RETURNS materialization.type
AS $$
    SELECT CASE
    WHEN materialization.has_function($1) THEN
        (
            SELECT materialization.add_missing_trends(materialization.function($1)::regprocedure, dst)
            FROM trend.trendstore dst
            WHERE dst.id = $1.dst_trendstore_id
        )
    ELSE
        (
            SELECT materialization.add_missing_trends(src, dst)
            FROM trend.trendstore src, trend.trendstore dst
            WHERE src.id = $1.src_trendstore_id AND dst.id = $1.dst_trendstore_id
        )
    END;

    SELECT $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.modify_mismatching_trends(src trend.trendstore, dst trend.trendstore)
    RETURNS void
AS $$
    SELECT trend.modify_trendstore_columns($2.id, array_agg(src_column))
    FROM trend.table_columns('trend', trend.to_base_table_name($1)) src_column
    JOIN trend.table_columns('trend', trend.to_base_table_name($2)) dst_column ON
        src_column.name = dst_column.name
            AND
        src_column.datatype <> dst_column.datatype;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.modify_mismatching_trends(materialization.type)
    RETURNS void
AS $$
    SELECT materialization.modify_mismatching_trends(src, dst)
    FROM trend.trendstore src, trend.trendstore dst
    WHERE src.id = $1.src_trendstore_id AND dst.id = $1.dst_trendstore_id;
$$ LANGUAGE SQL VOLATILE;


CREATE TYPE materialization.column AS (
    name name,
    data_type text
);


CREATE OR REPLACE FUNCTION materialization.function_return_columns(oid)
    RETURNS SETOF materialization.column
AS $$
select
    (name, type_name)::materialization.column
from (
    select unnest(names) AS "name", format_type(unnest(type_oids), NULL) AS "type_name"
    from (
            select
            proargnames[pronargs+1:array_length(proargnames, 1)] AS names,
            (proallargtypes::oid[])[pronargs+1:array_length(proallargtypes, 1)] AS type_oids
            from pg_proc where oid = $1
    ) foo
) bar;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION materialization.function_return_columns(materialization.type)
    RETURNS SETOF materialization.column
AS $$
SELECT
    materialization.function_return_columns(pg_proc.oid)
FROM pg_proc
JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
WHERE nspname = 'trend_transform' AND proname = (SELECT trendstore::text FROM trend.trendstore WHERE id = $1.dst_trendstore_id)
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION materialization.partial_index_start(partial_index int4, count_partials int4)
  RETURNS int8
  LANGUAGE sql
  IMMUTABLE
AS $$
  SELECT least(((4294967295/$2)+1) * $1) - 2147483648
$$;

CREATE OR REPLACE FUNCTION materialization.entity_in_partial(entity_id int4, partial_index int4, count_partials int4)
  RETURNS boolean
  LANGUAGE sql
  IMMUTABLE
AS $$
SELECT CASE WHEN $3 = 1 THEN true ELSE hashint4($1) BETWEEN materialization.partial_index_start($2, $3) AND materialization.partial_index_start($2 + 1, $3) - 1 END;
$$;

CREATE OR REPLACE FUNCTION materialization.materialize(materialization.type, "timestamp" timestamp with time zone)
  RETURNS materialization.materialization_result
AS $$
DECLARE
  table_name character varying;
  src trend.trendstore;
  dst trend.trendstore;
  dst_partition trend.partition;
  columns_part text;
  result materialization.materialization_result;
  mat_state materialization.state;
  mat_fingerprint text;
BEGIN
  SELECT * INTO src FROM trend.trendstore WHERE id = $1.src_trendstore_id;
  SELECT * INTO dst FROM trend.trendstore WHERE id = $1.dst_trendstore_id;

  table_name = trend.to_base_table_name(src);

  PERFORM materialization.add_missing_trends($1);
  PERFORM materialization.modify_mismatching_trends($1);

  dst_partition = trend.attributes_to_partition(dst, trend.timestamp_to_index(dst.partition_size, $2));

  SELECT * INTO STRICT mat_state
    FROM materialization.state
    WHERE type_id = $1.id
      AND state.timestamp = $2;

  SELECT fingerprint INTO mat_fingerprint
    FROM materialization.state_fingerprint
    WHERE type_id = $1.id
      AND state_fingerprint.timestamp = $2;

  IF mat_state.source_states IS DISTINCT FROM mat_state.partial_states OR mat_state.partials_processed = $1.partials
  THEN
    -- restart from first partial, because either:
    -- * source_states changed
    -- * manual rematerialization

    IF mat_state.partial_states IS NOT NULL
    THEN
      IF mat_state.source_states IS DISTINCT FROM mat_state.partial_states
      THEN
        RAISE WARNING 'restarting partial materialization for % -> % (type %) timestamp %, reason: source states changed', src::text, dst::text, $1.id, $2;
      ELSE
        RAISE WARNING 'restarting partial materialization for % -> % (type %) timestamp %, reason: rematerialization', src::text, dst::text, $1.id, $2;
      END IF;
    END IF;

    UPDATE materialization.state
    SET partial_states = source_states,
      partials_processed = 0
    WHERE type_id = mat_state.type_id
      AND state.timestamp = mat_state.timestamp;

    mat_state.partial_states = mat_state.source_states;
    mat_state.partials_processed = 0;
  END IF;

  EXECUTE format(
    'DELETE FROM trend.%I WHERE timestamp = $1 AND materialization.entity_in_partial(entity_id, $2, $3)',
    dst_partition.table_name, mat_state.partials_processed, $1.partials
  )
    USING $2, mat_state.partials_processed, $1.partials;

  SELECT array_to_string(array_agg(quote_ident(name)), ', ') INTO STRICT columns_part
  FROM
    trend.table_columns('trend', table_name);

  -- Functions should perform better than views, so use it when it exists.
  IF materialization.has_function($1) THEN
    -- TODO: use partial in function
    EXECUTE format(
      'INSERT INTO trend.%I (%s) SELECT %s FROM trend_transform.%I($1)',
      dst_partition.table_name, columns_part, columns_part, trend.to_base_table_name(dst)
    )
    USING $2;

    -- HACK: finish partial materialization because the function has no knowledge of partials
    mat_state.partials_processed = $1.partials - 1;
  ELSE
    EXECUTE format(
      'INSERT INTO trend.%I (%s) SELECT %s FROM trend.%I WHERE timestamp = $1 AND materialization.entity_in_partial(entity_id, $2, $3)',
      dst_partition.table_name, columns_part, columns_part, table_name
    )
    USING $2, mat_state.partials_processed, $1.partials;
  END IF;

  GET DIAGNOSTICS result.row_count = ROW_COUNT;
  RAISE NOTICE 'materialized % rows for partial % for % -> % timestamp %', result.row_count, mat_state.partials_processed, src::text, dst::text, $2;

  IF mat_state.partials_processed + 1 = $1.partials OR materialization.has_function($1) THEN
    -- this is the final (or the only) partial materialization

    UPDATE materialization.state
    SET processed_states = mat_state.source_states,
      partials_processed = $1.partials
    WHERE type_id = $1.id
      AND state.timestamp = $2;

    UPDATE materialization.state_fingerprint SET processed_fingerprint = mat_fingerprint
    WHERE
      state_fingerprint.type_id = $1.id AND
      state_fingerprint.timestamp = $2;

    PERFORM trend.mark_modified(dst_partition.table_name, $2);
  ELSE
    UPDATE materialization.state
    SET partials_processed = mat_state.partials_processed + 1
    WHERE type_id = $1.id
      AND state.timestamp = $2;

    -- schedule the next partial materialization job
    PERFORM materialization.create_job($1.id, $2);
  END IF;

  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION materialization.materialize(src_trendstore_id integer, dst_trendstore_id integer, "timestamp" timestamp with time zone)
    RETURNS materialization.materialization_result
AS $$
    SELECT materialization.materialize(type, $3)
    FROM materialization.type
    WHERE src_trendstore_id = $1 ANd dst_trendstore_id = $2;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.materialize(materialization text, "timestamp" timestamp with time zone)
    RETURNS materialization.materialization_result
AS $$
    SELECT materialization.materialize(mt.src_trendstore_id, mt.dst_trendstore_id, $2)
    FROM materialization.type mt
    WHERE materialization.to_char(mt) = $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.materialize(id integer, "timestamp" timestamp with time zone)
    RETURNS materialization.materialization_result
AS $$
    SELECT materialization.materialize(type, $2)
    FROM materialization.type
    WHERE id = $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.default_processing_delay(granularity character varying)
    RETURNS interval
AS $$
    SELECT CASE
        WHEN $1 = '1800' OR $1 = '900' OR $1 = '300' THEN
            interval '0 seconds'
        WHEN $1 = '3600' THEN
            interval '15 minutes'
        ELSE
            interval '3 hours'
        END;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION materialization.default_stability_delay(granularity character varying)
    RETURNS interval
AS $$
    SELECT CASE
        WHEN $1 = '1800' OR $1 = '900' OR $1 = '300' THEN
            interval '180 seconds'
        WHEN $1 = '3600' THEN
            interval '5 minutes'
        ELSE
            interval '15 minutes'
        END;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION materialization.define(src_trendstore_id integer, dst_trendstore_id integer)
    RETURNS materialization.type
AS $$
    INSERT INTO materialization.type (src_trendstore_id, dst_trendstore_id, processing_delay, stability_delay, reprocessing_period)
    SELECT $1, $2, materialization.default_processing_delay(granularity), materialization.default_stability_delay(granularity), interval '3 days'
    FROM trend.trendstore WHERE id = $2
    RETURNING type;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.define(src trend.trendstore, dst trend.trendstore)
    RETURNS materialization.type
AS $$
    SELECT materialization.define($1.id, $2.id);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.define(text, text)
    RETURNS materialization.type
AS $$
    SELECT
        materialization.define(src.id, dst.id)
    FROM
        trend.trendstore src,
        trend.trendstore dst
    WHERE src::text = $1 AND dst::text = $2;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.define(trend.trendstore)
    RETURNS materialization.type
AS $$
    SELECT materialization.add_missing_trends(
        materialization.define(
            $1,
            trend.attributes_to_trendstore(substring(ds.name, '^v(.*)'), et.name, ts.granularity)
        )
    )
    FROM trend.view
    JOIN trend.trendstore ts on ts.id = view.trendstore_id
    JOIN directory.datasource ds on ds.id = ts.datasource_id
    JOIN directory.entitytype et on et.id = ts.entitytype_id
    WHERE view.trendstore_id = $1.id;
$$ LANGUAGE SQL VOLATILE;

COMMENT ON FUNCTION materialization.define(trend.trendstore)
IS 'Defines a new materialization with the convention that the datasource of
the source trendstore should start with a ''v'' for views and that the
destination trendstore has the same properties except for a datasource with a
name without the leading ''v''. A new trendstore and datasource are created if
they do not exist.';


CREATE OR REPLACE FUNCTION materialization.define(trend.view)
    RETURNS materialization.type
AS $$
    SELECT materialization.add_missing_trends(
        materialization.define(
            ts,
            trend.attributes_to_trendstore(substring(ds.name, '^v(.*)'), et.name, ts.granularity)
        )
    )
    FROM trend.trendstore ts
    JOIN directory.datasource ds on ds.id = ts.datasource_id
    JOIN directory.entitytype et on et.id = ts.entitytype_id
    WHERE ts.id = $1.trendstore_id;
$$ LANGUAGE SQL VOLATILE;

COMMENT ON FUNCTION materialization.define(trend.view)
IS 'Defines a new materialization with the convention that the datasource of
the source trendstore should start with a ''v'' for views and that the
destination trendstore has the same properties except for a datasource with a
name without the leading ''v''. A new trendstore and datasource are created if
they do not exist.';


CREATE OR REPLACE FUNCTION materialization.define(
        regprocedure, trend.trendstore)
    RETURNS materialization.type
AS $$
    SELECT materialization.add_missing_trends(
        materialization.define(
            NULL::trend.trendstore,
            $2
        )
    );
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.render_job_json(type_id integer, timestamp with time zone)
    RETURNS character varying
AS $$
    SELECT format('{"type_id": %s, "timestamp": "%s"}', $1, $2);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION materialization.create_job(type_id integer, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    description text;
    new_job_id integer;
BEGIN
    description := materialization.render_job_json(type_id, "timestamp");

    SELECT system.create_job('materialize', description, 1, job_source.id) INTO new_job_id
        FROM system.job_source
        WHERE name = 'compile-materialize-jobs';

    UPDATE materialization.state
        SET job_id = new_job_id
        WHERE state.type_id = $1 AND state.timestamp = $2;

    UPDATE materialization.state_fingerprint
        SET job_id = new_job_id
        WHERE state_fingerprint.type_id = $1 AND state_fingerprint.timestamp = $2;

    RETURN new_job_id;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION materialization.source_data_ready(type materialization.type, "timestamp" timestamp with time zone, max_modified timestamp with time zone)
    RETURNS boolean
AS $$
    SELECT
        $2 < now() - $1.processing_delay AND
        $3 < now() - $1.stability_delay;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION materialization.runnable(type materialization.type, "timestamp" timestamp with time zone, max_modified timestamp with time zone)
    RETURNS boolean
AS $$
    SELECT
        $1.enabled AND
        materialization.source_data_ready($1, $2, $3) AND
        ($1.reprocessing_period IS NULL OR now() - $2 < $1.reprocessing_period);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION materialization.runnable(materialization.type, materialization.state)
    RETURNS boolean
AS $$
    SELECT materialization.runnable($1, $2.timestamp, $2.max_modified);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION materialization.runnable(materialization.type, materialization.state_fingerprint)
    RETURNS boolean
AS $$
    SELECT materialization.runnable($1, $2.timestamp, $2.modified);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION materialization.open_job_slots(slot_count integer)
    RETURNS integer
AS $$
    SELECT greatest($1 - COUNT(*), 0)::integer
    FROM system.job
    WHERE type = 'materialize' AND (state = 'running' OR state = 'queued');
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION materialization.tag(tag_name character varying, type_id integer)
    RETURNS materialization.type_tag_link
AS $$
    INSERT INTO materialization.type_tag_link (type_id, tag_id)
    SELECT $2, tag.id FROM directory.tag WHERE name = $1
    RETURNING *;
$$ LANGUAGE SQL VOLATILE;

COMMENT ON FUNCTION materialization.tag(character varying, type_id integer)
IS 'Add tag with name tag_name to materialization type with id type_id.
The tag must already exist.';


CREATE OR REPLACE FUNCTION materialization.tag(tag_name character varying, materialization.type)
    RETURNS materialization.type
AS $$
    INSERT INTO materialization.type_tag_link (type_id, tag_id)
    SELECT $2.id, tag.id FROM directory.tag WHERE name = $1
    RETURNING $2;
$$ LANGUAGE SQL VOLATILE;

COMMENT ON FUNCTION materialization.tag(character varying, materialization.type)
IS 'Add tag with name tag_name to materialization type. The tag must already exist.';


CREATE OR REPLACE FUNCTION materialization.untag(materialization.type)
    RETURNS materialization.type
AS $$
    DELETE FROM materialization.type_tag_link WHERE type_id = $1.id RETURNING $1;
$$ LANGUAGE SQL VOLATILE;

COMMENT ON FUNCTION materialization.untag(materialization.type)
IS 'Remove all tags from the materialization';


CREATE OR REPLACE FUNCTION materialization.reset(type_id integer)
    RETURNS SETOF materialization.state
AS $$
    UPDATE materialization.state SET processed_states = NULL
    WHERE
        type_id = $1 AND
        source_states = processed_states
    RETURNING *;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.reset_hard(materialization.type)
    RETURNS void
AS $$
    DELETE FROM trend.partition WHERE trendstore_id = $1.dst_trendstore_id;
    DELETE FROM materialization.state WHERE type_id = $1.id;
$$ LANGUAGE SQL VOLATILE;

COMMENT ON FUNCTION materialization.reset_hard(materialization.type)
IS 'Remove data (partitions) resulting from this materialization and the
corresponding state records, so materialization for all timestamps can be done
again';


CREATE OR REPLACE FUNCTION materialization.reset(type_id integer, timestamp with time zone)
    RETURNS materialization.state
AS $$
    UPDATE materialization.state SET processed_states = NULL
    WHERE type_id = $1 AND timestamp = $2
    RETURNING *;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.reset(materialization.type, timestamp with time zone)
    RETURNS materialization.state
AS $$
    SELECT materialization.reset($1.id, $2);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.enable(materialization.type)
    RETURNS materialization.type
AS $$
    UPDATE materialization.type SET enabled = true WHERE id = $1.id RETURNING type;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.disable(materialization.type)
    RETURNS materialization.type
AS $$
    UPDATE materialization.type SET enabled = false WHERE id = $1.id RETURNING type;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization.fragments(materialization.source_fragment_state[])
    RETURNS materialization.source_fragment[]
AS $$
    SELECT array_agg(fragment) FROM unnest($1);
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION materialization.requires_update(materialization.state)
    RETURNS boolean
AS $$
    SELECT (
        $1.source_states <> $1.processed_states AND
        materialization.fragments($1.source_states) @> materialization.fragments($1.processed_states)
    )
    OR $1.processed_states IS NULL;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION materialization.dependencies(trend.trendstore, level integer)
    RETURNS TABLE(trendstore trend.trendstore, level integer)
AS $$
-- Stub to allow recursive definition.
    SELECT $1, $2;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION materialization.direct_view_dependencies(trend.trendstore)
    RETURNS SETOF trend.trendstore
AS $$
    SELECT trendstore
    FROM trend.trendstore
    JOIN trend.view_trendstore_link vtl ON vtl.trendstore_id = trendstore.id
    JOIN trend.view ON view.id = vtl.view_id
    WHERE view.trendstore_id = $1.id;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION materialization.direct_table_dependencies(trend.trendstore)
    RETURNS SETOF trend.trendstore
AS $$
    SELECT trendstore
    FROM trend.trendstore
    JOIN materialization.type ON type.src_trendstore_id = trendstore.id
    WHERE dst_trendstore_id = $1.id;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION materialization.direct_dependencies(trend.trendstore)
    RETURNS SETOF trend.trendstore
AS $$
    SELECT
    CASE WHEN $1.type = 'view' THEN
        materialization.direct_view_dependencies($1)
    WHEN $1.type = 'table' THEN
        materialization.direct_table_dependencies($1)
    END;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION materialization.dependencies(trend.trendstore, level integer)
    RETURNS TABLE(trendstore trend.trendstore, level integer)
AS $$
    SELECT (d.dependencies).* FROM (
        SELECT materialization.dependencies(dependency, $2 + 1)
        FROM materialization.direct_dependencies($1) dependency
    ) d
    UNION ALL
    SELECT dependency, $2
    FROM materialization.direct_dependencies($1) dependency;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION materialization.dependencies(trend.trendstore)
    RETURNS TABLE(trendstore trend.trendstore, level integer)
AS $$
    SELECT materialization.dependencies($1, 1);
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION materialization.dependencies(name text)
    RETURNS TABLE(trendstore trend.trendstore, level integer)
AS $$
    SELECT materialization.dependencies(trendstore) FROM trend.trendstore WHERE trend.to_char(trendstore) = $1;
$$ LANGUAGE SQL STABLE;


-- View 'runnable_materializations'

CREATE OR REPLACE view materialization.runnable_materializations AS
SELECT type, state
FROM materialization.state
JOIN materialization.type ON type.id = state.type_id
WHERE
    materialization.requires_update(state)
    AND
    materialization.runnable(type, state."timestamp", state.max_modified);

ALTER VIEW materialization.runnable_materializations OWNER TO minerva_admin;


-- View 'runnable_materializations_fingerprint'

CREATE OR REPLACE view materialization.runnable_materializations_fingerprint AS
SELECT type, state
FROM materialization.state_fingerprint state
JOIN materialization.type ON type.id = state.type_id
WHERE
    (
        state.fingerprint <> state.processed_fingerprint
        OR
        state.processed_fingerprint IS NULL
    )
    AND
    materialization.runnable(type, state);

ALTER VIEW materialization.runnable_materializations_fingerprint OWNER TO minerva_admin;


-- View 'next_up_materializations'

CREATE OR REPLACE VIEW materialization.next_up_materializations AS
SELECT type_id, timestamp, (tag).name, cost, cumsum, resources AS group_resources, (job.id IS NOT NULL AND job.state IN ('queued', 'running')) AS job_active FROM
(
    SELECT
        (rm.type).id AS type_id,
        (rm.state).timestamp,
        tag,
        (rm.type).cost,
        sum((rm.type).cost) over (partition by tag.name order by trend.granularity_seconds(ts.granularity) asc, (rm.state).timestamp desc, rm.type) as cumsum,
        (rm.state).job_id
    FROM materialization.runnable_materializations rm
    JOIN trend.trendstore ts ON ts.id = (rm.type).dst_trendstore_id
    JOIN materialization.type_tag_link ttl ON ttl.type_id = (rm.type).id
    JOIN directory.tag ON tag.id = ttl.tag_id
) summed
JOIN materialization.group_priority ON (summed.tag).id = group_priority.tag_id
LEFT JOIN system.job ON job.id = job_id
WHERE cumsum <= group_priority.resources;

ALTER VIEW materialization.next_up_materializations OWNER TO minerva_admin;

-- View 'next_up_materializations_fingerprint'

CREATE OR REPLACE VIEW materialization.next_up_materializations_fingerprint AS
SELECT
    type_id,
    timestamp,
    (tag).name,
    cost,
    cumsum,
    resources AS group_resources,
    (job.id IS NOT NULL AND job.state IN ('queued', 'running')) AS job_active
FROM
(
    SELECT
        (rm.type).id AS type_id,
        (rm.state).timestamp,
        tag,
        (rm.type).cost,
        sum((rm.type).cost) OVER (partition BY tag.name ORDER BY trend.granularity_seconds(ts.granularity) ASC, (rm.state).timestamp DESC, rm.type) AS cumsum,
        (rm.state).job_id
    FROM materialization.runnable_materializations_fingerprint rm
    JOIN trend.trendstore ts ON ts.id = (rm.type).dst_trendstore_id
    JOIN materialization.type_tag_link ttl ON ttl.type_id = (rm.type).id
    JOIN directory.tag ON tag.id = ttl.tag_id
) summed
JOIN materialization.group_priority ON (summed.tag).id = group_priority.tag_id
LEFT JOIN system.job ON job.id = job_id
WHERE cumsum <= group_priority.resources;

ALTER VIEW materialization.next_up_materializations OWNER TO minerva_admin;


CREATE OR REPLACE FUNCTION materialization.create_jobs()
    RETURNS integer
    LANGUAGE sql
AS $function$
    SELECT COUNT(materialization.create_job(num.type_id, timestamp))::integer
    FROM materialization.next_up_materializations num
    WHERE NOT job_active;
$function$;

