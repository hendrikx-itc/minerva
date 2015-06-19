SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = materialization, pg_catalog;


CREATE OR REPLACE FUNCTION to_char(materialization.type)
	RETURNS text
AS $$
	SELECT trend.to_base_table_name(src) || ' -> ' || trend.to_base_table_name(dst)
	FROM trend.trendstore src, trend.trendstore dst
	WHERE src.id = $1.src_trendstore_id AND dst.id = $1.dst_trendstore_id
$$ LANGUAGE SQL STABLE STRICT;


CREATE OR REPLACE FUNCTION add_new_state()
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


CREATE OR REPLACE FUNCTION update_modified_state()
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


CREATE OR REPLACE FUNCTION delete_obsolete_state()
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


CREATE OR REPLACE FUNCTION update_state()
	RETURNS text
AS $$
	SELECT 'added: ' || materialization.add_new_state() || ', updated: ' || materialization.update_modified_state() || ', deleted: ' || materialization.delete_obsolete_state();
$$ LANGUAGE SQL VOLATILE;


CREATE TYPE materialization_result AS (processed_max_modified timestamp with time zone, row_count integer);


CREATE OR REPLACE FUNCTION missing_columns(src trend.trendstore, dst trend.trendstore)
	RETURNS TABLE (name character varying, datatype character varying)
AS $$
	SELECT name, datatype
	FROM trend.table_columns('trend', trend.to_base_table_name($1))
	WHERE name NOT IN (
		SELECT name FROM trend.table_columns('trend', trend.to_base_table_name($2))
	);
$$ LANGUAGE SQL STABLE;

COMMENT ON FUNCTION missing_columns(src trend.trendstore, dst trend.trendstore)
IS 'The set of table columns (name, datatype) that exist in the source trendstore but not yet in the destination.';


CREATE OR REPLACE FUNCTION missing_columns(materialization.type)
	RETURNS TABLE (name character varying, datatype character varying)
AS $$
	SELECT materialization.missing_columns(src, dst)
	FROM trend.trendstore src, trend.trendstore dst
	WHERE src.id = $1.src_trendstore_id AND dst.id = $1.dst_trendstore_id;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION add_missing_trends(src trend.trendstore, dst trend.trendstore)
	RETURNS bigint
AS $$
	SELECT count(trend.add_trend_to_trendstore($2, name, datatype))
	FROM materialization.missing_columns($1, $2);
$$ LANGUAGE SQL VOLATILE;

COMMENT ON FUNCTION add_missing_trends(src trend.trendstore, dst trend.trendstore)
IS 'Add trends and actual table columns to destination that exist in the source
trendstore but not yet in the destination.';


CREATE OR REPLACE FUNCTION add_missing_trends(materialization.type)
	RETURNS materialization.type
AS $$
	SELECT materialization.add_missing_trends(src, dst)
	FROM trend.trendstore src, trend.trendstore dst
	WHERE src.id = $1.src_trendstore_id AND dst.id = $1.dst_trendstore_id;

	SELECT $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION modify_mismatching_trends(src trend.trendstore, dst trend.trendstore)
	RETURNS void
AS $$
	SELECT trend.modify_trendstore_columns($2.id, array_agg(src_column))
	FROM trend.table_columns('trend', trend.to_base_table_name($1)) src_column
	JOIN trend.table_columns('trend', trend.to_base_table_name($2)) dst_column ON
		src_column.name = dst_column.name
			AND
		src_column.datatype <> dst_column.datatype;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION modify_mismatching_trends(materialization.type)
	RETURNS void
AS $$
	SELECT materialization.modify_mismatching_trends(src, dst)
	FROM trend.trendstore src, trend.trendstore dst
	WHERE src.id = $1.src_trendstore_id AND dst.id = $1.dst_trendstore_id;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialize(src trend.trendstore, dst trend.trendstore, "timestamp" timestamp with time zone)
	RETURNS materialization_result
AS $$
DECLARE
	schema_name character varying;
	table_name character varying;
	dst_table_name character varying;
	dst_partition trend.partition;
	sources_query character varying;
	data_query character varying;
	conn_str character varying;
	columns_part character varying;
	column_defs_part character varying;
	modified timestamp with time zone;
	row_count integer;
	result materialization.materialization_result;
	replicated_server_conn system.setting;
	tmp_source_states materialization.source_fragment_state[];
