CREATE TYPE system.version_tuple AS (
    major smallint,
    minor smallint,
    patch smallint
);

CREATE FUNCTION system.version_gtlt_version(system.version_tuple, system.version_tuple)
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


CREATE FUNCTION system.set_version(system.version_tuple)
    RETURNS system.version_tuple
AS $$
BEGIN

    EXECUTE format($sql$CREATE FUNCTION system.version()
    RETURNS system.version_tuple
AS $function$
SELECT %s::system.version_tuple;
$function$ LANGUAGE sql IMMUTABLE;$sql$, $1);

    RETURN $1;

END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION system.set_version(integer, integer, integer)
    RETURNS system.version_tuple
AS $$
    SELECT system.set_version(($1, $2, $3)::system.version_tuple);
$$ LANGUAGE sql VOLATILE;


SELECT system.set_version(5, 0, 0);


CREATE TYPE system.job_type AS (id int, type character varying, description character varying, size bigint, config text);


CREATE FUNCTION system.enqueue_job(system.job)
    RETURNS system.job
AS $$
    INSERT INTO system.job_queue(job_id) VALUES ($1.id);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION system.define_job(type character varying, description json, size bigint, job_source_id int)
    RETURNS system.job
AS $$
    INSERT INTO system.job(
        size, job_source_id, type, description
    ) VALUES (
        size, job_source_id, type, description
    ) RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION system.create_job(type character varying, description json, size bigint, job_source_id int)
    RETURNS system.job
AS $$
    SELECT system.enqueue_job(system.define_job($1, $2, $3, $4));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION system.get_job()
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


CREATE FUNCTION system.finish_job(job_id int)
    RETURNS void
AS $$
    UPDATE system.job SET state = 'finished', finished = NOW() WHERE system.job.id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION system.fail_job(job_id int)
    RETURNS void
AS $$
    UPDATE system.job SET state = 'failed', finished = NOW() WHERE system.job.id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION system.fail_job(job_id int, message text)
    RETURNS void
AS $$
    UPDATE system.job SET state = 'failed', finished = NOW() WHERE system.job.id = $1;

    INSERT INTO system.job_error_log (job_id, message) VALUES ($1, $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION system.create_job_source(text, text, json)
    RETURNS system.job_source
AS $$
    INSERT INTO system.job_source (id, name, job_type, config)
    VALUES (DEFAULT, $1, $2, $3)
    RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION system.get_job_source(integer)
    RETURNS system.job_source
AS $$
    SELECT * FROM system.job_source WHERE id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION system.remove_jobs(before timestamp with time zone, max bigint DEFAULT 100000)
    RETURNS bigint
AS $$
    WITH deleted AS (
        DELETE FROM system.job WHERE id IN (SELECT id FROM system.job WHERE created < $1 ORDER BY created ASC LIMIT $2) RETURNING *
    )
    SELECT count(*) FROM deleted;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION system.get_setting(name text)
    RETURNS system.setting
AS $$
    SELECT setting FROM system.setting WHERE name = $1;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION system.add_setting(name text, value text)
    RETURNS system.setting
AS $$
    INSERT INTO system.setting (name, value) VALUES ($1, $2) RETURNING setting;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION system.update_setting(name text, value text)
    RETURNS system.setting
AS $$
    UPDATE system.setting SET value = $2 WHERE name = $1 RETURNING setting;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION system.set_setting(name text, value text)
    RETURNS system.setting
AS $$
    SELECT COALESCE(system.update_setting($1, $2), system.add_setting($1, $2));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION system.get_setting_value(name text)
    RETURNS text
AS $$
    SELECT value FROM system.setting WHERE name = $1;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION system.get_setting_value(name text, "default" text)
    RETURNS text
AS $$
    SELECT COALESCE(system.get_setting_value($1), $2);
$$ LANGUAGE sql STABLE STRICT;
