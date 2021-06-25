

CREATE OR REPLACE FUNCTION "trend_directory"."create_staging_table_sql"(trend_directory.trend_store_part)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE UNLOGGED TABLE %I.%I (entity_id integer, "timestamp" timestamp with time zone, created timestamp with time zone, job_id bigint%s);',
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name($1),
        (
            SELECT string_agg(format(', %I %s', t.name, t.data_type), ' ')
            FROM trend_directory.table_trend t
            WHERE t.trend_store_part_id = $1.id
        )
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


CREATE OR REPLACE FUNCTION "trend_directory"."transfer"("materialization" trend_directory.view_materialization, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    columns_part text;
    row_count integer;
    job_id bigint;
BEGIN
    SELECT logging.start_job(format('{"view_materialization": "%s", "timestamp": "%s"}', m::text, $2::text)::jsonb) INTO job_id
    FROM trend_directory.materialization m WHERE id = $1.materialization_id;

    SELECT trend_directory.columns_part($1) INTO columns_part;

    EXECUTE format(
        'INSERT INTO trend.%I (entity_id, timestamp, created, job_id, %s) SELECT entity_id, timestamp, now(), %s, %s FROM %s WHERE timestamp = $1',
        (trend_directory.dst_trend_store_part($1)).name,
        columns_part,
        job_id,
        columns_part,
        $1.src_view::name
    ) USING timestamp;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    PERFORM logging.end_job(job_id);

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."transfer"("materialization" trend_directory.view_materialization, "timestamp" timestamp with time zone) IS 'Transfer all records of the specified timestamp from the view to the target trend store of the materialization.';


CREATE OR REPLACE FUNCTION "trend_directory"."transfer"("materialization" trend_directory.function_materialization, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    columns_part text;
    row_count integer;
    job_id bigint;
BEGIN
    SELECT logging.start_job(format('{"function_materialization": "%s", "timestamp": "%s"}', m::text, $2::text)::jsonb) INTO job_id
    FROM trend_directory.materialization m WHERE id = $1.materialization_id;

    SELECT trend_directory.columns_part($1) INTO columns_part;

    EXECUTE format(
        'INSERT INTO trend.%I (entity_id, timestamp, created, job_id, %s) SELECT entity_id, timestamp, now(), %s, %s FROM %s($1)',
        (trend_directory.dst_trend_store_part($1)).name,
        columns_part,
        job_id,
        columns_part,
        $1.src_function::regproc
    ) USING timestamp;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    PERFORM logging.end_job(job_id);

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;