BEGIN
	schema_name = 'trend';
	table_name = trend.to_base_table_name(src);
	dst_table_name = trend.to_base_table_name(dst);

	PERFORM materialization.add_missing_trends($1, $2);
	PERFORM materialization.modify_mismatching_trends($1, $2);

	dst_partition = trend.attributes_to_partition(dst, trend.timestamp_to_index(dst.partition_size, $3));
	EXECUTE format('DELETE FROM trend.%I WHERE timestamp = %L', dst_partition.table_name, timestamp);

	SELECT
		array_to_string(array_agg(quote_ident(name)), ', ') INTO columns_part
	FROM
		trend.table_columns(schema_name, table_name);

	sources_query = format('SELECT source_states
	FROM materialization.materializables mz
	JOIN materialization.type ON type.id = mz.type_id
	WHERE
		mz.timestamp = %L AND
		type.src_trendstore_id = %L AND
		type.dst_trendstore_id = %L;', $3, src.id, dst.id);

	data_query = format('SELECT %s FROM %I.%I WHERE timestamp = %L',
		columns_part, schema_name, table_name, timestamp);

	replicated_server_conn = system.get_setting('replicated_server_conn');

	IF replicated_server_conn IS NULL THEN
		-- Local materialization
		EXECUTE sources_query INTO tmp_source_states;
		EXECUTE format('INSERT INTO trend.%I (%s) %s', dst_partition.table_name, columns_part, data_query);
	ELSE
		-- Remote materialization
		conn_str = replicated_server_conn.value;

		SELECT
			array_to_string(array_agg(format('%I %s', col.name, col.datatype)), ', ') INTO column_defs_part
		FROM
			trend.table_columns(schema_name, table_name) col;

		SELECT sources INTO tmp_source_states
		FROM public.dblink(conn_str, sources_query) AS r (sources materialization.source_fragment_state[]);

		EXECUTE format('INSERT INTO trend.%I (%s) SELECT * FROM public.dblink(%L, %L) AS rel (%s)',
			dst_partition.table_name, columns_part, conn_str, data_query, column_defs_part);
	END IF;

	GET DIAGNOSTICS result.row_count = ROW_COUNT;

	UPDATE materialization.state SET processed_states = tmp_source_states
	FROM materialization.type
	WHERE type.id = state.type_id AND state.timestamp = $3
	AND type.src_trendstore_id = $1.id
	AND type.dst_trendstore_id = $2.id;

	IF result.row_count = 0 THEN
		RAISE NOTICE 'NO ROWS materialized FOR materialization of % -> %, %', src::text, dst::text, timestamp;
		RETURN result;
	END IF;

	PERFORM trend.mark_modified(dst_partition.table_name, "timestamp");

	RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION materialize(src_trendstore_id integer, dst_trendstore_id integer, "timestamp" timestamp with time zone)
	RETURNS materialization_result
AS $$
	SELECT materialization.materialize(src, dst, $3)
		FROM trend.trendstore src, trend.trendstore dst
		WHERE src.id = $1 AND dst.id = $2;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialization(src text, dst text, "timestamp" timestamp with time zone)
	RETURNS materialization_result
AS $$
	SELECT materialization.materialize(src, dst, $3)
	FROM
		trend.trendstore src,
		trend.trendstore dst
	WHERE src::text = $1 and dst::text = $2;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialize(materialization text, "timestamp" timestamp with time zone)
	RETURNS materialization_result
AS $$
	SELECT materialization.materialize(mt.src_trendstore_id, mt.dst_trendstore_id, $2)
	FROM materialization.type mt
	WHERE materialization.to_char(mt) = $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialize(materialization.type, "timestamp" timestamp with time zone)
	RETURNS materialization_result
AS $$
	SELECT materialization.materialize($1.src_trendstore_id, $1.dst_trendstore_id, $2);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION materialize(id integer, "timestamp" timestamp with time zone)
	RETURNS materialization_result
AS $$
	SELECT materialization.materialize(mt.src_trendstore_id, mt.dst_trendstore_id, $2)
	FROM materialization.type mt
	WHERE mt.id = $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION define(src_trendstore_id integer, dst_trendstore_id integer)
	RETURNS materialization.type
AS $$
	INSERT INTO materialization.type (src_trendstore_id, dst_trendstore_id, processing_delay, stability_delay, reprocessing_period)
	SELECT $1, $2, materialization.default_processing_delay(granularity), materialization.default_stability_delay(granularity), interval '3 days'
	FROM trend.trendstore WHERE id = $2
	RETURNING type;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION define(src trend.trendstore, dst trend.trendstore)
	RETURNS materialization.type
AS $$
	SELECT materialization.define($1.id, $2.id);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION define(text, text)
	RETURNS materialization.type
AS $$
	SELECT
		materialization.define(src.id, dst.id)
	FROM
		trend.trendstore src,
		trend.trendstore dst
	WHERE src::text = $1 AND dst::text = $2;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION define(trend.trendstore)
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

COMMENT ON FUNCTION define(trend.trendstore)
IS 'Defines a new materialization with the convention that the datasource of
the source trendstore should start with a ''v'' for views and that the
destination trendstore has the same properties except for a datasource with a
name without the leading ''v''. A new trendstore and datasource are created if
they do not exist.';


CREATE OR REPLACE FUNCTION define(trend.view)
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

COMMENT ON FUNCTION define(trend.view)
IS 'Defines a new materialization with the convention that the datasource of
the source trendstore should start with a ''v'' for views and that the
destination trendstore has the same properties except for a datasource with a
name without the leading ''v''. A new trendstore and datasource are created if
they do not exist.';


CREATE OR REPLACE FUNCTION render_job_json(type_id integer, timestamp with time zone)
	RETURNS character varying
AS $$
	SELECT format('{"type_id": %s, "timestamp": "%s"}', $1, $2);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION create_job(type_id integer, "timestamp" timestamp with time zone)
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

	RETURN new_job_id;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION runnable(type materialization.type, "timestamp" timestamp with time zone, max_modified timestamp with time zone)
	RETURNS boolean
AS $$
	SELECT
		$1.enabled AND
		materialization.source_data_ready($1, $2, $3) AND
		($1.reprocessing_period IS NULL OR now() - $2 < $1.reprocessing_period);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION runnable(materialization.type, materialization.state)
	RETURNS boolean
AS $$
	SELECT materialization.runnable($1, $2.timestamp, $2.max_modified);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION open_job_slots(slot_count integer)
	RETURNS integer
AS $$
	SELECT greatest($1 - COUNT(*), 0)::integer
	FROM system.job
	WHERE type = 'materialize' AND (state = 'running' OR state = 'queued');
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION runnable_materializations(tag varchar)
	RETURNS TABLE (type_id integer, "timestamp" timestamp with time zone)
AS $$
DECLARE
	runnable_materializations_query text;
	conn_str text;
	replicated_server_conn system.setting;
BEGIN
	replicated_server_conn = system.get_setting('replicated_server_conn');

	IF replicated_server_conn IS NULL THEN
		RETURN QUERY SELECT trm.type_id, trm.timestamp
		FROM materialization.tagged_runnable_materializations trm
		WHERE trm.tag = $1;
	ELSE
		runnable_materializations_query = format('SELECT type_id, timestamp
			FROM materialization.tagged_runnable_materializations
			WHERE tag = %L', tag);

		RETURN QUERY SELECT replicated_state.type_id, replicated_state.timestamp
		FROM public.dblink(replicated_server_conn.value, runnable_materializations_query)
			AS replicated_state(type_id integer, "timestamp" timestamp with time zone)
		JOIN materialization.tagged_runnable_materializations rj ON
			replicated_state.type_id = rj.type_id
				AND
			replicated_state.timestamp = rj.timestamp
        WHERE materialization.no_slave_lag();
	END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION runnable_materializations(tag varchar)
IS 'Return table with all combinations (type_id, timestamp) that are ready to
run. This includes the check between the master and slave states.';


CREATE OR REPLACE FUNCTION create_jobs(tag varchar, job_limit integer)
	RETURNS integer
AS $$
	SELECT COUNT(materialization.create_job(type_id, timestamp))::integer
	FROM (
		SELECT type_id, timestamp
		FROM materialization.runnable_materializations($1)
		LIMIT materialization.open_job_slots($2)
	) mzs;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION create_jobs(tag varchar)
	RETURNS integer
AS $$
	SELECT COUNT(materialization.create_job(type_id, timestamp))::integer
	FROM materialization.runnable_materializations($1);
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION create_jobs_limited(tag varchar, job_limit integer)
	RETURNS integer
AS $$
	SELECT materialization.create_jobs($1, $2);
$$ LANGUAGE SQL;

COMMENT ON FUNCTION create_jobs_limited(tag varchar, job_limit integer)
IS 'Deprecated function that just calls the overloaded create_jobs function.';


CREATE OR REPLACE FUNCTION tag(tag_name character varying, type_id integer)
	RETURNS materialization.type_tag_link
AS $$
	INSERT INTO materialization.type_tag_link (type_id, tag_id)
	SELECT $2, tag.id FROM directory.tag WHERE name = $1
	RETURNING *;
$$ LANGUAGE SQL VOLATILE;

COMMENT ON FUNCTION tag(character varying, type_id integer)
IS 'Add tag with name tag_name to materialization type with id type_id.
The tag must already exist.';


CREATE OR REPLACE FUNCTION tag(tag_name character varying, materialization.type)
	RETURNS materialization.type
AS $$
	INSERT INTO materialization.type_tag_link (type_id, tag_id)
	SELECT $2.id, tag.id FROM directory.tag WHERE name = $1
	RETURNING $2;
$$ LANGUAGE SQL VOLATILE;

COMMENT ON FUNCTION tag(character varying, materialization.type)
IS 'Add tag with name tag_name to materialization type. The tag must already exist.';


CREATE OR REPLACE FUNCTION untag(materialization.type)
	RETURNS materialization.type
AS $$
	DELETE FROM materialization.type_tag_link WHERE type_id = $1.id RETURNING $1;
$$ LANGUAGE SQL VOLATILE;

COMMENT ON FUNCTION untag(materialization.type)
IS 'Remove all tags from the materialization';


CREATE OR REPLACE FUNCTION reset(type_id integer)
	RETURNS SETOF materialization.state
AS $$
	UPDATE materialization.state SET processed_states = NULL
	WHERE
		type_id = $1 AND
		source_states = processed_states
	RETURNING *;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION reset_hard(materialization.type)
	RETURNS void
AS $$
	DELETE FROM trend.partition WHERE trendstore_id = $1.dst_trendstore_id;
	DELETE FROM materialization.state WHERE type_id = $1.id;
$$ LANGUAGE SQL VOLATILE;

COMMENT ON FUNCTION reset_hard(materialization.type)
IS 'Remove data (partitions) resulting from this materialization and the
corresponding state records, so materialization for all timestamps can be done
again';


CREATE OR REPLACE FUNCTION reset(type_id integer, timestamp with time zone)
	RETURNS materialization.state 
AS $$
	UPDATE materialization.state SET processed_states = NULL
	WHERE type_id = $1 AND timestamp = $2
	RETURNING *;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION reset(materialization.type, timestamp with time zone)
	RETURNS materialization.state 
AS $$
	SELECT reset($1.id, $2);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION enable(materialization.type)
	RETURNS materialization.type
AS $$
	UPDATE materialization.type SET enabled = true WHERE id = $1.id RETURNING type;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION disable(materialization.type)
	RETURNS materialization.type
AS $$
	UPDATE materialization.type SET enabled = false WHERE id = $1.id RETURNING type;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION fragments(materialization.source_fragment_state[])
	RETURNS materialization.source_fragment[]
AS $$
	SELECT array_agg(fragment) FROM unnest($1);
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION requires_update(materialization.state)
	RETURNS boolean
AS $$
	SELECT (
		$1.source_states <> $1.processed_states AND
		materialization.fragments($1.source_states) @> materialization.fragments($1.processed_states)
	)
	OR $1.processed_states IS NULL;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION default_processing_delay(granularity character varying)
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


CREATE OR REPLACE FUNCTION default_stability_delay(granularity character varying)
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


CREATE OR REPLACE FUNCTION source_data_ready(type materialization.type, "timestamp" timestamp with time zone, max_modified timestamp with time zone)
	RETURNS boolean
AS $$
	SELECT
		$2 < now() - $1.processing_delay AND
		$3 < now() - $1.stability_delay;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION dependencies(trend.trendstore, level integer)
	RETURNS TABLE(trendstore trend.trendstore, level integer)
AS $$
-- Stub to allow recursive definition.
	SELECT $1, $2;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION direct_view_dependencies(trend.trendstore)
	RETURNS SETOF trend.trendstore
AS $$
	SELECT trendstore
	FROM trend.trendstore
	JOIN trend.view_trendstore_link vtl ON vtl.trendstore_id = trendstore.id
	JOIN trend.view ON view.id = vtl.view_id
	WHERE view.trendstore_id = $1.id;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION direct_table_dependencies(trend.trendstore)
	RETURNS SETOF trend.trendstore
AS $$
	SELECT trendstore
	FROM trend.trendstore
	JOIN materialization.type ON type.src_trendstore_id = trendstore.id
	WHERE dst_trendstore_id = $1.id;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION direct_dependencies(trend.trendstore)
	RETURNS SETOF trend.trendstore
AS $$
	SELECT
	CASE WHEN $1.type = 'view' THEN
		materialization.direct_view_dependencies($1)
	WHEN $1.type = 'table' THEN
		materialization.direct_table_dependencies($1)
	END;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION dependencies(trend.trendstore, level integer)
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


CREATE OR REPLACE FUNCTION dependencies(trend.trendstore)
	RETURNS TABLE(trendstore trend.trendstore, level integer)
AS $$
	SELECT materialization.dependencies($1, 1);
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION dependencies(name text)
	RETURNS TABLE(trendstore trend.trendstore, level integer)
AS $$
	SELECT materialization.dependencies(trendstore) FROM trend.trendstore WHERE trend.to_char(trendstore) = $1;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION no_slave_lag()
    RETURNS boolean
    LANGUAGE sql
AS $$SELECT bytes_lag < 10000000
FROM metric.replication_lag
WHERE client_addr = '192.168.42.19';$$;


CREATE OR REPLACE FUNCTION materialization.create_jobs()
    RETURNS integer
    LANGUAGE sql
AS $function$
    SELECT COUNT(materialization.create_job(num.type_id, timestamp))::integer
    FROM materialization.next_up_materializations num
    WHERE NOT job_active AND materialization.no_slave_lag();
$function$;

