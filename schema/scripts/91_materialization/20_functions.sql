CREATE FUNCTION materialization.to_char(materialization.type)
    RETURNS text
AS $$
    SELECT trend_directory.base_table_name(view_trend_store) || ' -> ' || trend_directory.base_table_name(table_trend_store)
    FROM trend_directory.view_trend_store, trend_directory.table_trend_store
    WHERE view_trend_store.id = $1.view_trend_store_id AND table_trend_store.id = $1.table_trend_store_id
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION materialization.add_new_state()
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


CREATE FUNCTION materialization.update_modified_state()
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


CREATE FUNCTION materialization.delete_obsolete_state()
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


CREATE FUNCTION materialization.update_state()
    RETURNS text
AS $$
    SELECT 'added: ' || materialization.add_new_state() || ', updated: ' || materialization.update_modified_state() || ', deleted: ' || materialization.delete_obsolete_state();
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION materialization.materialize(type materialization.type, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    src_trend_store trend_directory.view_trend_store;
    dst_trend_store trend_directory.table_trend_store;
    view_name character varying;
    dst_table_name character varying;
    dst_partition trend_directory.partition;
    sources_query character varying;
    data_query character varying;
    conn_str character varying;
    columns_part character varying;
    column_defs_part character varying;
    modified timestamp with time zone;
    row_count integer;
    replicated_server_conn system.setting;
    tmp_source_states materialization.source_fragment_state[];
BEGIN
    SELECT * INTO src_trend_store FROM trend_directory.view_trend_store WHERE id = type.view_trend_store_id;
    SELECT * INTO dst_trend_store FROM trend_directory.table_trend_store WHERE id = type.table_trend_store_id;

    view_name = trend_directory.base_table_name(src_trend_store);
    dst_table_name = trend_directory.base_table_name(dst_trend_store);

    dst_partition = trend_directory.attributes_to_partition(
        dst_trend_store,
        trend_directory.timestamp_to_index(dst_trend_store.partition_size, "timestamp")
    );

    PERFORM trend_directory.clear_timestamp(dst_trend_store, timestamp);

    SELECT
        array_to_string(array_agg(quote_ident(name)), ', ') INTO columns_part
    FROM
        trend_directory.table_columns(trend_directory.view_schema(), view_name);

    sources_query = format(
        'SELECT source_states
    FROM materialization.materializables mz
    JOIN materialization.type ON type.id = mz.type_id
    WHERE
        mz.timestamp = %L AND mz.type_id = %L;',
        "timestamp",
        type.id
    );

    data_query = format(
        'SELECT %s FROM %I.%I WHERE timestamp = %L',
        columns_part, trend_directory.view_schema(), view_name, timestamp
    );

    replicated_server_conn = system.get_setting('replicated_server_conn');

    IF replicated_server_conn IS NULL THEN
        -- Local materialization
        EXECUTE sources_query INTO tmp_source_states;
        EXECUTE format(
            'INSERT INTO %I.%I (%s) %s',
            trend_directory.partition_table_schema(),
            trend_directory.table_name(dst_partition),
            columns_part,
            data_query
        );
    ELSE
        -- Remote materialization
        conn_str = replicated_server_conn.value;

        SELECT
            array_to_string(array_agg(format('%I %s', col.name, col.data_type)), ', ') INTO column_defs_part
        FROM
            trend_directory.table_columns(trend_directory.base_table_schema(), view_name) col;

        SELECT sources INTO tmp_source_states
        FROM public.dblink(conn_str, sources_query) AS r (sources materialization.source_fragment_state[]);

        EXECUTE format(
            'INSERT INTO %I.%I (%s) SELECT * FROM public.dblink(%L, %L) AS rel (%s)',
            trend_directory.partition_table_name(),
            trend_directory.table_name(dst_partition),
            columns_part,
            conn_str,
            data_query,
            column_defs_part
        );
    END IF;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    UPDATE materialization.state
    SET processed_states = tmp_source_states
    WHERE state.type_id = $1.id AND state.timestamp = $2;

    IF row_count > 0 THEN
        PERFORM trend_directory.mark_modified($1.table_trend_store_id, "timestamp");
    END IF;

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION materialization.materialize(materialization text, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
    SELECT materialization.materialize(type, $2)
    FROM materialization.type
    WHERE materialization.to_char(type) = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION materialization.materialize(id integer, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
    SELECT materialization.materialize(type, $2)
    FROM materialization.type
    WHERE id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION materialization.default_processing_delay(granularity interval)
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


CREATE FUNCTION materialization.default_stability_delay(granularity interval)
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


CREATE FUNCTION materialization.define(view_trend_store_id integer, table_trend_store_id integer)
    RETURNS materialization.type
AS $$
    INSERT INTO materialization.type (
        view_trend_store_id,
        table_trend_store_id,
        processing_delay,
        stability_delay,
        reprocessing_period
    )
    SELECT
        $1,
        $2,
        materialization.default_processing_delay(granularity),
        materialization.default_stability_delay(granularity),
        interval '3 days'
    FROM trend_directory.trend_store
    WHERE id = $2
    RETURNING type;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION materialization.define(src trend_directory.view_trend_store, dst trend_directory.table_trend_store)
    RETURNS materialization.type
AS $$
    SELECT materialization.define($1.id, $2.id);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION materialization.define(text, text)
    RETURNS materialization.type
AS $$
    SELECT
        materialization.define(view_trend_store.id, table_trend_store.id)
    FROM
        trend_directory.view_trend_store,
        trend_directory.table_trend_store
    WHERE view_trend_store::text = $1 AND table_trend_store::text = $2;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION materialization.define(trend_directory.view_trend_store)
    RETURNS materialization.type
AS $$
    SELECT materialization.define(
        $1,
        trend_directory.attributes_to_table_trend_store(
            substring(data_source.name, '^v(.*)'),
            entity_type.name,
            $1.granularity,
            array_agg((view_trend.name, view_trend.data_type, view_trend.description)::trend_directory.trend_descr)
        )
    )
    FROM
        directory.data_source,
        directory.entity_type,
        trend_directory.view_trend
    WHERE
        data_source.id = $1.data_source_id
        AND
        entity_type.id = $1.entity_type_id
        AND
        view_trend.trend_store_id = $1.id
    GROUP BY
        data_source.id, entity_type.id;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION materialization.define(trend_directory.view_trend_store)
IS 'Defines a new materialization with the convention that the data_source of
the source trend_store should start with a ''v'' for views and that the
destination trend_store has the same properties except for a data_source with a
name without the leading ''v''. A new trend_store and data_source are created if
they do not exist.';


CREATE FUNCTION materialization.materialized_data_source_name(name character varying)
  RETURNS character varying
AS $$
BEGIN
  IF NOT name ~ '^v.*' THEN
    RAISE EXCEPTION '% does not start with a ''v''', name;
  ELSE
    RETURN substring(name, '^v(.*)');
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE FUNCTION materialization.render_job_json(type_id integer, timestamp with time zone)
    RETURNS json
AS $$
    SELECT format('{"type_id": %s, "timestamp": "%s"}', $1, $2)::json;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION materialization.get_materialization_job_source()
    RETURNS system.job_source
AS $$
    SELECT *
    FROM system.job_source
    WHERE name = 'compile-materialize-jobs';
$$ LANGUAGE sql STABLE;


CREATE FUNCTION materialization.create_job(type_id integer, "timestamp" timestamp with time zone)
    RETURNS system.job
AS $$
    UPDATE materialization.state
    SET job_id = job.id
    FROM system.create_job(
        'materialize',
        materialization.render_job_json($1, $2),
        1,
        (materialization.get_materialization_job_source()).id
    ) AS job
    WHERE state.type_id = $1 AND state.timestamp = $2
    RETURNING job;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION materialization.source_data_ready(type materialization.type, "timestamp" timestamp with time zone, max_modified timestamp with time zone)
    RETURNS boolean
AS $$
    SELECT
        $2 < now() - $1.processing_delay AND
        $3 < now() - $1.stability_delay;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION materialization.runnable(type materialization.type, "timestamp" timestamp with time zone, max_modified timestamp with time zone)
    RETURNS boolean
AS $$
    SELECT
        $1.enabled AND
        materialization.source_data_ready($1, $2, $3) AND
        ($1.reprocessing_period IS NULL OR now() - $2 < $1.reprocessing_period);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION materialization.runnable(materialization.type, materialization.state)
    RETURNS boolean
AS $$
    SELECT materialization.runnable($1, $2.timestamp, $2.max_modified);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION materialization.open_job_slots(slot_count integer)
    RETURNS integer
AS $$
    SELECT greatest($1 - COUNT(*), 0)::integer
    FROM system.job
    WHERE type = 'materialize' AND (state = 'running' OR state = 'queued');
$$ LANGUAGE sql STABLE;


CREATE FUNCTION materialization.tag(tag_name character varying, type_id integer)
    RETURNS materialization.type_tag_link
AS $$
    INSERT INTO materialization.type_tag_link (type_id, tag_id)
    SELECT $2, tag.id FROM directory.tag WHERE name = $1
    RETURNING *;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION materialization.tag(character varying, type_id integer)
IS 'Add tag with name tag_name to materialization type with id type_id.
The tag must already exist.';


CREATE FUNCTION materialization.tag(tag_name character varying, materialization.type)
    RETURNS materialization.type
AS $$
    INSERT INTO materialization.type_tag_link (type_id, tag_id)
    SELECT $2.id, tag.id FROM directory.tag WHERE name = $1
    RETURNING $2;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION materialization.tag(character varying, materialization.type)
IS 'Add tag with name tag_name to materialization type. The tag must already exist.';


CREATE FUNCTION materialization.untag(materialization.type)
    RETURNS materialization.type
AS $$
    DELETE FROM materialization.type_tag_link WHERE type_id = $1.id RETURNING $1;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION materialization.untag(materialization.type)
IS 'Remove all tags from the materialization';


CREATE FUNCTION materialization.reset(type_id integer)
    RETURNS SETOF materialization.state
AS $$
    UPDATE materialization.state SET processed_states = NULL
    WHERE
        type_id = $1 AND
        source_states = processed_states
    RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION materialization.reset_hard(materialization.type)
    RETURNS void
AS $$
    DELETE FROM trend_directory.partition WHERE table_trend_store_id = $1.table_trend_store_id;
    DELETE FROM materialization.state WHERE type_id = $1.id;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION materialization.reset_hard(materialization.type)
IS 'Remove data (partitions) resulting from this materialization and the
corresponding state records, so materialization for all timestamps can be done
again';


CREATE FUNCTION materialization.reset(type_id integer, timestamp with time zone)
    RETURNS materialization.state
AS $$
    UPDATE materialization.state SET processed_states = NULL
    WHERE type_id = $1 AND timestamp = $2
    RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION materialization.reset(materialization.type, timestamp with time zone)
    RETURNS materialization.state
AS $$
    SELECT materialization.reset($1.id, $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION materialization.enable(materialization.type)
    RETURNS materialization.type
AS $$
    UPDATE materialization.type SET enabled = true WHERE id = $1.id RETURNING type;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION materialization.disable(materialization.type)
    RETURNS materialization.type
AS $$
    UPDATE materialization.type SET enabled = false WHERE id = $1.id RETURNING type;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION materialization.fragments(materialization.source_fragment_state[])
    RETURNS materialization.source_fragment[]
AS $$
    SELECT array_agg(fragment) FROM unnest($1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION materialization.requires_update(materialization.state)
    RETURNS boolean
AS $$
    SELECT (
        $1.source_states <> $1.processed_states AND
        materialization.fragments($1.source_states) @> materialization.fragments($1.processed_states)
    )
    OR $1.processed_states IS NULL;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION materialization.no_slave_lag()
    RETURNS boolean
AS $$
SELECT bytes_lag < 10000000
FROM metric.replication_lag
WHERE client_addr = '192.168.42.19';
$$ LANGUAGE sql;


-- View 'runnable_materializations'

CREATE view materialization.runnable_materializations AS
SELECT type, state
FROM materialization.state
JOIN materialization.type ON type.id = state.type_id
WHERE
    materialization.requires_update(state)
    AND
    materialization.runnable(type, materialization.state."timestamp", materialization.state.max_modified);


-- View 'next_up_materializations'

CREATE VIEW materialization.next_up_materializations AS
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
        sum((rm.type).cost) over (partition by tag.name order by ts.granularity asc, (rm.state).timestamp desc, rm.type) as cumsum,
        (rm.state).job_id
    FROM materialization.runnable_materializations rm
    JOIN trend_directory.table_trend_store ts ON ts.id = (rm.type).table_trend_store_id
    JOIN materialization.type_tag_link ttl ON ttl.type_id = (rm.type).id
    JOIN directory.tag ON tag.id = ttl.tag_id
) summed
JOIN materialization.group_priority ON (summed.tag).id = group_priority.tag_id
LEFT JOIN system.job ON job.id = job_id
WHERE cumsum <= group_priority.resources;


CREATE FUNCTION materialization.create_jobs()
    RETURNS integer
AS $$
    SELECT COUNT(materialization.create_job(num.type_id, timestamp))::integer
    FROM materialization.next_up_materializations num
    WHERE NOT job_active AND materialization.no_slave_lag();
$$ LANGUAGE sql;

