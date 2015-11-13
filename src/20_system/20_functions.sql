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
    INSERT INTO system.job(size, job_source_id, type, description) VALUES (size, job_source_id, type, description) RETURNING id INTO new_job_id;

    INSERT INTO system.job_queue(job_id) VALUES (new_job_id);

    return new_job_id;
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

            UPDATE system.job SET state = 'running', started = NOW() WHERE id = result.id;
        END IF;

        RETURN result;
    END LOOP;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION system.finish_job(job_id int)
    RETURNS void
AS $$
DECLARE
BEGIN
    UPDATE system.job SET state = 'finished', finished = NOW() WHERE system.job.id = job_id;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;


CREATE OR REPLACE FUNCTION system.fail_job(job_id int)
    RETURNS void
AS $$
DECLARE
BEGIN
    UPDATE system.job SET state = 'failed', finished = NOW() WHERE system.job.id = job_id;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;


CREATE OR REPLACE FUNCTION system.fail_job(job_id int, message character varying)
    RETURNS void
AS $$
DECLARE
BEGIN
    UPDATE system.job SET state = 'failed', finished = NOW() WHERE system.job.id = job_id;

    INSERT INTO system.job_error_log (job_id, message) VALUES (job_id, message);
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;


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


CREATE OR REPLACE FUNCTION system.remove_jobs(before timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    result integer;
BEGIN
    -- Acquire locks
    PERFORM pg_advisory_xact_lock(0);

    -- Drop constraints on dependent tables
    ALTER TABLE system.job_queue DROP CONSTRAINT job_queue_job_id_fkey;
    ALTER TABLE transform.state DROP CONSTRAINT job_id_fkey;

    -- Select rows for deletion
    CREATE TEMP TABLE to_be_deleted ON COMMIT DROP AS SELECT * FROM system.job WHERE created < before;

    -- Actual deleting of jobs
    DELETE FROM system.job USING to_be_deleted WHERE to_be_deleted.id = job.id;

    GET DIAGNOSTICS result = ROW_COUNT;

    -- Update dependent tables
    DELETE FROM system.job_queue USING to_be_deleted WHERE to_be_deleted.id = job_queue.job_id;

    UPDATE transform.state SET job_id = DEFAULT WHERE job_id IN (SELECT id FROM to_be_deleted);

    -- Restore constraints on dependent tables
    ALTER TABLE transform.state
        ADD CONSTRAINT job_id_fkey FOREIGN KEY (job_id) REFERENCES system.job(id)
        MATCH SIMPLE ON UPDATE NO ACTION ON DELETE SET DEFAULT;

    ALTER TABLE system.job_queue
        ADD CONSTRAINT job_queue_job_id_fkey FOREIGN KEY (job_id) REFERENCES system.job(id)
        ON DELETE CASCADE;

    return result;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;


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
