CREATE TYPE system.version_tuple AS (
    major smallint,
    minor smallint,
    patch smallint
);

CREATE OR REPLACE FUNCTION system.version_gtlt_version(system.version_tuple, system.version_tuple)
    RETURNS boolean
AS $$
SELECT
    $1.major > $2.major AND
    $1.minor > $2.minor AND
    $1.patch > $2.patch;
$$ LANGUAGE sql IMMUTABLE;


CREATE OPERATOR <> (
    LEFTARG = system.version_tuple,
    RIGHTARG = system.version_tuple,
    PROCEDURE = system.version_gtlt_version
);


CREATE OR REPLACE FUNCTION system.set_version(system.version_tuple)
    RETURNS system.version_tuple
AS $$
BEGIN

    EXECUTE format($sql$CREATE OR REPLACE FUNCTION system.version()
    RETURNS system.version_tuple
AS $function$
SELECT %s::system.version_tuple;
$function$ LANGUAGE sql IMMUTABLE;$sql$, $1);

    RETURN $1;

END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION system.set_version(integer, integer, integer)
    RETURNS system.version_tuple
AS $$
    SELECT system.set_version(($1, $2, $3)::system.version_tuple);
$$ LANGUAGE sql VOLATILE;


SELECT system.set_version(4, 7, 0);


CREATE TYPE system.job_type AS (id int, type character varying, description character varying, size bigint, config text);


CREATE OR REPLACE FUNCTION system.create_job(type character varying, description character varying, size bigint, job_source_id int)
    RETURNS integer
AS $$
DECLARE
    new_job_id integer;
BEGIN
    IF EXISTS (
        SELECT 1
        FROM system.job
        WHERE job.description = create_job.description
            AND job.size = create_job.size
            AND job.type = create_job.type
            AND job.job_source_id = create_job.job_source_id
            AND create_job.type = 'harvest')
    THEN
        RAISE WARNING 'ignoring duplicate harvest job';
    ELSE
        INSERT INTO system.job(size, job_source_id, type, description) VALUES (size, job_source_id, type, description) RETURNING id INTO new_job_id;

        INSERT INTO system.job_queue(job_id) VALUES (new_job_id);
    END IF;

    RETURN new_job_id;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;


CREATE OR REPLACE FUNCTION system.get_job()
    RETURNS system.job_type
AS $$
DECLARE
    result system.job_type;
BEGIN
    LOOP
        SELECT job_queue.job_id, job.type, job.description, job.size, js.config INTO result
            FROM system.job_queue
            JOIN system.job ON job_queue.job_id = job.id
            JOIN system.job_source js ON js.id = job.job_source_id
            WHERE pg_try_advisory_xact_lock(job_queue.job_id)
            ORDER BY job_id ASC LIMIT 1;

        IF result IS NOT NULL THEN
            DELETE FROM system.job_queue WHERE job_id = result.id;

            IF NOT found THEN
                -- race: job was just assigned, retry
                CONTINUE;
            END IF;

            UPDATE system.job SET started = NOW() WHERE id = result.id;
        END IF;

        RETURN result;
    END LOOP;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION system.finish_job(job_id integer)
 RETURNS void
AS $$
    INSERT INTO system.job_finished(id, type, description, size, created, started, finished, job_source_id)
    SELECT id, type, description, size, created, started, now(), job_source_id FROM system.job WHERE id = $1;

    DELETE FROM system.job WHERE id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION system.fail_job(job_id integer)
    RETURNS integer
AS $$
    INSERT INTO system.job_failed(id, type, description, size, created, started, finished, job_source_id)
    SELECT id, type, description, size, created, started, now(), job_source_id FROM system.job WHERE id = $1;

    DELETE FROM system.job WHERE id = $1 RETURNING id;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION system.fail_job(job_id integer, message character varying)
    RETURNS integer
AS $$
    INSERT INTO system.job_error_log (job_id, message) VALUES ($1, $2);

    SELECT system.fail_job($1);
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION system.add_job_source(character varying, character varying, character varying)
    RETURNS integer
AS $$
    INSERT INTO system.job_source (id, name, job_type, config)
    VALUES (DEFAULT, $1, $2, $3)
    RETURNING id;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION system.get_job_source(integer)
    RETURNS TABLE(name character varying, job_type character varying, config character varying)
AS $$
    SELECT name, job_type, config FROM system.job_source WHERE id = $1;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION system.remove_failed_jobs(before timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    row_count integer;
BEGIN
    DELETE FROM system.job_failed WHERE created < before;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION system.remove_finished_jobs(before timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    row_count integer;
BEGIN
    DELETE FROM system.job_finished WHERE created < before;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION system.get_setting(name text)
    RETURNS system.setting
AS $$
    SELECT setting FROM system.setting WHERE name = $1;
$$ LANGUAGE SQL STABLE STRICT;


CREATE OR REPLACE FUNCTION system.add_setting(name text, value text)
    RETURNS system.setting
AS $$
    INSERT INTO system.setting (name, value) VALUES ($1, $2) RETURNING setting;
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE OR REPLACE FUNCTION system.update_setting(name text, value text)
    RETURNS system.setting
AS $$
    UPDATE system.setting SET value = $2 WHERE name = $1 RETURNING setting;
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE OR REPLACE FUNCTION system.set_setting(name text, value text)
    RETURNS system.setting
AS $$
    SELECT COALESCE(system.update_setting($1, $2), system.add_setting($1, $2));
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE OR REPLACE FUNCTION system.get_setting_value(name text)
    RETURNS text
AS $$
    SELECT value FROM system.setting WHERE name = $1;
$$ LANGUAGE SQL STABLE STRICT;


CREATE OR REPLACE FUNCTION system.get_setting_value(name text, "default" text)
    RETURNS text
AS $$
    SELECT COALESCE(system.get_setting_value($1), $2);
$$ LANGUAGE SQL STABLE STRICT;
