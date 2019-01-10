

DO
$$
BEGIN
  IF NOT EXISTS(SELECT * FROM pg_roles WHERE rolname = 'minerva') THEN
    CREATE ROLE minerva
      NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
  END IF;
END
$$;


DO
$$
BEGIN
  IF NOT EXISTS(SELECT * FROM pg_roles WHERE rolname = 'minerva_writer') THEN
    CREATE ROLE minerva_writer
      NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
  END IF;
END
$$;

GRANT minerva TO minerva_writer;


DO
$$
BEGIN
  IF NOT EXISTS(SELECT * FROM pg_roles WHERE rolname = 'minerva_admin') THEN
    CREATE ROLE minerva_admin
      LOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
  END IF;
END
$$;

GRANT minerva TO minerva_admin;

GRANT minerva_writer TO minerva_admin;


CREATE SCHEMA IF NOT EXISTS "public";


CREATE SCHEMA IF NOT EXISTS "dimension";
GRANT USAGE,CREATE ON SCHEMA "dimension" TO "minerva_writer";
GRANT USAGE ON SCHEMA "dimension" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "system";


CREATE SCHEMA IF NOT EXISTS "directory";
COMMENT ON SCHEMA "directory" IS 'Stores contextual information for the data. This includes the entities, entity_types, data_sources, etc. It is the entrypoint when looking for data.';
GRANT USAGE ON SCHEMA "directory" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "alias";


CREATE SCHEMA IF NOT EXISTS "alias_directory";


CREATE SCHEMA IF NOT EXISTS "relation";
COMMENT ON SCHEMA "relation" IS 'Stores the actual relations between entities in dynamically created tables.';
GRANT USAGE,CREATE ON SCHEMA "relation" TO "minerva_writer";
GRANT USAGE ON SCHEMA "relation" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "relation_def";
COMMENT ON SCHEMA "relation_def" IS 'Stores definitions of relations in the form of views. These views are used to
populate the corresponding tables in the relation schema';
GRANT USAGE,CREATE ON SCHEMA "relation_def" TO "minerva_writer";
GRANT USAGE ON SCHEMA "relation_def" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "relation_directory";


CREATE SCHEMA IF NOT EXISTS "trend";
COMMENT ON SCHEMA "trend" IS 'Stores information with fixed interval and format, like periodic measurements.';
GRANT USAGE,CREATE ON SCHEMA "trend" TO "minerva_writer";
GRANT USAGE ON SCHEMA "trend" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "trend_directory";


CREATE SCHEMA IF NOT EXISTS "trend_partition";
COMMENT ON SCHEMA "trend_partition" IS 'Stores information with fixed interval and format, like periodic measurements.';
GRANT USAGE,CREATE ON SCHEMA "trend_partition" TO "minerva_writer";
GRANT USAGE ON SCHEMA "trend_partition" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "attribute";
GRANT USAGE,CREATE ON SCHEMA "attribute" TO "minerva_writer";
GRANT USAGE ON SCHEMA "attribute" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "attribute_base";
GRANT USAGE,CREATE ON SCHEMA "attribute_base" TO "minerva_writer";
GRANT USAGE ON SCHEMA "attribute_base" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "attribute_directory";
GRANT USAGE,CREATE ON SCHEMA "attribute_directory" TO "minerva_writer";
GRANT USAGE ON SCHEMA "attribute_directory" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "attribute_history";
GRANT USAGE,CREATE ON SCHEMA "attribute_history" TO "minerva_writer";
GRANT USAGE ON SCHEMA "attribute_history" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "attribute_staging";
GRANT USAGE,CREATE ON SCHEMA "attribute_staging" TO "minerva_writer";
GRANT USAGE ON SCHEMA "attribute_staging" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "notification";
COMMENT ON SCHEMA "notification" IS 'Stores information of events that can occur at irregular intervals, but
still have a fixed, known format.

This schema is dynamically populated.';
GRANT USAGE,CREATE ON SCHEMA "notification" TO "minerva_writer";
GRANT USAGE ON SCHEMA "notification" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "notification_directory";
COMMENT ON SCHEMA "notification_directory" IS 'Stores meta-data about notification data in the notification schema.';
GRANT USAGE,CREATE ON SCHEMA "notification_directory" TO "minerva_writer";
GRANT USAGE ON SCHEMA "notification_directory" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "metric";
GRANT USAGE ON SCHEMA "metric" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "virtual_entity";
GRANT USAGE ON SCHEMA "virtual_entity" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "olap";
GRANT USAGE,CREATE ON SCHEMA "olap" TO "minerva_writer";
GRANT USAGE ON SCHEMA "olap" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "entity_tag";
GRANT USAGE ON SCHEMA "entity_tag" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "trigger";
GRANT USAGE,CREATE ON SCHEMA "trigger" TO "minerva_writer";
GRANT USAGE ON SCHEMA "trigger" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "trigger_rule";
GRANT USAGE,CREATE ON SCHEMA "trigger_rule" TO "minerva_writer";
GRANT USAGE ON SCHEMA "trigger_rule" TO "minerva";


CREATE FUNCTION "public"."integer_to_array"("value" integer)
    RETURNS integer[]
AS $$
BEGIN
    RETURN ARRAY[value];
END;
$$ LANGUAGE plpgsql STABLE STRICT;


CREATE FUNCTION "public"."smallint_to_array"("value" smallint)
    RETURNS smallint[]
AS $$
BEGIN
    RETURN ARRAY[value];
END;
$$ LANGUAGE plpgsql STABLE STRICT;


CREATE FUNCTION "public"."smallint_to_timestamp_without_time_zone"(smallint)
    RETURNS timestamp without time zone
AS $$
BEGIN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE STRICT;


CREATE FUNCTION "public"."smallint_to_timestamp_with_time_zone"(smallint)
    RETURNS timestamp with time zone
AS $$
BEGIN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE STRICT;


CREATE FUNCTION "public"."column_names"("namespace" name, "table" name)
    RETURNS SETOF name
AS $$
SELECT a.attname
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
    JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
    WHERE
        n.nspname = $1 AND
        c.relname = $2 AND
        a.attisdropped = false AND
        a.attnum > 0;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "public"."fst"(anyelement, anyelement)
    RETURNS anyelement
AS $$
SELECT $1;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "public"."snd"(anyelement, anyelement)
    RETURNS anyelement
AS $$
SELECT $2;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "public"."safe_division"("numerator" anyelement, "denominator" anyelement)
    RETURNS anyelement
AS $$
SELECT CASE
    WHEN $2 = 0 THEN
        NULL
    ELSE
        $1 / $2
    END;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "public"."add_array"(anyarray, anyarray)
    RETURNS anyarray
AS $$
SELECT array_agg((arr1 + arr2)) FROM
(
    SELECT
        unnest($1[1:least(array_length($1,1), array_length($2,1))]) AS arr1,
        unnest($2[1:least(array_length($1,1), array_length($2,1))]) AS arr2
) AS foo;
$$ LANGUAGE sql STABLE STRICT;


CREATE AGGREGATE sum_array (anyarray) (
    sfunc = add_array,
    stype = anyarray
);



CREATE FUNCTION "public"."divide_array"(anyarray, anyelement)
    RETURNS anyarray
AS $$
SELECT array_agg(arr / $2) FROM
(
    SELECT unnest($1) AS arr
) AS foo;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "public"."divide_array"(anyarray, anyarray)
    RETURNS anyarray
AS $$
SELECT array_agg(public.safe_division(arr1, arr2)) FROM
(
    SELECT
    unnest($1[1:least(array_length($1,1), array_length($2,1))]) AS arr1,
    unnest($2[1:least(array_length($1,1), array_length($2,1))]) AS arr2
) AS foo;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "public"."array_sum"(anyarray)
    RETURNS anyelement
AS $$
SELECT sum(t) FROM unnest($1) t;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "public"."to_pdf"(text)
    RETURNS integer[]
AS $$
SELECT array_agg(nullif(x, '')::int)
    FROM unnest(string_to_array($1, ',')) AS x;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "public"."action"("sql" text)
    RETURNS void
AS $$
BEGIN
    EXECUTE sql;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "public"."action"(anyelement, "sql" text)
    RETURNS anyelement
AS $$
BEGIN
    EXECUTE sql;

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "public"."action"(anyelement, "sql" text[])
    RETURNS anyelement
AS $$
DECLARE
    statement text;
BEGIN
    FOREACH statement IN ARRAY sql LOOP
        EXECUTE statement;
    END LOOP;

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "public"."table_exists"("schema_name" name, "table_name" name)
    RETURNS bool
AS $$
SELECT exists(
        SELECT 1
        FROM pg_class
        JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
        WHERE relname = $2 AND relkind = 'r' AND pg_namespace.nspname = $1
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "public"."raise_exception"("message" anyelement)
    RETURNS void
AS $$
BEGIN
    RAISE EXCEPTION '%', message;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "public"."raise_info"("message" anyelement)
    RETURNS void
AS $$
BEGIN
    RAISE INFO '%', message;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE AGGREGATE first (anyelement) (
    sfunc = fst,
    stype = anyelement
);



CREATE AGGREGATE last (anyelement) (
    sfunc = snd,
    stype = anyelement
);



CREATE CAST (integer AS integer[])
  WITH FUNCTION "public"."integer_to_array"(integer);


CREATE CAST (smallint AS smallint[])
  WITH FUNCTION "public"."smallint_to_array"(smallint);


CREATE CAST (smallint AS timestamp without time zone)
  WITH FUNCTION "public"."smallint_to_timestamp_without_time_zone"(smallint);


CREATE CAST (smallint AS timestamp with time zone)
  WITH FUNCTION "public"."smallint_to_timestamp_with_time_zone"(smallint);


CREATE TABLE "dimension"."month"
(
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone,
  "end" timestamp with time zone,
  PRIMARY KEY (timestamp)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."month" TO minerva_writer;

GRANT SELECT ON TABLE "dimension"."month" TO minerva;



CREATE TABLE "dimension"."week"
(
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone,
  "end" timestamp with time zone,
  "year" smallint,
  "week_iso_8601" smallint,
  PRIMARY KEY (timestamp)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."week" TO minerva_writer;

GRANT SELECT ON TABLE "dimension"."week" TO minerva;



CREATE TABLE "dimension"."day"
(
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone,
  "end" timestamp with time zone,
  PRIMARY KEY (timestamp)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."day" TO minerva_writer;

GRANT SELECT ON TABLE "dimension"."day" TO minerva;



CREATE TABLE "dimension"."hour"
(
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone,
  "end" timestamp with time zone,
  PRIMARY KEY (timestamp)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."hour" TO minerva_writer;

GRANT SELECT ON TABLE "dimension"."hour" TO minerva;



CREATE TABLE "dimension"."quarter"
(
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone,
  "end" timestamp with time zone,
  PRIMARY KEY (timestamp)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."quarter" TO minerva_writer;

GRANT SELECT ON TABLE "dimension"."quarter" TO minerva;



CREATE TABLE "dimension"."5m"
(
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone,
  "end" timestamp with time zone,
  PRIMARY KEY (timestamp)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."5m" TO minerva_writer;

GRANT SELECT ON TABLE "dimension"."5m" TO minerva;



CREATE TABLE "dimension"."four_consec_qtr"
(
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone,
  "end" timestamp with time zone,
  PRIMARY KEY (timestamp)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."four_consec_qtr" TO minerva_writer;

GRANT SELECT ON TABLE "dimension"."four_consec_qtr" TO minerva;



CREATE TABLE "dimension"."month_15m"
(
  "timestamp" timestamp with time zone,
  "timestamp_15m" timestamp with time zone NOT NULL,
  PRIMARY KEY (timestamp_15m)
);

CREATE INDEX "month_15m_timestamp_idx" ON "dimension"."month_15m" USING btree ("timestamp");

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."month_15m" TO minerva_writer;

GRANT SELECT ON TABLE "dimension"."month_15m" TO minerva;



CREATE TABLE "dimension"."week_15m"
(
  "timestamp" timestamp with time zone,
  "timestamp_15m" timestamp with time zone NOT NULL,
  PRIMARY KEY (timestamp_15m)
);

CREATE INDEX "week_15m_timestamp_idx" ON "dimension"."week_15m" USING btree ("timestamp");

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."week_15m" TO minerva_writer;

GRANT SELECT ON TABLE "dimension"."week_15m" TO minerva;



CREATE TABLE "dimension"."day_15m"
(
  "timestamp" timestamp with time zone,
  "timestamp_15m" timestamp with time zone NOT NULL,
  PRIMARY KEY (timestamp_15m)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."day_15m" TO minerva_writer;

GRANT SELECT ON TABLE "dimension"."day_15m" TO minerva;



CREATE FUNCTION "dimension"."update_month"()
    RETURNS void
AS $$
TRUNCATE dimension.month;
    INSERT INTO dimension.month SELECT
        timestamp,
        timestamp - '1 month'::interval,
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('month', now() - '1 year'::interval),
            date_trunc('month', now() + '1 year'::interval),
            '1 month'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "dimension"."update_week"()
    RETURNS void
AS $$
TRUNCATE dimension.week;
    INSERT INTO dimension.week SELECT
        timestamp,
        timestamp - '1 week'::interval,
        timestamp,
        date_part('isoyear'::text, timestamp - '7 days'::interval),
        date_part('week'::text, timestamp - '7 days'::interval)
    FROM (
        SELECT generate_series(
            date_trunc('week', now() - '1 year'::interval),
            date_trunc('week', now() + '1 year'::interval),
            '1 week'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "dimension"."update_day"()
    RETURNS void
AS $$
TRUNCATE dimension.day;
    INSERT INTO dimension.day SELECT
        timestamp,
        timestamp - '1 day'::interval,
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('day', now()) - '1 year'::interval,
            date_trunc('day', now()) + '1 year'::interval,
            '1 day'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "dimension"."update_hour"()
    RETURNS void
AS $$
TRUNCATE dimension.hour;
    INSERT INTO dimension.hour SELECT
        timestamp,
        timestamp - '1 hour'::interval,
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('hour', now()) - '1 year'::interval,
            date_trunc('hour', now()) + '1 year'::interval,
            '1 hour'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "dimension"."update_quarter"()
    RETURNS void
AS $$
TRUNCATE dimension.quarter;
    INSERT INTO dimension.quarter SELECT
        timestamp,
        timestamp - '15 minute'::interval,
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('hour', now()) - '1 year'::interval,
            date_trunc('hour', now()) + '1 year'::interval,
            '15 minute'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "dimension"."update_5m"()
    RETURNS void
AS $$
TRUNCATE dimension."5m";
    INSERT INTO dimension."5m" SELECT
        timestamp,
        timestamp - '5 minute'::interval,
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('hour', now()) - '1 year'::interval,
            date_trunc('hour', now()) + '1 year'::interval,
            '5 minute'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "dimension"."update_four_consec_qtr"()
    RETURNS void
AS $$
TRUNCATE dimension."four_consec_qtr";
    INSERT INTO dimension."four_consec_qtr" SELECT
        timestamp,
        timestamp - '1 hour'::interval,
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('hour', now()) - '1 year'::interval,
            date_trunc('hour', now()) + '1 year'::interval,
            '15 minute'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "dimension"."update_month_15m"()
    RETURNS void
AS $$
TRUNCATE dimension.month_15m;
    INSERT INTO dimension.month_15m SELECT
        date_trunc('month', timestamp_15m) as timestamp,
        timestamp_15m
    FROM 
        generate_series(
            date_trunc('month', now() - '1 year'::interval),
            date_trunc('month', now() + '1 year'::interval),
            '15 minutes'::interval
        ) AS timestamps(timestamp_15m);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "dimension"."update_week_15m"()
    RETURNS void
AS $$
TRUNCATE dimension.week_15m;
    INSERT INTO dimension.week_15m SELECT
        date_trunc('week', timestamp_15m) as timestamp,
        timestamp_15m
    FROM 
        generate_series(
            date_trunc('week', now() - '1 year'::interval),
            date_trunc('week', now() + '1 year'::interval),
            '15 minutes'::interval
        ) AS timestamps(timestamp_15m);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "dimension"."update_day_15m"()
    RETURNS void
AS $$
TRUNCATE dimension.day_15m;
    INSERT INTO dimension.day_15m SELECT
        date_trunc('day', timestamp),
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('hour', now()) - '1 year'::interval,
            date_trunc('hour', now()) + '1 year'::interval,
            '15 minute'::interval
        ) AS timestamp
    ) timestamps;
$$ LANGUAGE sql VOLATILE;


SELECT dimension.update_month();


SELECT dimension.update_week();


SELECT dimension.update_day();


SELECT dimension.update_hour();


SELECT dimension.update_quarter();


SELECT dimension.update_four_consec_qtr();


SELECT dimension.update_month_15m();


SELECT dimension.update_week_15m();


SELECT dimension.update_day_15m();


CREATE TYPE "system"."job_state_enum" AS ENUM (
  'queued',
  'running',
  'finished',
  'failed'
);



CREATE SEQUENCE system.job_source_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "system"."job_source"
(
  "name" varchar NOT NULL,
  "job_type" varchar NOT NULL,
  "config" json,
  "id" integer NOT NULL DEFAULT nextval('system.job_source_id_seq'::regclass),
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "ix_system_job_source_name" ON "system"."job_source" USING btree (name);

GRANT INSERT,UPDATE,DELETE ON TABLE "system"."job_source" TO minerva_writer;

GRANT SELECT ON TABLE "system"."job_source" TO minerva;



CREATE SEQUENCE system.job_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "system"."job"
(
  "type" varchar NOT NULL,
  "description" json NOT NULL,
  "size" bigint NOT NULL,
  "started" timestamp with time zone,
  "finished" timestamp with time zone,
  "job_source_id" integer NOT NULL,
  "created" timestamp with time zone NOT NULL DEFAULT now(),
  "state" system.job_state_enum NOT NULL DEFAULT 'queued'::system.job_state_enum,
  "id" integer NOT NULL DEFAULT nextval('system.job_id_seq'::regclass),
  PRIMARY KEY (id)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "system"."job" TO minerva_writer;

GRANT SELECT ON TABLE "system"."job" TO minerva;



CREATE TABLE "system"."job_error_log"
(
  "job_id" integer NOT NULL,
  "message" varchar,
  PRIMARY KEY (job_id)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "system"."job_error_log" TO minerva_writer;

GRANT SELECT ON TABLE "system"."job_error_log" TO minerva;



CREATE TABLE "system"."job_queue"
(
  "job_id" integer NOT NULL,
  PRIMARY KEY (job_id)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "system"."job_queue" TO minerva_writer;

GRANT SELECT ON TABLE "system"."job_queue" TO minerva;



CREATE SEQUENCE system.setting_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "system"."setting"
(
  "name" text NOT NULL,
  "value" text,
  "id" integer NOT NULL DEFAULT nextval('system.setting_id_seq'::regclass),
  PRIMARY KEY (id)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "system"."setting" TO minerva_writer;

GRANT SELECT ON TABLE "system"."setting" TO minerva;



CREATE TYPE "system"."version_tuple" AS (
  "major" smallint,
  "minor" smallint,
  "patch" smallint
);



CREATE FUNCTION "system"."version_gtlt_version"(system.version_tuple, system.version_tuple)
    RETURNS bool
AS $$
SELECT
    $1.major > $2.major AND
    $1.minor > $2.minor AND
    $1.patch > $2.patch;
$$ LANGUAGE sql IMMUTABLE;


CREATE OPERATOR <> (
    PROCEDURE = system.version_gtlt_version,
    LEFTARG = system.version_tuple,
    RIGHTARG = system.version_tuple
);


CREATE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,0,0)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "system"."set_version"(system.version_tuple)
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


CREATE FUNCTION "system"."set_version"(integer, integer, integer)
    RETURNS system.version_tuple
AS $$
SELECT system.set_version(($1, $2, $3)::system.version_tuple);
$$ LANGUAGE sql VOLATILE;


CREATE TYPE "system"."job_type" AS (
  "id" integer,
  "type" varchar,
  "description" varchar,
  "size" bigint,
  "config" text
);



CREATE FUNCTION "system"."enqueue_job"(system.job)
    RETURNS system.job
AS $$
INSERT INTO system.job_queue(job_id) VALUES ($1.id);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "system"."define_job"("type" varchar, "description" json, "size" bigint, "job_source_id" integer)
    RETURNS system.job
AS $$
INSERT INTO system.job(
        size, job_source_id, type, description
    ) VALUES (
        size, job_source_id, type, description
    ) RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "system"."create_job"("type" varchar, "description" json, "size" bigint, "job_source_id" integer)
    RETURNS system.job
AS $$
SELECT system.enqueue_job(system.define_job($1, $2, $3, $4));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "system"."get_job"()
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


CREATE FUNCTION "system"."finish_job"("job_id" integer)
    RETURNS void
AS $$
UPDATE system.job SET state = 'finished', finished = NOW() WHERE system.job.id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "system"."fail_job"("job_id" integer)
    RETURNS void
AS $$
UPDATE system.job SET state = 'failed', finished = NOW() WHERE system.job.id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "system"."fail_job"("job_id" integer, "message" text)
    RETURNS void
AS $$
UPDATE system.job SET state = 'failed', finished = NOW() WHERE system.job.id = $1;

    INSERT INTO system.job_error_log (job_id, message) VALUES ($1, $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "system"."create_job_source"(text, text, json)
    RETURNS system.job_source
AS $$
INSERT INTO system.job_source (id, name, job_type, config)
    VALUES (DEFAULT, $1, $2, $3)
    RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "system"."get_job_source"(integer)
    RETURNS system.job_source
AS $$
SELECT * FROM system.job_source WHERE id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "system"."remove_jobs"("before" timestamp with time zone, "max" bigint DEFAULT 100000)
    RETURNS bigint
AS $$
WITH deleted AS (
        DELETE FROM system.job WHERE id IN (SELECT id FROM system.job WHERE created < $1 ORDER BY created ASC LIMIT $2) RETURNING *
    )
    SELECT count(*) FROM deleted;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "system"."get_setting"("name" text)
    RETURNS system.setting
AS $$
SELECT setting FROM system.setting WHERE name = $1;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "system"."add_setting"("name" text, "value" text)
    RETURNS system.setting
AS $$
INSERT INTO system.setting (name, value) VALUES ($1, $2) RETURNING setting;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "system"."update_setting"("name" text, "value" text)
    RETURNS system.setting
AS $$
UPDATE system.setting SET value = $2 WHERE name = $1 RETURNING setting;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "system"."set_setting"("name" text, "value" text)
    RETURNS system.setting
AS $$
SELECT COALESCE(system.update_setting($1, $2), system.add_setting($1, $2));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "system"."get_setting_value"("name" text)
    RETURNS text
AS $$
SELECT value FROM system.setting WHERE name = $1;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "system"."get_setting_value"("name" text, "default" text)
    RETURNS text
AS $$
SELECT COALESCE(system.get_setting_value($1), $2);
$$ LANGUAGE sql STABLE STRICT;


CREATE SEQUENCE directory.data_source_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "directory"."data_source"
(
  "name" varchar NOT NULL,
  "description" varchar NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('directory.data_source_id_seq'::regclass),
  PRIMARY KEY (id)
);

COMMENT ON TABLE "directory"."data_source" IS 'Describes data_sources. A data_source is used to indicate where data came from. Datasources are also used to prevent collisions between sets of data from different sources, where names can be the same, but the meaning of the data differs.';

CREATE UNIQUE INDEX "ix_directory_data_source_name" ON "directory"."data_source" USING btree (name);

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."data_source" TO minerva_writer;

GRANT SELECT ON TABLE "directory"."data_source" TO minerva;



CREATE SEQUENCE directory.entity_type_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "directory"."entity_type"
(
  "name" varchar NOT NULL,
  "description" varchar NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('directory.entity_type_id_seq'::regclass),
  PRIMARY KEY (id)
);

COMMENT ON TABLE "directory"."entity_type" IS 'Stores the entity types that exist in the entity table. Entity types are also used to give context to data that is stored for entities.';

CREATE UNIQUE INDEX "ix_directory_entity_type_name" ON "directory"."entity_type" USING btree (lower((name)::text));

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."entity_type" TO minerva_writer;

GRANT SELECT ON TABLE "directory"."entity_type" TO minerva;



CREATE SEQUENCE directory.entity_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "directory"."entity"
(
  "created" timestamp with time zone NOT NULL,
  "name" varchar NOT NULL,
  "entity_type_id" integer NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('directory.entity_id_seq'::regclass),
  PRIMARY KEY (id)
);

COMMENT ON TABLE "directory"."entity" IS 'Describes entities. An entity is the base object for which the database can hold further information such as attributes, trends and notifications. All data must have a reference to an entity.';

CREATE INDEX "ix_directory_entity_name" ON "directory"."entity" USING btree (name);

CREATE INDEX "ix_directory_entity_entity_type_id" ON "directory"."entity" USING btree (entity_type_id);

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."entity" TO minerva_writer;

GRANT SELECT ON TABLE "directory"."entity" TO minerva;



CREATE SEQUENCE directory.tag_group_id_seq
  START WITH 3
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "directory"."tag_group"
(
  "name" varchar NOT NULL,
  "complementary" bool NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('directory.tag_group_id_seq'::regclass),
  PRIMARY KEY (id)
);

COMMENT ON TABLE "directory"."tag_group" IS 'Stores groups that can be related to by tags.';

CREATE UNIQUE INDEX "ix_directory_tag_group_name" ON "directory"."tag_group" USING btree (lower((name)::text));

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."tag_group" TO minerva_writer;

GRANT SELECT ON TABLE "directory"."tag_group" TO minerva;



CREATE SEQUENCE directory.tag_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "directory"."tag"
(
  "name" varchar NOT NULL,
  "tag_group_id" integer NOT NULL,
  "description" varchar,
  "id" integer NOT NULL DEFAULT nextval('directory.tag_id_seq'::regclass),
  PRIMARY KEY (id)
);

COMMENT ON TABLE "directory"."tag" IS 'Stores all tags. A tag is a simple label that can be attached to a number of object types in the database, such as entities and trends.';

CREATE UNIQUE INDEX "ix_directory_tag_name" ON "directory"."tag" USING btree (lower((name)::text));

CREATE INDEX "tag_lower_id_idx" ON "directory"."tag" USING btree (lower((name)::text), id);

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."tag" TO minerva_writer;

GRANT SELECT ON TABLE "directory"."tag" TO minerva;



CREATE TABLE "directory"."entity_tag_link"
(
  "tag_id" integer NOT NULL,
  "entity_id" integer NOT NULL,
  PRIMARY KEY (tag_id, entity_id)
);

CREATE INDEX "ix_directory_entity_tag_link_entity_id" ON "directory"."entity_tag_link" USING btree (entity_id);

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."entity_tag_link" TO minerva_writer;

GRANT SELECT ON TABLE "directory"."entity_tag_link" TO minerva;



CREATE TABLE "directory"."entity_tag_link_denorm"
(
  "entity_id" integer NOT NULL,
  "tags" text[] NOT NULL,
  "name" text NOT NULL,
  PRIMARY KEY (entity_id)
);

CREATE INDEX "entity_tag_link_denorm_tags_idx" ON "directory"."entity_tag_link_denorm" USING gin (tags);

CREATE INDEX "entity_tag_link_denorm_name_idx" ON "directory"."entity_tag_link_denorm" USING btree (name);

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."entity_tag_link_denorm" TO minerva_writer;

GRANT SELECT ON TABLE "directory"."entity_tag_link_denorm" TO minerva;



CREATE FUNCTION "directory"."get_entity_by_id"(integer)
    RETURNS directory.entity
AS $$
SELECT * FROM directory.entity WHERE id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "directory"."get_entity_type"(text)
    RETURNS directory.entity_type
AS $$
SELECT entity_type FROM directory.entity_type WHERE lower(name) = lower($1);
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "directory"."get_data_source"(text)
    RETURNS directory.data_source
AS $$
SELECT * FROM directory.data_source WHERE name = $1;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "directory"."create_data_source"(text)
    RETURNS directory.data_source
AS $$
INSERT INTO directory.data_source (name, description)
    VALUES ($1, 'default')
    RETURNING data_source;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."delete_data_source"(text)
    RETURNS directory.data_source
AS $$
DELETE FROM directory.data_source WHERE name = $1 RETURNING *;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."create_entity_type"(text)
    RETURNS directory.entity_type
AS $$
INSERT INTO directory.entity_type(name, description) VALUES ($1, '') RETURNING entity_type;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."create_or_replace_entity_type"(text)
    RETURNS directory.entity_type
AS $$
INSERT INTO directory.entity_type(name, description) VALUES ($1, '')
    ON CONFLICT DO NOTHING
    RETURNING entity_type;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."name_to_entity_type"(text)
    RETURNS directory.entity_type
AS $$
SELECT COALESCE(directory.get_entity_type($1), directory.create_or_replace_entity_type($1));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."entity_type_id"(directory.entity_type)
    RETURNS integer
AS $$
SELECT $1.id;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."entity_id"(directory.entity)
    RETURNS integer
AS $$
SELECT $1.id;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."name_to_data_source"(text)
    RETURNS directory.data_source
AS $$
SELECT COALESCE(directory.get_data_source($1), directory.create_data_source($1));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."tag_entity"("entity_id" integer, "tag" text)
    RETURNS integer
AS $$
INSERT INTO directory.entity_tag_link(tag_id, entity_id)
    SELECT id, $1
    FROM directory.tag
    LEFT JOIN directory.entity_tag_link ON entity_tag_link.tag_id = tag.id AND entity_tag_link.entity_id = $1
    WHERE name = $2 AND entity_tag_link.entity_id IS NULL;

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "directory"."update_denormalized_entity_tags"("entity_id" integer)
    RETURNS directory.entity_tag_link_denorm
AS $$
DELETE FROM directory.entity_tag_link_denorm WHERE entity_id = $1;
INSERT INTO directory.entity_tag_link_denorm
SELECT
    entity.id,
    array_agg(lower(tag.name)),
    lower(entity.name)
FROM directory.entity
JOIN directory.entity_tag_link etl ON etl.entity_id = entity.id
JOIN directory.tag ON tag.id = etl.tag_id
WHERE entity.id = $1
GROUP BY entity.id
RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "directory"."create_entity_type_tag"()
    RETURNS trigger
AS $$
BEGIN
    BEGIN
        INSERT INTO directory.tag (name, tag_group_id) SELECT NEW.name, id FROM directory.tag_group WHERE directory.tag_group.name = 'entity_type';
    EXCEPTION WHEN unique_violation THEN
        UPDATE directory.tag SET tag_group_id = (SELECT id FROM directory.tag_group WHERE directory.tag_group.name = 'entity_type') WHERE tag.name = NEW.name;
    END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "directory"."create_entity_tag_link"()
    RETURNS trigger
AS $$
BEGIN
    INSERT INTO directory.entity_tag_link (entity_id, tag_id) VALUES (NEW.id, (
    SELECT tag.id FROM directory.tag
    INNER JOIN directory.entity_type ON tag.name = entity_type.name
    WHERE entity_type.id = NEW.entity_type_id
    ));

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "directory"."update_entity_tag_link_denorm_for_insert"()
    RETURNS trigger
AS $$
BEGIN
    PERFORM directory.update_denormalized_entity_tags(NEW.entity_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "directory"."update_entity_tag_link_denorm_for_delete"()
    RETURNS trigger
AS $$
BEGIN
    PERFORM directory.update_denormalized_entity_tags(OLD.entity_id);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TRIGGER create_entity_tag_link_for_new_entity
  AFTER INSERT ON "directory"."entity"
  FOR EACH ROW
  EXECUTE PROCEDURE "directory"."create_entity_tag_link"();


CREATE TRIGGER create_tag_for_new_entity_types
  AFTER INSERT ON "directory"."entity_type"
  FOR EACH ROW
  EXECUTE PROCEDURE "directory"."create_entity_type_tag"();


CREATE TRIGGER update_denormalized_tags_on_link_insert
  AFTER INSERT ON "directory"."entity_tag_link"
  FOR EACH ROW
  EXECUTE PROCEDURE "directory"."update_entity_tag_link_denorm_for_insert"();


CREATE TRIGGER update_denormalized_tags_on_link_delete
  AFTER DELETE ON "directory"."entity_tag_link"
  FOR EACH ROW
  EXECUTE PROCEDURE "directory"."update_entity_tag_link_denorm_for_delete"();


CREATE SEQUENCE alias_directory.alias_type_id_seq
  START WITH 2
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "alias_directory"."alias_type"
(
  "name" varchar NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('alias_directory.alias_type_id_seq'::regclass),
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "alias_type_name_lower_idx" ON "alias_directory"."alias_type" USING btree (name, lower((name)::text));



CREATE FUNCTION "alias_directory"."alias_schema"()
    RETURNS name
AS $$
SELECT 'alias'::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "alias_directory"."initialize_alias_type_sql"(alias_directory.alias_type)
    RETURNS text[]
AS $$
SELECT ARRAY[
        format(
            'CREATE TABLE %I.%I ('
            '  id serial PRIMARY KEY,'
            '  %I text UNIQUE NOT NULL,'
            '  entity_id integer REFERENCES directory.entity(id)'
            ');',
            alias_directory.alias_schema(),
            $1.name, $1.name
        )
    ];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "alias_directory"."initialize_alias_type"(alias_directory.alias_type)
    RETURNS alias_directory.alias_type
AS $$
SELECT public.action($1, alias_directory.initialize_alias_type_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "alias_directory"."drop_alias_type_sql"(alias_directory.alias_type)
    RETURNS text
AS $$
SELECT format(
    'DROP TABLE %I.%I;',
    alias_directory.alias_schema(),
    $1.name
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "alias_directory"."delete_alias_type"(alias_directory.alias_type)
    RETURNS alias_directory.alias_type
AS $$
DELETE FROM alias_directory.alias_type WHERE id = $1.id;
SELECT public.action($1, alias_directory.drop_alias_type_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "alias_directory"."get_alias"("entity_id" integer, "alias_type_name" text)
    RETURNS text
AS $$
DECLARE
    result text;
BEGIN
    EXECUTE format(
        'SELECT %I INTO result FROM alias.%I WHERE entity_id = %s',
        $2, $2, $1
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "alias_directory"."create_alias"("entity_id" integer, "alias_type_name" text, "alias" text)
    RETURNS void
AS $$
BEGIN
    EXECUTE format(
        'INSERT INTO alias.%I(entity_id, %I) VALUES ($1, $2)',
        $2, $2
    ) USING $1, $3;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "alias_directory"."define_alias_type"("name" name)
    RETURNS alias_directory.alias_type
AS $$
INSERT INTO alias_directory.alias_type(name) VALUES ($1) RETURNING *;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "alias_directory"."define_alias_type"("name" name) IS 'Define a new alias type, but do not create a table for it.';


CREATE FUNCTION "alias_directory"."create_alias_type"("name" name)
    RETURNS alias_directory.alias_type
AS $$
SELECT alias_directory.initialize_alias_type(
        alias_directory.define_alias_type($1)
    );
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "alias_directory"."create_alias_type"("name" name) IS 'Define a new alias type and created the table for storing the aliases.';


CREATE FUNCTION "alias_directory"."get_entity_by_alias"("alias_type" name, "name" name)
    RETURNS directory.entity
AS $$
DECLARE
    id integer;
BEGIN
    EXECUTE format(
        'SELECT id FROM alias.%I '
        'WHERE %I = ''%s''',
        $1, $1, $2) INTO id;
    RETURN directory.get_entity_by_id(id);
END;
$$ LANGUAGE plpgsql STABLE;


CREATE TYPE "relation_directory"."type_cardinality_enum" AS ENUM (
  'one-to-one',
  'one-to-many',
  'many-to-one'
);



CREATE SEQUENCE relation_directory.type_id_seq
  START WITH 2
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "relation_directory"."type"
(
  "name" name NOT NULL,
  "cardinality" relation_directory.type_cardinality_enum,
  "id" integer NOT NULL DEFAULT nextval('relation_directory.type_id_seq'::regclass),
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "type_name_key" ON "relation_directory"."type" USING btree (name);

GRANT INSERT,UPDATE,DELETE ON TABLE "relation_directory"."type" TO minerva_writer;

GRANT SELECT ON TABLE "relation_directory"."type" TO minerva;



CREATE TABLE "relation"."base"
(
  "source_id" integer NOT NULL,
  "target_id" integer NOT NULL
);

COMMENT ON TABLE "relation"."base" IS 'This table is used as the parent/base table for all relation tables and
therefore can be queried to include all relations of all types.';

GRANT SELECT ON TABLE "relation"."base" TO minerva;



CREATE FUNCTION "relation_directory"."table_schema"()
    RETURNS name
AS $$
SELECT 'relation'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "relation_directory"."view_schema"()
    RETURNS name
AS $$
SELECT 'relation_def'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "relation_directory"."create_relation_table_sql"(relation_directory.type)
    RETURNS text[]
AS $$
SELECT ARRAY[
        format(
            'CREATE TABLE %I.%I ('
            'PRIMARY KEY(source_id, target_id)'
            ') INHERITS (%I.base);',
            relation_directory.table_schema(),
            $1.name,
            relation_directory.table_schema()
        ),
        format(
            'GRANT SELECT ON TABLE %I.%I TO minerva;',
            relation_directory.table_schema(),
            $1.name
        ),
        format(
            'GRANT INSERT,DELETE,UPDATE ON TABLE %I.%I TO minerva_writer;',
            relation_directory.table_schema(),
            $1.name
        ),
        format(
            'CREATE INDEX %I ON %I.%I USING btree (target_id);',
            'ix_' || $1.name || '_target_id',
            relation_directory.table_schema(),
            $1.name
        )
    ];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "relation_directory"."create_relation_table"(relation_directory.type)
    RETURNS relation_directory.type
AS $$
SELECT public.action($1, relation_directory.create_relation_table_sql($1));
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "relation_directory"."drop_relation_table_sql"(relation_directory.type)
    RETURNS text
AS $$
SELECT format('DROP TABLE %I.%I', relation_directory.table_schema(), $1.name);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "relation_directory"."drop_relation_table"(relation_directory.type)
    RETURNS relation_directory.type
AS $$
SELECT public.action($1, relation_directory.drop_relation_table_sql($1));
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "relation_directory"."get_type"(name)
    RETURNS relation_directory.type
AS $$
SELECT type FROM relation_directory.type WHERE name = $1;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "relation_directory"."define"(name)
    RETURNS relation_directory.type
AS $$
INSERT INTO relation_directory.type (name) VALUES ($1) RETURNING type;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "relation_directory"."create_type"(name)
    RETURNS relation_directory.type
AS $$
SELECT relation_directory.create_relation_table(
        relation_directory.define($1)
    );
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "relation_directory"."create_type"(name) IS 'Defines a new relation type, creates the corresponding table and then returns
the new type record';


CREATE FUNCTION "relation_directory"."create_relation_view_sql"(relation_directory.type, text)
    RETURNS text
AS $$
SELECT format(
        'CREATE VIEW %I.%I AS %s',
        relation_directory.view_schema(),
        $1.name,
        $2
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "relation_directory"."create_relation_view"(relation_directory.type, text)
    RETURNS relation_directory.type
AS $$
SELECT public.action(
        $1,
        relation_directory.create_relation_view_sql($1, $2)
    );
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "relation_directory"."create_type"(name, "view_sql" text)
    RETURNS relation_directory.type
AS $$
SELECT relation_directory.create_relation_view(
        relation_directory.create_type($1),
        $2
    );
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "relation_directory"."create_type"(name, "view_sql" text) IS 'Defines a new relation type (just like relation_directory.define(name)),
including a view that will be used to populate the relation table.';


CREATE FUNCTION "relation_directory"."name_to_type"(name)
    RETURNS relation_directory.type
AS $$
SELECT COALESCE(
        relation_directory.get_type($1),
        relation_directory.create_type($1)
    );
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "relation_directory"."drop_relation_view_sql"(relation_directory.type)
    RETURNS text
AS $$
SELECT format(
        'DROP VIEW IF EXISTS %I.%I',
        relation_directory.view_schema(),
        $1.name
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "relation_directory"."drop_relation_view"(relation_directory.type)
    RETURNS relation_directory.type
AS $$
SELECT public.action(
        $1,
        relation_directory.drop_relation_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "relation_directory"."remove"(name)
    RETURNS void
AS $$
SELECT relation_directory.drop_relation_view(
        relation_directory.drop_relation_table(type)
    )
    FROM relation_directory.type WHERE name = $1;

    DELETE FROM relation_directory.type WHERE name = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "relation_directory"."create_or_replace_relation_view_sql"(relation_directory.type, text)
    RETURNS text
AS $$
SELECT format(
        'CREATE OR REPLACE VIEW %I.%I AS %s',
        relation_directory.view_schema(),
        $1.name,
        $2
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "relation_directory"."update"(relation_directory.type, text)
    RETURNS relation_directory.type
AS $$
SELECT public.action(
        $1,
        relation_directory.create_or_replace_relation_view_sql($1, $2)
    );
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "relation_directory"."create_reverse"("reverse" name, "original" name)
    RETURNS relation_directory.type
AS $$
SELECT relation_directory.create_type(
    $1,
    format(
        $query$SELECT
    target_id AS source_id,
    source_id AS target_id
FROM %I.%I$query$,
        relation_directory.view_schema(),
        $2
    )
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "relation_directory"."create_reverse"("reverse" name, "original" relation_directory.type)
    RETURNS relation_directory.type
AS $$
SELECT relation_directory.create_type(
    $1,
    format(
        $query$SELECT
    target_id AS source_id,
    source_id AS target_id
FROM %I.%I$query$,
        relation_directory.view_schema(),
        $2.name
    )
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "relation_directory"."materialize_relation"("type" relation_directory.type)
    RETURNS integer
AS $$
DECLARE
    result integer;
BEGIN
    EXECUTE format('DELETE FROM relation.%I;', $1.name);
    EXECUTE format('INSERT INTO relation.%I SELECT *, %L FROM relation_def.%I;', $1.name, $1.id, $1.name);

    GET DIAGNOSTICS result = ROW_COUNT;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;


CREATE FUNCTION "relation_directory"."create_relation_table_on_insert"()
    RETURNS trigger
AS $$
BEGIN
    PERFORM relation_directory.create_relation_table(NEW);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "relation_directory"."drop_table_on_type_delete"()
    RETURNS trigger
AS $$
BEGIN
    EXECUTE format('DROP TABLE IF EXISTS %I.%I', relation_directory.table_schema(), OLD.name);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE SEQUENCE alias.dn_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "alias"."dn"
(
  "dn" text NOT NULL,
  "entity_id" integer,
  "id" integer NOT NULL DEFAULT nextval('alias.dn_id_seq'::regclass),
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "dn_dn_key" ON "alias"."dn" USING btree (dn);



CREATE FUNCTION "directory"."get_entity_by_dn"(text)
    RETURNS directory.entity
AS $$
SELECT entity
    FROM directory.entity
    JOIN alias.dn ON dn.entity_id = entity.id
    WHERE dn.dn = $1;
$$ LANGUAGE sql STABLE;


CREATE TYPE "directory"."dn_part" AS (
  "type_name" text,
  "name" text
);



CREATE FUNCTION "directory"."dn_part_to_string"(directory.dn_part)
    RETURNS text
AS $$
SELECT $1.type_name || '=' || $1.name;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE CAST (directory.dn_part AS text)
  WITH FUNCTION "directory"."dn_part_to_string"(directory.dn_part);


CREATE FUNCTION "directory"."array_to_dn_part"(text[])
    RETURNS directory.dn_part
AS $$
SELECT CAST(ROW($1[1], $1[2]) AS directory.dn_part);
$$ LANGUAGE sql IMMUTABLE;


CREATE CAST (text[] AS directory.dn_part)
  WITH FUNCTION "directory"."array_to_dn_part"(text[]);


CREATE FUNCTION "directory"."split_raw_part"(text)
    RETURNS directory.dn_part
AS $$
SELECT directory.array_to_dn_part(string_to_array($1, '='));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "directory"."explode_dn"(text)
    RETURNS directory.dn_part[]
AS $$
SELECT array_agg(directory.split_raw_part(raw_part)) FROM unnest(string_to_array($1, ',')) AS raw_part;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "directory"."glue_dn"(directory.dn_part[])
    RETURNS text
AS $$
SELECT
        array_to_string(b.part_arr, ',')
    FROM (
        SELECT array_agg(parts.p) part_arr
        FROM (
            SELECT directory.dn_part_to_string(part) p FROM unnest($1) part
        ) parts
    ) b;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "directory"."parent_dn_parts"(directory.dn_part[])
    RETURNS directory.dn_part[]
AS $$
SELECT
        CASE
            WHEN array_length($1, 1) > 1 THEN
                $1[1:array_length($1, 1) - 1]
            ELSE
                NULL
        END;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "directory"."parent_dn"(text)
    RETURNS text
AS $$
SELECT directory.glue_dn(directory.parent_dn_parts(directory.explode_dn($1)));
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "directory"."last_dn_part"(directory.dn_part[])
    RETURNS directory.dn_part
AS $$
SELECT $1[array_length($1, 1)];
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "directory"."create_entity"(text)
    RETURNS directory.entity
AS $$
INSERT INTO directory.entity(created, name, entity_type_id)
        VALUES (
            now(),
            (directory.last_dn_part(directory.explode_dn($1))).name,
            directory.entity_type_id(directory.name_to_entity_type((directory.last_dn_part(directory.explode_dn($1))).type_name))
        )
        RETURNING entity;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."dn_to_entity"(text)
    RETURNS directory.entity
AS $$
SELECT COALESCE(directory.get_entity_by_dn($1), directory.create_entity($1));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."create_dn_alias"(directory.entity, "dn" text)
    RETURNS directory.entity
AS $$
SELECT alias_directory.create_alias($1.id, 'dn', $2);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "directory"."create_entity_with_alias"(text)
    RETURNS directory.entity
AS $$
SELECT directory.create_dn_alias(new_entity, $1)
    FROM directory.create_entity($1) new_entity;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "directory"."dns_to_entity_ids"(text[])
    RETURNS SETOF integer
AS $$
SELECT (directory.dn_to_entity(dn)).id FROM unnest($1) dn;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."tag_entity"("dn" text, "tag" text)
    RETURNS text
AS $$
INSERT INTO directory.entity_tag_link(tag_id, entity_id)
    SELECT
        f.tag_id,
        f.entity_id
    FROM (
        SELECT
            tag.id AS tag_id,
            dn.entity_id
        FROM directory.tag, alias.dn
        WHERE tag.name = $2 AND dn.dn = $1
    ) f
    LEFT JOIN directory.entity_tag_link ON entity_tag_link.tag_id = f.tag_id AND entity_tag_link.entity_id = f.entity_id
    WHERE entity_tag_link.entity_id IS NULL;

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE TYPE "trend_directory"."trend_descr" AS (
  "name" name,
  "data_type" text,
  "description" text
);



CREATE TYPE "trend_directory"."view_trend_store_part_descr" AS (
  "name" name,
  "query" text
);



CREATE TYPE "trend_directory"."table_trend_store_part_descr" AS (
  "name" name,
  "trends" trend_directory.trend_descr[]
);



CREATE SEQUENCE trend_directory.trend_store_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "trend_directory"."trend_store"
(
  "entity_type_id" integer,
  "data_source_id" integer,
  "granularity" interval NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('trend_directory.trend_store_id_seq'::regclass),
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "trend_store_entity_type_id_data_source_id_granularity_key" ON "trend_directory"."trend_store" USING btree (entity_type_id, data_source_id, granularity);



CREATE SEQUENCE trend_directory.trend_store_part_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "trend_directory"."trend_store_part"
(
  "name" name NOT NULL,
  "trend_store_id" integer NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('trend_directory.trend_store_part_id_seq'::regclass),
  PRIMARY KEY (id)
);



CREATE TABLE "trend_directory"."table_trend_store"
(
  "partition_size" integer NOT NULL,
  "retention_period" interval NOT NULL DEFAULT '1 mon'::interval,
  PRIMARY KEY (id)
)INHERITS ("trend_directory"."trend_store");

COMMENT ON TABLE "trend_directory"."table_trend_store" IS 'Table based trend stores describing the common properties of all its partitions like entity type, data granularity, etc.';



CREATE TABLE "trend_directory"."table_trend_store_part"
(
  PRIMARY KEY (id)
)INHERITS ("trend_directory"."trend_store_part");

COMMENT ON TABLE "trend_directory"."table_trend_store_part" IS 'The parts of a horizontally partitioned table trend store. Each table trend store has at least 1 part.';



CREATE TABLE "trend_directory"."view_trend_store"
(
  PRIMARY KEY (id)
)INHERITS ("trend_directory"."trend_store");

COMMENT ON TABLE "trend_directory"."view_trend_store" IS 'View based trend stores describing the properties like entity type, data granularity, etc.';



CREATE TABLE "trend_directory"."view_trend_store_part"
(
  PRIMARY KEY (id)
)INHERITS ("trend_directory"."trend_store_part");



CREATE SEQUENCE trend_directory.trend_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "trend_directory"."trend"
(
  "trend_store_part_id" integer NOT NULL,
  "name" name NOT NULL,
  "data_type" text NOT NULL,
  "description" text NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('trend_directory.trend_id_seq'::regclass),
  PRIMARY KEY (id)
);



CREATE TABLE "trend_directory"."table_trend"
(
  PRIMARY KEY (id)
)INHERITS ("trend_directory"."trend");



CREATE TABLE "trend_directory"."view_trend"
(
  PRIMARY KEY (id)
)INHERITS ("trend_directory"."trend");



CREATE TABLE "trend_directory"."partition"
(
  "table_trend_store_part_id" integer NOT NULL,
  "index" integer NOT NULL,
  PRIMARY KEY (table_trend_store_part_id, index)
);



CREATE TABLE "trend_directory"."trend_tag_link"
(
  "trend_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY (trend_id, tag_id)
);



CREATE TABLE "trend_directory"."modified"
(
  "table_trend_store_part_id" integer NOT NULL,
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone NOT NULL,
  "end" timestamp with time zone NOT NULL,
  PRIMARY KEY (table_trend_store_part_id, timestamp)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."modified" TO minerva_writer;

GRANT SELECT ON TABLE "trend_directory"."modified" TO minerva;



CREATE SEQUENCE trend_directory.materialization_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "trend_directory"."materialization"
(
  "dst_trend_store_id" integer NOT NULL,
  "processing_delay" interval NOT NULL,
  "stability_delay" interval NOT NULL,
  "reprocessing_period" interval NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('trend_directory.materialization_id_seq'::regclass),
  "enabled" bool NOT NULL DEFAULT false,
  "cost" integer NOT NULL DEFAULT 10,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "trend_directory"."materialization" IS 'Indicates if jobs should be created for this materialization (manual execution is always possible)';

COMMENT ON COLUMN "trend_directory"."materialization"."dst_trend_store_id" IS 'The ID of the destination table_trend_store';

COMMENT ON COLUMN "trend_directory"."materialization"."processing_delay" IS 'The time after the destination timestamp before this materialization can be executed';

COMMENT ON COLUMN "trend_directory"."materialization"."stability_delay" IS 'The time to wait after the most recent modified timestamp before the source data is considered ''stable''';

COMMENT ON COLUMN "trend_directory"."materialization"."reprocessing_period" IS 'The maximum time after the destination timestamp that the materialization is allowed to be executed';

COMMENT ON COLUMN "trend_directory"."materialization"."id" IS 'The unique identifier of this materialization';

COMMENT ON COLUMN "trend_directory"."materialization"."enabled" IS 'Indicates if jobs should be created for this materialization (manual execution is always possible)';

CREATE UNIQUE INDEX "ix_trend_materialization_uniqueness" ON "trend_directory"."materialization" USING btree (dst_trend_store_id);

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."materialization" TO minerva_writer;

GRANT SELECT ON TABLE "trend_directory"."materialization" TO minerva;



CREATE TABLE "trend_directory"."view_materialization"
(
  "src_view" regclass NOT NULL
)INHERITS ("trend_directory"."materialization");

COMMENT ON TABLE "trend_directory"."view_materialization" IS 'A table_materialization is a materialization that uses the data from the function
registered in the src_function column to populate the target trend store.';



CREATE TABLE "trend_directory"."function_materialization"
(
  "src_function" regprocedure NOT NULL
)INHERITS ("trend_directory"."materialization");



CREATE TYPE "trend_directory"."source_fragment" AS (
  "trend_store_id" integer,
  "timestamp" timestamp with time zone
);



CREATE TYPE "trend_directory"."source_fragment_state" AS (
  "fragment" trend_directory.source_fragment,
  "modified" timestamp with time zone
);



CREATE TABLE "trend_directory"."state"
(
  "materialization_id" integer NOT NULL,
  "timestamp" timestamp with time zone NOT NULL,
  "max_modified" timestamp with time zone NOT NULL,
  "source_states" trend_directory.source_fragment_state[],
  "processed_states" trend_directory.source_fragment_state[],
  "job_id" integer,
  PRIMARY KEY (materialization_id, timestamp)
);

COMMENT ON TABLE "trend_directory"."state" IS 'ID of the most recent job for this materialization';

COMMENT ON COLUMN "trend_directory"."state"."materialization_id" IS 'The ID of the materialization type';

COMMENT ON COLUMN "trend_directory"."state"."timestamp" IS 'The timestamp of the materialized (materialization result) data';

COMMENT ON COLUMN "trend_directory"."state"."max_modified" IS 'The greatest modified timestamp of all materialization sources';

COMMENT ON COLUMN "trend_directory"."state"."source_states" IS 'Array of trend_store_id/timestamp/modified combinations for all source data fragments';

COMMENT ON COLUMN "trend_directory"."state"."processed_states" IS 'Array containing a snapshot of the source_states at the time of the most recent materialization';

COMMENT ON COLUMN "trend_directory"."state"."job_id" IS 'ID of the most recent job for this materialization';

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."state" TO minerva_writer;

GRANT SELECT ON TABLE "trend_directory"."state" TO minerva;



CREATE TABLE "trend_directory"."materialization_tag_link"
(
  "materialization_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY (materialization_id, tag_id)
);

COMMENT ON TABLE "trend_directory"."materialization_tag_link" IS 'Links tags to materializations. Examples of tags to link to a materialization
might be: online, offline, aggregation, kpi, etc.';

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."materialization_tag_link" TO minerva_writer;

GRANT SELECT ON TABLE "trend_directory"."materialization_tag_link" TO minerva;



CREATE TABLE "trend_directory"."group_priority"
(
  "tag_id" integer NOT NULL,
  "resources" integer NOT NULL DEFAULT 500,
  PRIMARY KEY (tag_id)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."group_priority" TO minerva_writer;

GRANT SELECT ON TABLE "trend_directory"."group_priority" TO minerva;



CREATE TABLE "trend_directory"."materialization_trend_store_link"
(
  "materialization_id" integer NOT NULL,
  "trend_store_id" integer NOT NULL
);

COMMENT ON TABLE "trend_directory"."materialization_trend_store_link" IS 'Stores the dependencies between a materialization and its source table trend
stores. Multiple levels of views and functions may exist between a
materialization and its source table trend stores. These intermediate views and
functions are not registered here, but only the table trend stores containing
the actual source data used in the views and/or functions.';



CREATE FUNCTION "trend_directory"."base_table_schema"()
    RETURNS name
AS $$
SELECT 'trend'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend_directory"."partition_table_schema"()
    RETURNS name
AS $$
SELECT 'trend_partition'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend_directory"."staging_table_schema"()
    RETURNS name
AS $$
SELECT 'trend'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend_directory"."view_schema"()
    RETURNS name
AS $$
SELECT 'trend'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend_directory"."granularity_to_text"(interval)
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


CREATE FUNCTION "trend_directory"."base_object_name"(trend_directory.trend_store_part)
    RETURNS name
AS $$
SELECT $1.name;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "trend_directory"."base_table_name"(trend_directory.table_trend_store_part)
    RETURNS name
AS $$
SELECT trend_directory.base_object_name($1);
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "trend_directory"."view_name"(trend_directory.view_trend_store_part)
    RETURNS name
AS $$
SELECT trend_directory.base_object_name($1);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."to_char"(trend_directory.trend_store_part)
    RETURNS text
AS $$
SELECT $1.name::text;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."to_char"(trend_directory.table_trend_store_part)
    RETURNS text
AS $$
SELECT $1.name::text;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."to_char"(trend_directory.view_trend_store_part)
    RETURNS text
AS $$
SELECT $1.name::text;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."get_view_trend_store"("data_source_name" text, "entity_type_name" text, "granularity" interval)
    RETURNS trend_directory.view_trend_store
AS $$
SELECT ts
    FROM trend_directory.view_trend_store ts
    JOIN directory.data_source ds ON ds.id = ts.data_source_id
    JOIN directory.entity_type et ON et.id = ts.entity_type_id
    WHERE lower(ds.name) = lower($1) AND lower(et.name) = lower($2) AND ts.granularity = $3;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."create_base_table_sql"("name" text, trend_directory.trend[])
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE TABLE %I.%I ('
        'entity_id integer NOT NULL, '
        '"timestamp" timestamp with time zone NOT NULL, '
        'modified timestamp with time zone NOT NULL '
        '%s'
        ') PARTITION BY RANGE ("timestamp");',
        trend_directory.base_table_schema(),
        name,
        (
            SELECT string_agg(format(',%I %s', t.name, t.data_type), ' ')
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
    )
];
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."create_base_table"("name" name, trend_directory.trend[])
    RETURNS name
AS $$
SELECT public.action($1, trend_directory.create_base_table_sql($1, $2))
$$ LANGUAGE sql VOLATILE STRICT SECURITY DEFINER;


CREATE FUNCTION "trend_directory"."create_base_table"(trend_directory.table_trend_store_part, trend_directory.trend[])
    RETURNS trend_directory.table_trend_store_part
AS $$
SELECT trend_directory.create_base_table(trend_directory.base_table_name($1), $2);
    SELECT $1;
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "trend_directory"."get_trend_store_part_trends"(trend_directory.trend_store_part)
    RETURNS trend_directory.trend[]
AS $$
SELECT COALESCE(array_agg(trend), ARRAY[]::trend_directory.trend[])
    FROM trend_directory.trend
    WHERE trend_store_part_id = $1.id
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."create_base_table"(trend_directory.table_trend_store_part)
    RETURNS trend_directory.table_trend_store_part
AS $$
SELECT trend_directory.create_base_table(
        $1,
        trend_directory.get_trend_store_part_trends($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."staging_table_name"(trend_directory.table_trend_store_part)
    RETURNS name
AS $$
SELECT (trend_directory.base_table_name($1) || '_staging')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."create_staging_table_sql"(trend_directory.table_trend_store_part)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE UNLOGGED TABLE %I.%I (entity_id integer, "timestamp" timestamp with time zone);',
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


CREATE FUNCTION "trend_directory"."create_staging_table"(trend_directory.table_trend_store_part)
    RETURNS trend_directory.table_trend_store_part
AS $$
SELECT public.action($1, trend_directory.create_staging_table_sql($1));
$$ LANGUAGE sql VOLATILE STRICT SECURITY DEFINER;


CREATE FUNCTION "trend_directory"."initialize_table_trend_store_part"(trend_directory.table_trend_store_part)
    RETURNS trend_directory.table_trend_store_part
AS $$
SELECT trend_directory.create_base_table($1);
    SELECT trend_directory.create_staging_table($1);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."initialize_table_trend_store_part"(trend_directory.table_trend_store_part) IS 'Create all database objects required for the trend store part to be fully functional
and capable of storing data.';


CREATE FUNCTION "trend_directory"."create_view"(trend_directory.trend_store_part, name)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT public.action(
        $1,
        format('CREATE VIEW trend.%I AS SELECT * FROM trend.%I', trend_directory.base_object_name($1))
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."get_default_partition_size"("granularity" interval)
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

COMMENT ON FUNCTION "trend_directory"."get_default_partition_size"("granularity" interval) IS 'Return the default partition size in seconds for a particular granularity';


CREATE FUNCTION "trend_directory"."define_table_trend"("trend_store_part_id" integer, "name" name, "data_type" text, "description" text)
    RETURNS trend_directory.table_trend
AS $$
INSERT INTO trend_directory.table_trend (trend_store_part_id, name, data_type, description)
    VALUES ($1, $2, $3, $4)
    RETURNING table_trend;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_view_trend"("trend_store_part_id" integer, "name" name, "data_type" text, "description" text)
    RETURNS trend_directory.view_trend
AS $$
INSERT INTO trend_directory.view_trend (trend_store_part_id, name, data_type, description)
    VALUES ($1, $2, $3, $4)
    RETURNING view_trend;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_view_trend_store"("data_source_name" text, "entity_type_name" text, "granularity" interval)
    RETURNS trend_directory.view_trend_store
AS $$
INSERT INTO trend_directory.view_trend_store (
        data_source_id,
        entity_type_id,
        granularity
    )
    VALUES (
        (directory.name_to_data_source($1)).id,
        (directory.name_to_entity_type($2)).id,
        $3
    ) RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."create_view_sql"(trend_directory.view_trend_store_part, "sql" text)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format('CREATE VIEW %I.%I AS %s;', trend_directory.view_schema(), trend_directory.view_name($1), $2),
    format('GRANT SELECT ON TABLE %I.%I TO minerva;', trend_directory.view_schema(), trend_directory.view_name($1))
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."get_view_trends"("view_name" name)
    RETURNS SETOF trend_directory.trend_descr
AS $$
SELECT (a.attname, format_type(a.atttypid, a.atttypmod), 'deduced from view')::trend_directory.trend_descr
    FROM pg_class c
    JOIN pg_attribute a ON a.attrelid = c.oid
    WHERE c.relname = $1 AND a.attnum >= 0 AND NOT a.attisdropped;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."show_trends"(trend_directory.trend_store_part)
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
        a.attnum > 0 AND trend.trend_store_part_id = $1.id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."create_view_trends"("view" trend_directory.view_trend_store_part)
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


CREATE FUNCTION "trend_directory"."initialize_view_trend_store_part"(trend_directory.view_trend_store_part, "query" text)
    RETURNS trend_directory.view_trend_store_part
AS $$
SELECT public.action($1, trend_directory.create_view_sql($1, $2));

    SELECT trend_directory.create_view_trends($1);

    SELECT $1;
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "trend_directory"."initialize_view_trend_store"(trend_directory.view_trend_store, trend_directory.view_trend_store_part_descr[])
    RETURNS trend_directory.view_trend_store
AS $$
SELECT $1;
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "trend_directory"."create_view_trend_store"("data_source_name" text, "entity_type_name" text, "granularity" interval, trend_directory.view_trend_store_part_descr[])
    RETURNS trend_directory.view_trend_store
AS $$
SELECT trend_directory.initialize_view_trend_store(
        trend_directory.define_view_trend_store($1, $2, $3), $4
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_table_trends"(trend_directory.table_trend_store_part, trend_directory.trend_descr[])
    RETURNS trend_directory.table_trend_store_part
AS $$
INSERT INTO trend_directory.table_trend(name, data_type, trend_store_part_id, description) (
        SELECT name, data_type, $1.id, description FROM unnest($2)
    );

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."partition_name"("base_table_name" name, "index" integer)
    RETURNS name
AS $$
SELECT ($1 || '_' || $2)::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend_directory"."partition_name"(trend_directory.table_trend_store_part, "index" integer)
    RETURNS name
AS $$
SELECT trend_directory.partition_name(trend_directory.base_table_name($1), $2);
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."timestamp_to_index"("partition_size" integer, "timestamp" timestamp with time zone)
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


CREATE FUNCTION "trend_directory"."partition_name"(trend_directory.table_trend_store_part, timestamp with time zone)
    RETURNS name
AS $$
SELECT trend_directory.partition_name(
        $1, trend_directory.timestamp_to_index(table_trend_store.partition_size, $2)
    )
    FROm trend_directory.table_trend_store
    WHERE id = $1.trend_store_id;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."table_name"(trend_directory.partition)
    RETURNS name
AS $$
SELECT trend_directory.partition_name(table_trend_store_part, $1.index)
    FROM trend_directory.table_trend_store_part
    WHERE id = $1.table_trend_store_part_id;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."rename_table_trend_store_part"(trend_directory.table_trend_store_part, name)
    RETURNS trend_directory.table_trend_store_part
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
    WHERE table_trend_store_part_id = $1.id;

    UPDATE trend_directory.table_trend_store_part
    SET name = $2
    WHERE id = $1.id;

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."get_index_on"(name, name)
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


CREATE FUNCTION "trend_directory"."table_trend_store"(trend_directory.table_trend_store_part)
    RETURNS trend_directory.table_trend_store
AS $$
SELECT * FROM trend_directory.table_trend_store
    WHERE id = $1.trend_store_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."get_table_trend_store"("data_source_name" text, "entity_type_name" text, "granularity" interval)
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


CREATE FUNCTION "trend_directory"."define_table_trend_store"("data_source_name" text, "entity_type_name" text, "granularity" interval, "partition_size" integer)
    RETURNS trend_directory.table_trend_store
AS $$
INSERT INTO trend_directory.table_trend_store (
        data_source_id,
        entity_type_id,
        granularity,
        partition_size
    )
    VALUES (
        (directory.name_to_data_source($1)).id,
        (directory.name_to_entity_type($2)).id,
        $3,
        $4
    ) RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."delete_table_trend_store"("name" name)
    RETURNS void
AS $$
DELETE FROM trend_directory.table_trend_store WHERE name = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."table_trend_store_part"(trend_directory.partition)
    RETURNS trend_directory.table_trend_store_part
AS $$
SELECT * FROM trend_directory.table_trend_store_part
    WHERE id = $1.table_trend_store_part_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."initialize_table_trend_store"(trend_directory.table_trend_store)
    RETURNS trend_directory.table_trend_store
AS $$
SELECT trend_directory.initialize_table_trend_store_part(table_trend_store_part)
    FROM trend_directory.table_trend_store_part WHERE trend_store_id = $1.id;

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_table_trend_store_part"("table_trend_store_id" integer, "name" name)
    RETURNS trend_directory.table_trend_store_part
AS $$
INSERT INTO trend_directory.table_trend_store_part (trend_store_id, name)
    VALUES ($1, $2)
    RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_table_trend_store_part"("table_trend_store_id" integer, "name" name, "trends" trend_directory.trend_descr[])
    RETURNS trend_directory.table_trend_store_part
AS $$
SELECT trend_directory.define_table_trends(
        trend_directory.define_table_trend_store_part($1, $2),
        $3
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_table_trend_store"(trend_directory.table_trend_store, trend_directory.table_trend_store_part_descr[])
    RETURNS trend_directory.table_trend_store
AS $$
SELECT trend_directory.define_table_trend_store_part($1.id, name, trends) FROM unnest($2);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_table_trend_store"("data_source_name" text, "entity_type_name" text, "granularity" interval, "partition_size" integer, "trends" trend_directory.table_trend_store_part_descr[])
    RETURNS trend_directory.table_trend_store
AS $$
SELECT trend_directory.define_table_trend_store(
        trend_directory.define_table_trend_store($1, $2, $3, $4),
        $5
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."create_table_trend_store"("data_source_name" text, "entity_type_name" text, "granularity" interval, "partition_size" integer, "parts" trend_directory.table_trend_store_part_descr[])
    RETURNS trend_directory.table_trend_store
AS $$
SELECT trend_directory.initialize_table_trend_store(
        trend_directory.define_table_trend_store($1, $2, $3, $4, $5)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."staged_timestamps"("trend_store_part" trend_directory.table_trend_store_part)
    RETURNS SETOF timestamp with time zone
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT timestamp FROM %I.%I GROUP BY timestamp',
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name(trend_store_part)
    );
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "trend_directory"."transfer_staged"("trend_store_part" trend_directory.table_trend_store_part, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    row_count integer;
BEGIN
    EXECUTE format(
        'INSERT INTO %I.%I SELECT * FROM %I.%I WHERE timestamp = $1',
        trend_directory.partition_table_schema(),
        trend_directory.table_name(trend_directory.attributes_to_partition(
            trend_store_part,
            trend_directory.timestamp_to_index(trend_store.partition_size, timestamp)
        )),
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name(trend_store_part)
    ) USING timestamp;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."transfer_staged"("trend_store_part" trend_directory.table_trend_store_part)
    RETURNS trend_directory.table_trend_store_part
AS $$
SELECT
        trend_directory.transfer_staged(trend_store_part, timestamp)
    FROM trend_directory.staged_timestamps(trend_store_part) timestamp;

    SELECT public.action(
        $1,
        format(
            'TRUNCATE %I.%I',
            trend_directory.staging_table_schema(),
            trend_directory.staging_table_name(trend_store_part)
        )
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."cluster_partition_table_on_timestamp_sql"("name" text)
    RETURNS text
AS $$
SELECT format(
        'CLUSTER %I.%I USING %I',
        trend_directory.partition_table_schema(),
        $1,
        trend_directory.get_index_on($1, 'timestamp')
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."cluster_partition_table_on_timestamp"("name" text)
    RETURNS text
AS $$
SELECT public.action(
        $1,
        trend_directory.cluster_partition_table_on_timestamp_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."alter_trend_name"(trend_directory.table_trend_store_part, "trend_name" name, "new_name" name)
    RETURNS trend_directory.table_trend_store_part
AS $$
UPDATE trend_directory.table_trend
    SET name = $3
    WHERE trend_store_part_id = $1.id AND name = $2;

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


CREATE TYPE "trend_directory"."column_info" AS (
  "name" name,
  "data_type" text
);



CREATE FUNCTION "trend_directory"."table_columns"("namespace" name, "table" name)
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


CREATE FUNCTION "trend_directory"."table_columns"(oid)
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


CREATE FUNCTION "trend_directory"."drop_view_sql"(trend_directory.view_trend_store_part)
    RETURNS text
AS $$
SELECT format(
        'DROP VIEW IF EXISTS %I.%I',
        trend_directory.view_schema(),
        trend_directory.view_name($1)
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."delete_view_trends"(trend_directory.view_trend_store_part)
    RETURNS trend_directory.view_trend_store_part
AS $$
DELETE FROM trend_directory.trend
    WHERE trend_store_part_id = $1.id;

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."drop_view"(trend_directory.view_trend_store_part)
    RETURNS trend_directory.view_trend_store_part
AS $$
SELECT public.action($1, trend_directory.drop_view_sql($1));

    SELECT trend_directory.delete_view_trends($1);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."add_trend_to_trend_store"(trend_directory.table_trend_store_part, trend_directory.table_trend)
    RETURNS trend_directory.table_trend
AS $$
SELECT public.action($2,
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
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."add_trend_to_trend_store"(trend_directory.table_trend_store_part, name, "data_type" text, "description" text)
    RETURNS trend_directory.table_trend
AS $$
SELECT trend_directory.add_trend_to_trend_store(
        $1,
        trend_directory.define_table_trend($1.id, $2, $3, $4)
    )
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."create_table_trend"(trend_directory.table_trend_store_part, trend_directory.trend_descr)
    RETURNS trend_directory.table_trend
AS $$
SELECT trend_directory.add_trend_to_trend_store($1, $2.name, $2.data_type, $2.description);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."create_table_trends"(trend_directory.table_trend_store_part, trend_directory.trend_descr[])
    RETURNS SETOF trend_directory.table_trend
AS $$
SELECT trend_directory.create_table_trend($1, descr)
    FROM unnest($2) descr;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."missing_table_trends"(trend_directory.table_trend_store_part, "required" trend_directory.trend_descr[])
    RETURNS SETOF trend_directory.trend_descr
AS $$
SELECT required
    FROM unnest($2) required
    LEFT JOIN trend_directory.table_trend ON table_trend.name = required.name AND table_trend.trend_store_part_id = $1.id
    WHERE table_trend.id IS NULL;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."assure_table_trends_exist"(trend_directory.table_trend_store_part, trend_directory.trend_descr[])
    RETURNS trend_directory.table_trend_store_part
AS $$
SELECT trend_directory.create_table_trend($1, t)
    FROM trend_directory.missing_table_trends($1, $2) t;

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."get_most_recent_timestamp"("dest_granularity" interval, "ts" timestamp with time zone)
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


CREATE FUNCTION "trend_directory"."is_integer"(varchar)
    RETURNS bool
AS $$
SELECT $1 ~ '^[1-9][0-9]*$'
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend_directory"."get_most_recent_timestamp"("dest_granularity" varchar, "ts" timestamp with time zone)
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


CREATE FUNCTION "trend_directory"."get_timestamp_for"("granularity" interval, "ts" timestamp with time zone)
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


CREATE FUNCTION "trend_directory"."get_timestamp_for"("granularity" varchar, "ts" timestamp with time zone)
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


CREATE FUNCTION "trend_directory"."index_to_timestamp"("partition_size" integer, "index" integer)
    RETURNS timestamp with time zone
AS $$
SELECT to_timestamp($1 * $2 + 1);
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "trend_directory"."data_start"(trend_directory.partition)
    RETURNS timestamp with time zone
AS $$
SELECT trend_directory.index_to_timestamp(
        (trend_directory.table_trend_store(trend_directory.table_trend_store_part($1))).partition_size, $1.index
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."data_end"(trend_directory.partition)
    RETURNS timestamp with time zone
AS $$
SELECT trend_directory.index_to_timestamp(
        (trend_directory.table_trend_store(trend_directory.table_trend_store_part($1))).partition_size, $1.index + 1
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."create_partition_table_sql"(trend_directory.partition)
    RETURNS text[]
AS $$
SELECT ARRAY[
        format(
            'CREATE TABLE %I.%I PARTITION OF trend.%I '
            'FOR VALUES FROM (%L) TO (%L);',
            trend_directory.partition_table_schema(),
            trend_directory.table_name($1),
            trend_directory.base_table_name(trend_directory.table_trend_store_part($1)),
            trend_directory.data_start($1),
            trend_directory.data_end($1)
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


CREATE FUNCTION "trend_directory"."create_partition_table"(trend_directory.partition)
    RETURNS trend_directory.partition
AS $$
SELECT public.action($1, trend_directory.create_partition_table_sql($1));
$$ LANGUAGE sql VOLATILE STRICT SECURITY DEFINER;


CREATE FUNCTION "trend_directory"."get_table_trend"(trend_directory.table_trend_store_part, name)
    RETURNS trend_directory.table_trend
AS $$
SELECT table_trend
    FROM trend_directory.table_trend
    WHERE trend_store_part_id = $1.id AND name = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."get_trends_for_trend_store_part"("trend_store_part_id" integer)
    RETURNS SETOF trend_directory.trend
AS $$
SELECT * FROM trend_directory.trend WHERE trend.trend_store_part_id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."get_trends_for_trend_store_part"(trend_directory.trend_store_part)
    RETURNS SETOF trend_directory.trend
AS $$
SELECT trend_directory.get_trends_for_trend_store_part($1.id);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."trend_store_part_has_trend_with_name"("trend_store" trend_directory.trend_store_part, "trend_name" name)
    RETURNS bool
AS $$
SELECT exists(
        SELECT 1
        FROM trend_directory.trend
        WHERE trend_store_part_id = $1.id AND name = $2
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."column_exists"("table_name" name, "column_name" name)
    RETURNS bool
AS $$
SELECT EXISTS(
        SELECT 1
        FROM pg_attribute a
        JOIN pg_class c ON c.oid = a.attrelid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE c.relname = table_name AND a.attname = column_name AND n.nspname = 'trend'
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."data_type_order"("data_type" text)
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


CREATE FUNCTION "trend_directory"."greatest_data_type"("data_type_a" text, "data_type_b" text)
    RETURNS text
AS $$
SELECT
        CASE WHEN trend_directory.data_type_order($2) > trend_directory.data_type_order($1) THEN
            $2
        ELSE
            $1
        END;
$$ LANGUAGE sql IMMUTABLE;


CREATE AGGREGATE trend_directory.max_data_type (text) (
    sfunc = trend_directory.greatest_data_type,
    stype = text
);



CREATE TYPE "trend_directory"."upgrade_record" AS (
  "timestamp" timestamp with time zone,
  "number_of_rows" integer
);



CREATE FUNCTION "trend_directory"."get_partition"("trend_store_part" trend_directory.table_trend_store_part, "index" integer)
    RETURNS trend_directory.partition
AS $$
SELECT partition
    FROM trend_directory.partition
    WHERE table_trend_store_part_id = $1.id AND index = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."define_partition"("trend_store_part" trend_directory.table_trend_store_part, "index" integer)
    RETURNS trend_directory.partition
AS $$
INSERT INTO trend_directory.partition(
        table_trend_store_part_id,
        index
    )
    VALUES (
        $1.id,
        $2
    )
    RETURNING partition;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."create_partition"("trend_store_part" trend_directory.table_trend_store_part, "index" integer)
    RETURNS trend_directory.partition
AS $$
SELECT trend_directory.create_partition_table(
        trend_directory.define_partition($1, $2)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."attributes_to_partition"(trend_directory.table_trend_store_part, "index" integer)
    RETURNS trend_directory.partition
AS $$
SELECT COALESCE(
        trend_directory.get_partition($1, $2),
        trend_directory.create_partition($1, $2)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."attributes_to_partition"(trend_directory.table_trend_store_part, timestamp with time zone)
    RETURNS trend_directory.partition
AS $$
SELECT trend_directory.attributes_to_partition(
        $1,
        trend_directory.timestamp_to_index(table_trend_store.partition_size, $2)
    )
    FROM trend_directory.table_trend_store WHERE id = $1.trend_store_id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."partition_exists"(trend_directory.partition)
    RETURNS bool
AS $$
SELECT public.table_exists(
        trend_directory.partition_table_schema(),
        trend_directory.table_name($1)
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."partition_exists"(trend_directory.table_trend_store_part, integer)
    RETURNS bool
AS $$
SELECT count(*) = 1
    FROM trend_directory.partition
    WHERE table_trend_store_part_id = $1.id AND index = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."get_trend_store"("id" integer)
    RETURNS trend_directory.trend_store
AS $$
SELECT * FROM trend_directory.trend_store WHERE id = $1
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."get_max_modified"(trend_directory.trend_store, timestamp with time zone)
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


CREATE FUNCTION "trend_directory"."update_modified"("table_trend_store_part_id" integer, "timestamp" timestamp with time zone, "modified" timestamp with time zone)
    RETURNS trend_directory.modified
AS $$
UPDATE trend_directory.modified
    SET "end" = greatest("end", $3)
    WHERE "timestamp" = $2 AND table_trend_store_part_id = $1
    RETURNING modified;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."store_modified"("table_trend_store_part_id" integer, "timestamp" timestamp with time zone, "modified" timestamp with time zone)
    RETURNS trend_directory.modified
AS $$
INSERT INTO trend_directory.modified(
        table_trend_store_part_id, "timestamp", start, "end"
    ) VALUES (
        $1, $2, $3, $3
    ) RETURNING modified;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."mark_modified"("table_trend_store_part_id" integer, "timestamp" timestamp with time zone, "modified" timestamp with time zone)
    RETURNS trend_directory.modified
AS $$
SELECT COALESCE(
        trend_directory.update_modified($1, $2, $3),
        trend_directory.store_modified($1, $2, $3)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."mark_modified"("table_trend_store_id" integer, "timestamp" timestamp with time zone)
    RETURNS trend_directory.modified
AS $$
SELECT COALESCE(
        trend_directory.update_modified($1, $2, now()),
        trend_directory.store_modified($1, $2, now())
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."populate_modified"("partition" trend_directory.partition)
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

COMMENT ON FUNCTION "trend_directory"."populate_modified"("partition" trend_directory.partition) IS 'Populate trend_directory.modified table with modified records from one
partition. This function should only be used in recovery scenarios where the
trend_directory.modified table has become corrupt or records are missing for
some reason.';


CREATE FUNCTION "trend_directory"."populate_modified"(trend_directory.table_trend_store_part)
    RETURNS SETOF trend_directory.modified
AS $$
SELECT
        trend_directory.populate_modified(partition)
    FROM trend_directory.partition
    WHERE table_trend_store_part_id = $1.id;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."populate_modified"(trend_directory.table_trend_store_part) IS 'Populate trend_directory.modified table with modified records from a whole
trend store. This function should only be used in recovery scenarios where the
trend_directory.modified table has become corrupt or records are missing for
some reason.';


CREATE FUNCTION "trend_directory"."available_timestamps"("partition" trend_directory.partition)
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


CREATE TYPE "trend_directory"."transfer_result" AS (
  "row_count" integer,
  "max_modified" timestamp with time zone
);



CREATE FUNCTION "trend_directory"."transfer"("source" trend_directory.trend_store, "target" trend_directory.trend_store, "timestamp" timestamp with time zone, "trend_names" text[])
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


CREATE FUNCTION "trend_directory"."show_trends"("trend_store_part_id" integer)
    RETURNS SETOF trend_directory.trend_descr
AS $$
SELECT trend_directory.show_trends(trend_store_part)
    FROM trend_directory.trend_store_part WHERE id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."clear"(trend_directory.table_trend_store_part, timestamp with time zone)
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


CREATE FUNCTION "trend_directory"."to_char"(trend_directory.materialization)
    RETURNS text
AS $$
SELECT table_trend_store::name::text
    FROM trend_directory.table_trend_store
    WHERE table_trend_store.id = $1.dst_trend_store_id
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."add_new_state"()
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


CREATE FUNCTION "trend_directory"."update_modified_state"()
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


CREATE FUNCTION "trend_directory"."delete_obsolete_state"()
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


CREATE FUNCTION "trend_directory"."update_state"()
    RETURNS text
AS $$
SELECT 'added: ' || trend_directory.add_new_state() || ', updated: ' || trend_directory.update_modified_state() || ', deleted: ' || trend_directory.delete_obsolete_state();
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."dst_trend_store"(trend_directory.materialization)
    RETURNS trend_directory.table_trend_store
AS $$
SELECT * FROM trend_directory.table_trend_store WHERE id = $1.dst_trend_store_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."columns_part"(trend_directory.view_materialization)
    RETURNS text
AS $$
SELECT
        array_to_string(array_agg(quote_ident(name)), ', ')
    FROM
        trend_directory.table_columns(
            $1.src_view::oid
        );
$$ LANGUAGE sql STABLE;


CREATE CAST ("trend_directory"."trend_store_part" AS text)
  WITH FUNCTION "trend_directory"."to_char"("trend_directory"."trend_store_part") AS IMPLICIT;


CREATE CAST ("trend_directory"."table_trend_store_part" AS text)
  WITH FUNCTION "trend_directory"."to_char"("trend_directory"."table_trend_store_part") AS IMPLICIT;


CREATE CAST ("trend_directory"."table_trend_store_part" AS name)
  WITH FUNCTION "trend_directory"."base_table_name"("trend_directory"."table_trend_store_part") AS IMPLICIT;


CREATE CAST ("trend_directory"."view_trend_store_part" AS text)
  WITH FUNCTION "trend_directory"."to_char"("trend_directory"."view_trend_store_part") AS IMPLICIT;


CREATE CAST ("trend_directory"."view_trend_store_part" AS name)
  WITH FUNCTION "trend_directory"."view_name"("trend_directory"."view_trend_store_part") AS IMPLICIT;


CREATE CAST ("trend_directory"."materialization" AS text)
  WITH FUNCTION "trend_directory"."to_char"("trend_directory"."materialization");


CREATE FUNCTION "trend_directory"."changes_on_data_source_update"()
    RETURNS trigger
AS $$
BEGIN
    IF NEW.name <> OLD.name THEN
        UPDATE trend_directory.partition SET
            table_name = trend_directory.to_table_name(partition)
        FROM trend_directory.trend_store ts
        WHERE ts.data_source_id = NEW.id AND ts.id = partition.trend_store_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."cleanup_on_data_source_delete"()
    RETURNS trigger
AS $$
BEGIN
    DELETE FROM trend_directory.trend_store WHERE data_source_id = OLD.id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."changes_on_trend_update"()
    RETURNS trigger
AS $$
DECLARE
    base_table_name text;
BEGIN
    IF NEW.name <> OLD.name THEN
        FOR base_table_name IN
            SELECT trend_directory.base_table_name(trend_store)
            FROM trend_directory.trend
            JOIN trend_directory.trend_store ON trend.trend_store_id = trend_store.id
            WHERE trend.id = NEW.id
        LOOP
            EXECUTE format('ALTER TABLE trend_directory.%I RENAME COLUMN %I TO %I', base_table_name, OLD.name, NEW.name);
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."drop_partition_table_on_delete"()
    RETURNS trigger
AS $$
DECLARE
    kind CHAR;
BEGIN
    SELECT INTO kind relkind
    FROM pg_class
    WHERE relname = trend_directory.table_name(OLD);

    IF kind = 'r' THEN
        EXECUTE format(
            'DROP TABLE IF EXISTS trend_directory.%I CASCADE',
            trend_directory.table_name(OLD)
        );
    ELSIF kind = 'v' THEN
        EXECUTE format(
            'DROP VIEW trend_directory.%I',
            trend_directory.table_name(OLD)
        );
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."update_modified_column"()
    RETURNS trigger
AS $$
BEGIN
    NEW.modified = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."cleanup_table_trend_store_part_on_delete"()
    RETURNS trigger
AS $$
DECLARE
    table_name text;
BEGIN

    EXECUTE format(
        'DROP TABLE IF EXISTS trend.%I CASCADE',
        trend_directory.base_table_name(OLD)
    );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."drop_view_on_delete"()
    RETURNS trigger
AS $$
BEGIN
    PERFORM trend_directory.drop_view(OLD);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TRIGGER propagate_changes_on_update_to_trend
  AFTER UPDATE ON "directory"."data_source"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."changes_on_data_source_update"();


CREATE TRIGGER propagate_changes_on_trend_update
  AFTER UPDATE ON "trend_directory"."trend"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."changes_on_trend_update"();


CREATE TRIGGER drop_table_on_delete
  AFTER DELETE ON "trend_directory"."partition"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."drop_partition_table_on_delete"();


CREATE TRIGGER delete_trend_stores_on_data_source_delete
  BEFORE DELETE ON "directory"."data_source"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."cleanup_on_data_source_delete"();


CREATE TRIGGER cleanup_table_trend_store_part_on_delete
  BEFORE DELETE ON "trend_directory"."table_trend_store_part"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."cleanup_table_trend_store_part_on_delete"();


CREATE TRIGGER drop_view_on_delete
  BEFORE DELETE ON "trend_directory"."view_trend_store"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."drop_view_on_delete"();


CREATE SEQUENCE attribute_directory.attribute_store_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "attribute_directory"."attribute_store"
(
  "data_source_id" integer NOT NULL,
  "entity_type_id" integer NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('attribute_directory.attribute_store_id_seq'::regclass),
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "attribute_store_uniqueness" ON "attribute_directory"."attribute_store" USING btree (data_source_id, entity_type_id);

GRANT INSERT,UPDATE,DELETE ON TABLE "attribute_directory"."attribute_store" TO minerva_writer;

GRANT SELECT ON TABLE "attribute_directory"."attribute_store" TO minerva;



CREATE TYPE "attribute_directory"."attribute_descr" AS (
  "name" name,
  "data_type" text,
  "description" text
);



CREATE SEQUENCE attribute_directory.attribute_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "attribute_directory"."attribute"
(
  "attribute_store_id" integer NOT NULL,
  "description" text,
  "name" name NOT NULL,
  "data_type" text NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('attribute_directory.attribute_id_seq'::regclass),
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "attribute_uniqueness" ON "attribute_directory"."attribute" USING btree (attribute_store_id, name);

GRANT INSERT,UPDATE,DELETE ON TABLE "attribute_directory"."attribute" TO minerva_writer;

GRANT SELECT ON TABLE "attribute_directory"."attribute" TO minerva;



CREATE TABLE "attribute_directory"."attribute_tag_link"
(
  "attribute_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY (attribute_id, tag_id)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "attribute_directory"."attribute_tag_link" TO minerva_writer;

GRANT SELECT ON TABLE "attribute_directory"."attribute_tag_link" TO minerva;



CREATE TABLE "attribute_directory"."attribute_store_modified"
(
  "attribute_store_id" integer NOT NULL,
  "modified" timestamp with time zone NOT NULL,
  PRIMARY KEY (attribute_store_id)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "attribute_directory"."attribute_store_modified" TO minerva_writer;

GRANT SELECT ON TABLE "attribute_directory"."attribute_store_modified" TO minerva;



CREATE TABLE "attribute_directory"."attribute_store_curr_materialized"
(
  "attribute_store_id" integer NOT NULL,
  "materialized" timestamp with time zone NOT NULL,
  PRIMARY KEY (attribute_store_id)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "attribute_directory"."attribute_store_curr_materialized" TO minerva_writer;

GRANT SELECT ON TABLE "attribute_directory"."attribute_store_curr_materialized" TO minerva;



CREATE TABLE "attribute_directory"."attribute_store_compacted"
(
  "attribute_store_id" integer NOT NULL,
  "compacted" timestamp with time zone NOT NULL,
  PRIMARY KEY (attribute_store_id)
);

GRANT INSERT,UPDATE,DELETE ON TABLE "attribute_directory"."attribute_store_compacted" TO minerva_writer;

GRANT SELECT ON TABLE "attribute_directory"."attribute_store_compacted" TO minerva;



CREATE TYPE "attribute_directory"."attribute_info" AS (
  "name" name,
  "data_type" varchar
);



CREATE FUNCTION "attribute_directory"."to_char"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT data_source.name || '_' || entity_type.name
    FROM directory.data_source, directory.entity_type
    WHERE data_source.id = $1.data_source_id AND entity_type.id = $1.entity_type_id;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "attribute_directory"."to_table_name"(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_char($1))::name;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "attribute_directory"."at_function_name"(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_at')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "attribute_directory"."staging_new_view_name"(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_new')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."staging_modified_view_name"(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_modified')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."changes_view_name"(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_changes')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."run_length_view_name"(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_run_length')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."compacted_view_name"(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_compacted')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."curr_ptr_view_name"(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_curr_selection')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."curr_view_name"(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT attribute_directory.to_table_name($1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."curr_ptr_table_name"(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_curr_ptr')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."greatest_data_type"("data_type_a" varchar, "data_type_b" varchar)
    RETURNS varchar
AS $$
BEGIN
    IF trend_directory.data_type_order(data_type_b) > trend_directory.data_type_order(data_type_a) THEN
        RETURN data_type_b;
    ELSE
        RETURN data_type_a;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE FUNCTION "attribute_directory"."render_hash_query"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_hash_function_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_hash_function"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.create_hash_function_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."changes_view_query"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format('SELECT entity_id, timestamp, COALESCE(hash <> lag(hash) OVER w, true) AS change FROM attribute_history.%I WINDOW w AS (PARTITION BY entity_id ORDER BY timestamp asc)', attribute_directory.to_table_name($1));
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."create_changes_view_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_changes_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_changes_view_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."run_length_view_query"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_run_length_view_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_run_length_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_run_length_view_sql($1)
);
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "attribute_directory"."create_run_length_view"(attribute_directory.attribute_store) IS 'Create a view on an attribute_store''s history table that lists the runs of
duplicate attribute data records by their entity ID and start-end. This can
be used as a source for compacting actions.';


CREATE FUNCTION "public"."drop_changes_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
BEGIN
    EXECUTE format('DROP VIEW attribute_history.%I', attribute_directory.to_table_name($1) || '_history_changes');

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."curr_view_query"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'SELECT h.* FROM attribute_history.%I h JOIN attribute_history.%I c ON h.entity_id = c.entity_id AND h.timestamp = c.timestamp',
    attribute_directory.to_table_name($1),
    attribute_directory.curr_ptr_table_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."create_curr_view_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_curr_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.create_curr_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_curr_view_sql"(attribute_directory.attribute_store)
    RETURNS varchar
AS $$
SELECT format('DROP VIEW attribute.%I', attribute_directory.to_table_name($1));
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."drop_curr_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.drop_curr_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_curr_ptr_table_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_curr_ptr_table"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_curr_ptr_table_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_curr_ptr_view_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_curr_ptr_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.create_curr_ptr_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_curr_ptr_view_sql"(attribute_directory.attribute_store)
    RETURNS varchar
AS $$
SELECT format('DROP VIEW attribute_history.%I', attribute_directory.curr_ptr_view_name($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_curr_ptr_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.drop_curr_ptr_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."base_columns"()
    RETURNS text[]
AS $$
SELECT ARRAY[
        'entity_id integer NOT NULL',
        '"timestamp" timestamp with time zone NOT NULL'
    ];
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "attribute_directory"."column_specs"(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
SELECT attribute_directory.base_columns() || array_agg(format('%I %s', name, data_type))
    FROM attribute_directory.attribute
    WHERE attribute_store_id = $1.id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."create_base_table_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_base_table"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action($1, attribute_directory.create_base_table_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."add_first_appearance_to_attribute_table"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_history_table_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_history_table"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action($1, attribute_directory.create_history_table_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_staging_table_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_staging_table"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.create_staging_table_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_staging_new_view_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_staging_new_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.create_staging_new_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_staging_new_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
BEGIN
    EXECUTE format('DROP VIEW attribute_staging.%I', attribute_directory.to_table_name($1) || '_new');

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_staging_modified_view_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_staging_modified_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.create_staging_modified_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_staging_modified_view_sql"(attribute_directory.attribute_store)
    RETURNS varchar
AS $$
SELECT format('DROP VIEW attribute_staging.%I', attribute_directory.staging_modified_view_name($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_staging_modified_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.drop_staging_modified_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."update_curr_materialized"("attribute_store_id" integer, "materialized" timestamp with time zone)
    RETURNS attribute_directory.attribute_store_curr_materialized
AS $$
UPDATE attribute_directory.attribute_store_curr_materialized
    SET materialized = greatest(materialized, $2)
    WHERE attribute_store_id = $1
    RETURNING attribute_store_curr_materialized;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."store_curr_materialized"("attribute_store_id" integer, "materialized" timestamp with time zone)
    RETURNS attribute_directory.attribute_store_curr_materialized
AS $$
INSERT INTO attribute_directory.attribute_store_curr_materialized (attribute_store_id, materialized)
    VALUES ($1, $2)
    RETURNING attribute_store_curr_materialized;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."mark_curr_materialized"("attribute_store_id" integer, "materialized" timestamp with time zone)
    RETURNS attribute_directory.attribute_store_curr_materialized
AS $$
SELECT COALESCE(attribute_directory.update_curr_materialized($1, $2), attribute_directory.store_curr_materialized($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."mark_curr_materialized"("attribute_store_id" integer)
    RETURNS attribute_directory.attribute_store_curr_materialized
AS $$
SELECT attribute_directory.mark_curr_materialized(attribute_store_id, modified)
    FROM attribute_directory.attribute_store_modified
    WHERE attribute_store_id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."update_compacted"("attribute_store_id" integer, "compacted" timestamp with time zone)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
UPDATE attribute_directory.attribute_store_compacted
    SET compacted = greatest(compacted, $2)
    WHERE attribute_store_id = $1
    RETURNING attribute_store_compacted;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."store_compacted"("attribute_store_id" integer, "compacted" timestamp with time zone)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
INSERT INTO attribute_directory.attribute_store_compacted (attribute_store_id, compacted)
    VALUES ($1, $2)
    RETURNING attribute_store_compacted;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."mark_compacted"("attribute_store_id" integer, "compacted" timestamp with time zone)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
SELECT COALESCE(attribute_directory.update_compacted($1, $2), attribute_directory.store_compacted($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."mark_compacted"("attribute_store_id" integer)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
SELECT attribute_directory.mark_compacted(attribute_store_id, modified)
    FROM attribute_directory.attribute_store_modified
    WHERE attribute_store_id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."update_modified"("attribute_store_id" integer, "modified" timestamp with time zone)
    RETURNS attribute_directory.attribute_store_modified
AS $$
UPDATE attribute_directory.attribute_store_modified
    SET modified = greatest(modified, $2)
    WHERE attribute_store_id = $1
    RETURNING attribute_store_modified;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."store_modified"("attribute_store_id" integer, "modified" timestamp with time zone)
    RETURNS attribute_directory.attribute_store_modified
AS $$
INSERT INTO attribute_directory.attribute_store_modified (attribute_store_id, modified)
    VALUES ($1, $2)
    RETURNING attribute_store_modified;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."mark_modified"("attribute_store_id" integer, "modified" timestamp with time zone)
    RETURNS attribute_directory.attribute_store_modified
AS $$
SELECT COALESCE(attribute_directory.update_modified($1, $2), attribute_directory.store_modified($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."mark_modified"("attribute_store_id" integer)
    RETURNS attribute_directory.attribute_store_modified
AS $$
SELECT CASE
        WHEN current_setting('minerva.trigger_mark_modified') = 'off' THEN
            (SELECT asm FROM attribute_directory.attribute_store_modified asm WHERE asm.attribute_store_id = $1)

        ELSE
            attribute_directory.mark_modified($1, now())

        END;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_modified_trigger_function_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_modified_trigger_function"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_modified_trigger_function_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_modified_triggers_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_modified_triggers"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_modified_triggers_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_hash_function"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
BEGIN
    EXECUTE format('DROP FUNCTION attribute_history.values_hash(attribute_history.%I)', attribute_directory.to_table_name($1));

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."get_attribute_store"("data_source_id" integer, "entity_type_id" integer)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_store
    FROM attribute_directory.attribute_store
    WHERE data_source_id = $1 AND entity_type_id = $2;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."define_attribute_store"("data_source_id" integer, "entity_type_id" integer)
    RETURNS attribute_directory.attribute_store
AS $$
INSERT INTO attribute_directory.attribute_store(data_source_id, entity_type_id)
    VALUES ($1, $2) RETURNING attribute_store;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."define_attribute_store"("data_source_name" text, "entity_type_name" text)
    RETURNS attribute_directory.attribute_store
AS $$
INSERT INTO attribute_directory.attribute_store(data_source_id, entity_type_id)
    VALUES ((directory.name_to_data_source($1)).id, (directory.name_to_entity_type($2)).id)
    RETURNING attribute_store;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."add_attributes"(attribute_directory.attribute_store, "attributes" attribute_directory.attribute_descr[])
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


CREATE FUNCTION "attribute_directory"."get_attribute"(attribute_directory.attribute_store, name)
    RETURNS attribute_directory.attribute
AS $$
SELECT attribute
    FROM attribute_directory.attribute
    WHERE attribute_store_id = $1.id AND name = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."define_attribute"(attribute_directory.attribute_store, "name" name, "data_type" text, "description" text)
    RETURNS attribute_directory.attribute
AS $$
INSERT INTO attribute_directory.attribute(attribute_store_id, name, data_type, description)
    VALUES ($1.id, $2, $3, $4)
    RETURNING attribute;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."check_attribute_types"(attribute_directory.attribute_store, attribute_directory.attribute_descr[])
    RETURNS SETOF attribute_directory.attribute
AS $$
UPDATE attribute_directory.attribute SET data_type = n.data_type
    FROM unnest($2) n
    WHERE attribute.name = n.name
    AND attribute.attribute_store_id = $1.id
    AND attribute.data_type <> attribute_directory.greatest_data_type(n.data_type, attribute.data_type)
    RETURNING attribute.*;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."modify_column_type"("table_name" name, "column_name" name, "data_type" text)
    RETURNS void
AS $$
BEGIN
    EXECUTE format('ALTER TABLE attribute_base.%I ALTER %I TYPE %s USING CAST(%I AS %s)', table_name, column_name, data_type, column_name, data_type);
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."modify_column_type"(attribute_directory.attribute_store, "column_name" name, "data_type" text)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_directory.modify_column_type(
        attribute_directory.to_table_name($1), $2, $3
    );

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."transfer_staged"(attribute_directory.attribute_store)
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
        '"timestamp"'
    ];

    SELECT array_to_string(default_columns || array_agg(format('%I', name)), ', ') INTO columns_part
    FROM attribute_directory.attribute
    WHERE attribute_store_id = $1.id;

    EXECUTE format(
        'INSERT INTO attribute_history.%I(%s) SELECT %s FROM attribute_staging.%I',
        table_name, columns_part, columns_part, table_name || '_new'
    );

    SELECT array_to_string(array_agg(format('%I = m.%I', name, name)), ', ') INTO set_columns_part
    FROM attribute_directory.attribute
    WHERE attribute_store_id = $1.id;

    EXECUTE format(
        'UPDATE attribute_history.%I a '
        'SET modified = now(), %s '
        'FROM attribute_staging.%I m '
        'WHERE m.entity_id = a.entity_id AND m.timestamp = a.timestamp',
        table_name, set_columns_part, table_name || '_modified'
    );

    EXECUTE format('TRUNCATE attribute_staging.%I', table_name);

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."compacted_tmp_table_name"(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_compacted_tmp')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."create_compacted_tmp_table_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_compacted_tmp_table"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_compacted_tmp_table_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."compacted_view_query"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_compacted_view_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_compacted_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.create_compacted_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_compacted_view_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format('DROP VIEW attribute_history.%I', attribute_directory.compacted_view_name($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_compacted_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.drop_compacted_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."requires_compacting"("attribute_store_id" integer)
    RETURNS bool
AS $$
SELECT modified <> compacted OR compacted IS NULL
    FROM attribute_directory.attribute_store_modified mod
    LEFT JOIN attribute_directory.attribute_store_compacted cmp ON mod.attribute_store_id = cmp.attribute_store_id
    WHERE mod.attribute_store_id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."requires_compacting"(attribute_directory.attribute_store)
    RETURNS bool
AS $$
SELECT attribute_directory.requires_compacting($1.id);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."compact"(attribute_directory.attribute_store)
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

    EXECUTE format(
        'UPDATE attribute_history.%I '
	'SET modified = now()',
	compacted_tmp_table_name
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

COMMENT ON FUNCTION "attribute_directory"."compact"(attribute_directory.attribute_store) IS 'Remove all subsequent records with duplicate attribute values and update the modified of the first';


CREATE FUNCTION "attribute_directory"."materialize_curr_ptr"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."direct_dependers"("name" text)
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


CREATE FUNCTION "attribute_directory"."dependers"("name" name, "level" integer)
    RETURNS TABLE("name" name, "level" integer)
AS $$
SELECT (d.dependers).* FROM (
        SELECT attribute_directory.dependers(depender, $2 + 1)
        FROM attribute_directory.direct_dependers($1) depender
    ) d
    UNION ALL
    SELECT depender, $2
    FROM attribute_directory.direct_dependers($1) depender;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."dependers"("name" name)
    RETURNS TABLE("name" name, "level" integer)
AS $$
SELECT * FROM attribute_directory.dependers($1, 1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."at_ptr_function_name"(attribute_directory.attribute_store)
    RETURNS name
AS $$
SELECT (attribute_directory.to_table_name($1) || '_at_ptr')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "attribute_directory"."create_at_func_ptr_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_at_func_ptr"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.create_at_func_ptr_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_entity_at_func_ptr_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_entity_at_func_ptr"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.create_entity_at_func_ptr_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_at_func"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."drop_entity_at_func_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION attribute_history.%I(integer, timestamp with time zone)',
    attribute_directory.at_function_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."drop_entity_at_func"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.drop_entity_at_func_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_entity_at_func_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_entity_at_func"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
        $1,
        attribute_directory.create_entity_at_func_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_dependees"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."drop_dependees"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."add_attribute_column"(attribute_directory.attribute_store, name, text)
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


CREATE FUNCTION "attribute_directory"."init"(attribute_directory.attribute)
    RETURNS attribute_directory.attribute
AS $$
SELECT public.action($1,
        ARRAY[
            format('SELECT attribute_directory.add_attribute_column(attribute_store, %L, %L) FROM attribute_directory.attribute_store WHERE id = %s', $1.name, $1.data_type, $1.attribute_store_id)
        ]
    )
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."modify_data_type"(attribute_directory.attribute)
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


CREATE CAST ("attribute_directory"."attribute_store" AS text)
  WITH FUNCTION "attribute_directory"."to_char"("attribute_directory"."attribute_store");


CREATE FUNCTION "attribute_directory"."cleanup_on_data_source_delete"()
    RETURNS trigger
AS $$
BEGIN
    DELETE FROM attribute_directory.attribute_store WHERE data_source_id = OLD.id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."cleanup_on_entity_type_delete"()
    RETURNS trigger
AS $$
BEGIN
    DELETE FROM attribute_directory.attribute_store WHERE entity_type_id = OLD.id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."cleanup_attribute_store_on_delete"()
    RETURNS trigger
AS $$
BEGIN
    PERFORM attribute_directory.drop_dependees(OLD);

    EXECUTE format('DROP TABLE IF EXISTS attribute_base.%I CASCADE', attribute_directory.to_table_name(OLD));

    EXECUTE format('DROP FUNCTION attribute_history.mark_modified_%s()', OLD.id);

    EXECUTE format('DROP FUNCTION attribute_history.%I(integer, timestamp with time zone)', attribute_directory.at_ptr_function_name(OLD));
    EXECUTE format('DROP FUNCTION attribute_history.%I(timestamp with time zone)', attribute_directory.at_ptr_function_name(OLD));

    EXECUTE format('DROP TABLE IF EXISTS attribute_history.%I', attribute_directory.to_table_name(OLD) || '_curr_ptr');

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."cleanup_attribute_after_delete"()
    RETURNS trigger
AS $$
DECLARE
    table_name name;
BEGIN
    SELECT attribute_directory.to_table_name(attribute_store) INTO table_name
    FROM attribute_directory.attribute_store
    WHERE id = OLD.attribute_store_id;

    -- When the delete of the attribute is cascaded from the attribute_store, the
    -- table name can no longer be constructed.
    IF table_name IS NOT NULL THEN
        PERFORM attribute_directory.drop_dependees(attribute_store) FROM attribute_directory.attribute_store WHERE id = OLD.attribute_store_id;

        EXECUTE format('ALTER TABLE attribute_base.%I DROP COLUMN %I', table_name, OLD.name);

        PERFORM attribute_directory.create_dependees(attribute_store) FROM attribute_directory.attribute_store WHERE id = OLD.attribute_store_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."update_data_type_on_change"()
    RETURNS trigger
AS $$
BEGIN
    IF OLD.data_type <> NEW.data_type THEN
        PERFORM attribute_directory.modify_data_type(NEW);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."set_hash"()
    RETURNS trigger
AS $$
BEGIN
    NEW.hash = attribute_history.values_hash(NEW);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_hash_triggers_sql"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."create_hash_triggers"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.create_hash_triggers_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."init"(attribute_directory.attribute_store)
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


CREATE FUNCTION "attribute_directory"."to_attribute"(attribute_directory.attribute_store, "name" name, "data_type" text, "description" text)
    RETURNS attribute_directory.attribute
AS $$
SELECT COALESCE(
        attribute_directory.get_attribute($1, $2),
        attribute_directory.init(attribute_directory.define_attribute($1, $2, $3, $4))
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."check_attributes_exist"(attribute_directory.attribute_store, attribute_directory.attribute_descr[])
    RETURNS SETOF attribute_directory.attribute
AS $$
SELECT attribute_directory.to_attribute($1, n.name, n.data_type, n.description)
    FROM unnest($2) n
    LEFT JOIN attribute_directory.attribute
    ON attribute.attribute_store_id = $1.id AND n.name = attribute.name
    WHERE attribute.name IS NULL;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_attribute_store"("data_source_name" text, "entity_type_name" text)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_directory.init(attribute_directory.define_attribute_store($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_attribute_store"("data_source_name" text, "entity_type_name" text, "attributes" attribute_directory.attribute_descr[])
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_directory.init(
    attribute_directory.add_attributes(attribute_directory.define_attribute_store($1, $2), $3)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_attribute_store"("data_source_id" integer, "entity_type_id" integer, "attributes" attribute_directory.attribute_descr[])
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_directory.init(
        attribute_directory.add_attributes(attribute_directory.define_attribute_store($1, $2), $3)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."to_attribute_store"("data_source_id" integer, "entity_type_id" integer, attribute_directory.attribute_descr[])
    RETURNS attribute_directory.attribute_store
AS $$
SELECT COALESCE(
        attribute_directory.get_attribute_store($1, $2),
        attribute_directory.create_attribute_store($1, $2, $3)
    );
$$ LANGUAGE sql VOLATILE;


CREATE TRIGGER delete_attribute_stores_on_data_source_delete
  BEFORE DELETE ON "directory"."data_source"
  FOR EACH ROW
  EXECUTE PROCEDURE "attribute_directory"."cleanup_on_data_source_delete"();


CREATE TRIGGER delete_attribute_stores_on_entity_type_delete
  BEFORE DELETE ON "directory"."entity_type"
  FOR EACH ROW
  EXECUTE PROCEDURE "attribute_directory"."cleanup_on_entity_type_delete"();


CREATE TRIGGER cleanup_attribute_store_on_delete
  BEFORE DELETE ON "attribute_directory"."attribute_store"
  FOR EACH ROW
  EXECUTE PROCEDURE "attribute_directory"."cleanup_attribute_store_on_delete"();


CREATE TRIGGER update_attribute_type
  AFTER UPDATE ON "attribute_directory"."attribute"
  FOR EACH ROW
  EXECUTE PROCEDURE "attribute_directory"."update_data_type_on_change"();


CREATE TRIGGER after_delete_attribute
  AFTER DELETE ON "attribute_directory"."attribute"
  FOR EACH ROW
  EXECUTE PROCEDURE "attribute_directory"."cleanup_attribute_after_delete"();


CREATE VIEW "attribute_directory"."dependencies" AS
 SELECT dependent.relname AS src,
    pg_attribute.attname AS column_name,
    dependee.relname AS dst
   FROM (((((pg_depend
     JOIN pg_rewrite ON ((pg_depend.objid = pg_rewrite.oid)))
     JOIN pg_class dependee ON ((pg_rewrite.ev_class = dependee.oid)))
     JOIN pg_class dependent ON ((pg_depend.refobjid = dependent.oid)))
     JOIN pg_namespace n ON ((dependent.relnamespace = n.oid)))
     JOIN pg_attribute ON (((pg_depend.refobjid = pg_attribute.attrelid) AND (pg_depend.refobjsubid = pg_attribute.attnum))))
  WHERE ((n.nspname = 'attribute_directory'::name) AND (pg_attribute.attnum > 0));

GRANT SELECT ON TABLE "attribute_directory"."dependencies" TO minerva;


CREATE TYPE "notification_directory"."attr_def" AS (
  "name" name,
  "data_type" name,
  "description" text
);



CREATE SEQUENCE notification_directory.notification_store_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "notification_directory"."notification_store"
(
  "data_source_id" integer,
  "id" integer NOT NULL DEFAULT nextval('notification_directory.notification_store_id_seq'::regclass),
  PRIMARY KEY (id)
);

COMMENT ON TABLE "notification_directory"."notification_store" IS 'Describes notification_stores. Each notification_store maps to a set of tables and functions that can store and manage notifications of a certain type. These corresponding tables and functions are created automatically for each notification_store. Because each notification_store maps one-on-one to a data_source, the name of the notification_store is the same as that of the data_source. Use the create_notification_store function to create new notification_stores.';

CREATE UNIQUE INDEX "uniqueness" ON "notification_directory"."notification_store" USING btree (data_source_id);

GRANT INSERT,UPDATE,DELETE ON TABLE "notification_directory"."notification_store" TO minerva_writer;

GRANT SELECT ON TABLE "notification_directory"."notification_store" TO minerva;



CREATE SEQUENCE notification_directory.attribute_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "notification_directory"."attribute"
(
  "notification_store_id" integer,
  "name" name NOT NULL,
  "data_type" name NOT NULL,
  "description" varchar NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('notification_directory.attribute_id_seq'::regclass),
  PRIMARY KEY (id)
);

COMMENT ON TABLE "notification_directory"."attribute" IS 'Describes attributes of notification stores. An attribute of a notification store is an attribute that each notification stored in that notification store has. An attribute corresponds directly to a column in the main notification store table';

GRANT INSERT,UPDATE,DELETE ON TABLE "notification_directory"."attribute" TO minerva_writer;

GRANT SELECT ON TABLE "notification_directory"."attribute" TO minerva;



CREATE SEQUENCE notification_directory.notification_set_store_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "notification_directory"."notification_set_store"
(
  "name" name NOT NULL,
  "notification_store_id" integer,
  "id" integer NOT NULL DEFAULT nextval('notification_directory.notification_set_store_id_seq'::regclass),
  PRIMARY KEY (id)
);

COMMENT ON TABLE "notification_directory"."notification_set_store" IS 'Describes notification_set_stores. A notification_set_store can hold information over sets of notifications that are related to each other.';

GRANT INSERT,UPDATE,DELETE ON TABLE "notification_directory"."notification_set_store" TO minerva_writer;

GRANT SELECT ON TABLE "notification_directory"."notification_set_store" TO minerva;



CREATE SEQUENCE notification_directory.set_attribute_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "notification_directory"."set_attribute"
(
  "notification_set_store_id" integer,
  "name" name NOT NULL,
  "data_type" name NOT NULL,
  "description" varchar NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('notification_directory.set_attribute_id_seq'::regclass),
  PRIMARY KEY (id)
);

COMMENT ON TABLE "notification_directory"."set_attribute" IS 'Describes attributes of notification_set_stores. A set_attribute of a notification_set_store is an attribute that each notification set has. A set_attribute corresponds directly to a column in the main notification_set_store table.';

GRANT INSERT,UPDATE,DELETE ON TABLE "notification_directory"."set_attribute" TO minerva_writer;

GRANT SELECT ON TABLE "notification_directory"."set_attribute" TO minerva;



CREATE FUNCTION "notification_directory"."notification_store_schema"()
    RETURNS name
AS $$
SELECT 'notification'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "notification_directory"."to_char"(notification_directory.notification_store)
    RETURNS text
AS $$
SELECT data_source.name
    FROM directory.data_source
    WHERE data_source.id = $1.data_source_id;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "notification_directory"."table_name"(notification_directory.notification_store)
    RETURNS name
AS $$
SELECT name::name
    FROM directory.data_source
    WHERE id = $1.data_source_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "notification_directory"."staging_table_name"(notification_directory.notification_store)
    RETURNS name
AS $$
SELECT (notification_directory.table_name($1) || '_staging')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "notification_directory"."create_table_sql"(notification_directory.notification_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
        format(
            'CREATE TABLE %I.%I ('
            '  id serial PRIMARY KEY,'
            '  entity_id integer NOT NULL,'
            '  "timestamp" timestamp with time zone NOT NULL'
            '%s'
            ');',
            notification_directory.notification_store_schema(),
            notification_directory.table_name($1),
            (SELECT array_to_string(array_agg(format(',%I %s', name, data_type)), ' ') FROM notification_directory.attribute WHERE notification_store_id = $1.id)
        ),
        format(
            'ALTER TABLE %I.%I OWNER TO minerva_writer;',
            notification_directory.notification_store_schema(),
            notification_directory.table_name($1)
        ),
        format(
            'GRANT SELECT ON TABLE %I.%I TO minerva;',
            notification_directory.notification_store_schema(),
            notification_directory.table_name($1)
        ),
        format(
            'GRANT INSERT,DELETE,UPDATE '
            'ON TABLE %I.%I TO minerva_writer;',
            notification_directory.notification_store_schema(),
            notification_directory.table_name($1)
        ),
        format(
            'CREATE INDEX %I ON %I.%I USING btree (timestamp);',
            'idx_notification_' || notification_directory.table_name($1) || '_timestamp',
            notification_directory.notification_store_schema(),
            notification_directory.table_name($1)
        )
    ];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "notification_directory"."create_table"(notification_directory.notification_store)
    RETURNS notification_directory.notification_store
AS $$
SELECT public.action($1, notification_directory.create_table_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."initialize_notification_store"(notification_directory.notification_store)
    RETURNS notification_directory.notification_store
AS $$
SELECT notification_directory.create_table($1);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."create_staging_table_sql"(notification_directory.notification_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
        format(
            'CREATE TABLE %I.%I ('
            '  entity_id integer NOT NULL,'
            '  "timestamp" timestamp with time zone NOT NULL'
            '%s'
            ');',
            notification_directory.notification_store_schema(),
            notification_directory.staging_table_name($1),
            (SELECT array_to_string(array_agg(format(',%I %s', name, data_type)), ' ') FROM notification_directory.attribute WHERE notification_store_id = $1.id)
        ),
        format(
            'ALTER TABLE %I.%I OWNER TO minerva_writer;',
            notification_directory.notification_store_schema(),
            notification_directory.staging_table_name($1)
        ),
        format(
            'GRANT SELECT ON TABLE %I.%I TO minerva;',
            notification_directory.notification_store_schema(),
            notification_directory.staging_table_name($1)
        ),
        format(
            'GRANT INSERT,DELETE,UPDATE '
            'ON TABLE %I.%I TO minerva_writer;',
            notification_directory.notification_store_schema(),
            notification_directory.staging_table_name($1)
        )
    ];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "notification_directory"."create_staging_table"(notification_directory.notification_store)
    RETURNS notification_directory.notification_store
AS $$
SELECT public.action($1, notification_directory.create_staging_table_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."define_attribute"(notification_directory.notification_store, name, name, text)
    RETURNS SETOF notification_directory.attribute
AS $$
INSERT INTO notification_directory.attribute(notification_store_id, name, data_type, description)
    VALUES($1.id, $2, $3, $4) RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."define_attributes"(notification_directory.notification_store, notification_directory.attr_def[])
    RETURNS notification_directory.notification_store
AS $$
SELECT notification_directory.define_attribute($1, name, data_type, description)
    FROM unnest($2);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."define_notification_set_store"("name" name, "notification_store_id" integer)
    RETURNS notification_directory.notification_set_store
AS $$
INSERT INTO notification_directory.notification_set_store(name, notification_store_id)
    VALUES ($1, $2)
    RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."notification_store"(notification_directory.notification_set_store)
    RETURNS notification_directory.notification_store
AS $$
SELECT notification_store FROM notification_directory.notification_store WHERE id = $1.notification_store_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "notification_directory"."get_notification_store"("data_source_name" name)
    RETURNS notification_directory.notification_store
AS $$
SELECT ns
    FROM notification_directory.notification_store ns
    JOIN directory.data_source ds ON ds.id = ns.data_source_id
    WHERE ds.name = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "notification_directory"."define_notification_store"("data_source_id" integer)
    RETURNS notification_directory.notification_store
AS $$
INSERT INTO notification_directory.notification_store(data_source_id)
    VALUES ($1)
    RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."define_notification_store"("data_source_id" integer, notification_directory.attr_def[])
    RETURNS notification_directory.notification_store
AS $$
SELECT notification_directory.define_attributes(
        notification_directory.define_notification_store($1),
        $2
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."create_notification_store"("data_source_id" integer, notification_directory.attr_def[])
    RETURNS notification_directory.notification_store
AS $$
SELECT notification_directory.initialize_notification_store(
        notification_directory.define_notification_store($1, $2)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."create_notification_store"("data_source_name" text, notification_directory.attr_def[])
    RETURNS notification_directory.notification_store
AS $$
SELECT notification_directory.create_notification_store(
        (directory.name_to_data_source($1)).id, $2
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."create_notification_store"("data_source_id" integer)
    RETURNS notification_directory.notification_store
AS $$
SELECT notification_directory.create_notification_store(
        $1, ARRAY[]::notification_directory.attr_def[]
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."create_notification_store"("data_source_name" text)
    RETURNS notification_directory.notification_store
AS $$
SELECT notification_directory.create_notification_store(
        (directory.name_to_data_source($1)).id
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."init_notification_set_store"(notification_directory.notification_set_store)
    RETURNS notification_directory.notification_set_store
AS $$
BEGIN
    EXECUTE format(
        'CREATE TABLE %I.%I('
        '  id serial PRIMARY KEY'
        ')',
        notification_directory.notification_store_schema(),
        $1.name
    );

    EXECUTE format(
        'CREATE TABLE %I.%I('
        '  notification_id integer REFERENCES %I.%I ON DELETE CASCADE,'
        '  set_id integer REFERENCES %I.%I ON DELETE CASCADE'
        ')',
        notification_directory.notification_store_schema(),
        $1.name || '_link',
        notification_directory.notification_store_schema(),
        notification_directory.table_name(notification_directory.notification_store($1)),
        notification_directory.notification_store_schema(),
        $1.name
    );

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "notification_directory"."create_notification_set_store"("name" name, "notification_store_id" integer)
    RETURNS notification_directory.notification_set_store
AS $$
SELECT notification_directory.init_notification_set_store(
        notification_directory.define_notification_set_store($1, $2)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."create_notification_set_store"("name" name, notification_directory.notification_store)
    RETURNS notification_directory.notification_set_store
AS $$
SELECT notification_directory.create_notification_set_store($1, $2.id);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."get_column_type_name"("namespace_name" name, "table_name" name, "column_name" name)
    RETURNS name
AS $$
SELECT typname
    FROM pg_type
    JOIN pg_attribute ON pg_attribute.atttypid = pg_type.oid
    JOIN pg_class ON pg_class.oid = pg_attribute.attrelid
    JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE nspname = $1 AND relname = $2 AND attname = $3 AND attnum > 0 AND not pg_attribute.attisdropped;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "notification_directory"."get_column_type_name"(notification_directory.notification_store, name)
    RETURNS name
AS $$
SELECT notification_directory.get_column_type_name(
        notification_directory.notification_store_schema(),
        notification_directory.table_name($1),
        $2
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "notification_directory"."add_attribute_column_sql"(name, notification_directory.attribute)
    RETURNS text
AS $$
SELECT format(
        'ALTER TABLE %I.%I ADD COLUMN %I %s',
        notification_directory.notification_store_schema(),
        $1, $2.name, $2.data_type
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "notification_directory"."add_staging_attribute_column_sql"(notification_directory.attribute)
    RETURNS text
AS $$
SELECT
        format(
            'ALTER TABLE %I.%I ADD COLUMN %I %s',
            notification_directory.notification_store_schema(),
            notification_directory.staging_table_name(notification_store), $1.name, $1.data_type
        )
    FROM notification_directory.notification_store WHERE id = $1.notification_store_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "notification_directory"."create_attribute_column"(notification_directory.attribute)
    RETURNS notification_directory.attribute
AS $$
SELECT
    public.action(
        $1,
        notification_directory.add_attribute_column_sql(
            notification_directory.table_name(notification_store),
            $1
        )
    )
FROM notification_directory.notification_store WHERE id = $1.notification_store_id;

SELECT
    public.action(
        $1,
        notification_directory.add_attribute_column_sql(
            notification_directory.staging_table_name(notification_store),
            $1
        )
    )
FROM notification_directory.notification_store WHERE id = $1.notification_store_id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."get_attr_defs"(notification_directory.notification_store)
    RETURNS SETOF notification_directory.attr_def
AS $$
SELECT (attname, typname, '')::notification_directory.attr_def
    FROM pg_type
    JOIN pg_attribute ON pg_attribute.atttypid = pg_type.oid
    JOIN pg_class ON pg_class.oid = pg_attribute.attrelid
    JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE
    nspname = notification_directory.notification_store_schema() AND
    relname = notification_directory.table_name($1) AND
    attnum > 0 AND
    NOT attname IN ('id', 'entity_id', 'timestamp') AND
    NOT pg_attribute.attisdropped;
$$ LANGUAGE sql STABLE;


CREATE CAST ("notification_directory"."notification_store" AS text)
  WITH FUNCTION "notification_directory"."to_char"("notification_directory"."notification_store");


CREATE FUNCTION "notification_directory"."drop_table_on_delete"()
    RETURNS trigger
AS $$
BEGIN
    EXECUTE format(
        'DROP TABLE IF EXISTS %I.%I CASCADE',
        notification_directory.notification_store_schema(),
        notification_directory.staging_table_name(OLD)
    );

    EXECUTE format(
        'DROP TABLE IF EXISTS %I.%I CASCADE',
        notification_directory.notification_store_schema(),
        notification_directory.table_name(OLD)
    );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "notification_directory"."drop_notification_set_store_table_on_delete"()
    RETURNS trigger
AS $$
BEGIN
    EXECUTE format(
        'DROP TABLE IF EXISTS %I.%I',
        notification_directory.notification_store_schema(),
        OLD.name || '_link'
    );

    EXECUTE format(
        'DROP TABLE IF EXISTS %I.%I',
        notification_directory.notification_store_schema(),
        OLD.name
    );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "notification_directory"."cleanup_on_data_source_delete"()
    RETURNS trigger
AS $$
BEGIN
    DELETE FROM notification_directory.notification_store WHERE data_source_id = OLD.id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TRIGGER drop_table_on_delete
  BEFORE DELETE ON "notification_directory"."notification_store"
  FOR EACH ROW
  EXECUTE PROCEDURE "notification_directory"."drop_table_on_delete"();


CREATE TRIGGER drop_notification_set_store_table_on_delete
  BEFORE DELETE ON "notification_directory"."notification_set_store"
  FOR EACH ROW
  EXECUTE PROCEDURE "notification_directory"."drop_notification_set_store_table_on_delete"();


CREATE TRIGGER delete_notification_stores_on_data_source_delete
  BEFORE DELETE ON "directory"."data_source"
  FOR EACH ROW
  EXECUTE PROCEDURE "notification_directory"."cleanup_on_data_source_delete"();


CREATE FUNCTION "virtual_entity"."update"("name" name)
    RETURNS integer
AS $$
DECLARE
    result integer;
BEGIN
    EXECUTE format('SELECT count(directory.dn_to_entity(v.dn)) FROM virtual_entity.%I v LEFT JOIN directory.entity ON entity.dn = v.dn WHERE entity.dn IS NULL', name) INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE SEQUENCE entity_tag.type_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "entity_tag"."type"
(
  "name" name,
  "tag_group_id" integer NOT NULL,
  "id" integer NOT NULL DEFAULT nextval('entity_tag.type_id_seq'::regclass)
);

CREATE UNIQUE INDEX "type_name_key" ON "entity_tag"."type" USING btree (name);



CREATE UNLOGGED TABLE "entity_tag"."entity_tag_link_staging"
(
  "entity_id" integer NOT NULL,
  "tag_name" text NOT NULL,
  "tag_group_id" integer NOT NULL
);

GRANT INSERT,UPDATE,DELETE ON TABLE "entity_tag"."entity_tag_link_staging" TO minerva_writer;

GRANT SELECT ON TABLE "entity_tag"."entity_tag_link_staging" TO minerva;



CREATE FUNCTION "entity_tag"."create_view_sql"("type_name" name, "sql" text)
    RETURNS text[]
AS $$
SELECT ARRAY[
        format('CREATE VIEW entity_tag.%I AS %s;', type_name, sql),
        format('GRANT SELECT ON TABLE entity_tag.%I TO minerva;', type_name)
    ];
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "entity_tag"."create_view"("type_name" name, "sql" text)
    RETURNS name
AS $$
SELECT public.action($1, entity_tag.create_view_sql($1, $2));
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "entity_tag"."define"("type_name" name, "tag_group" text, "sql" text)
    RETURNS entity_tag.type
AS $$
INSERT INTO entity_tag.type(name, tag_group_id)
    SELECT type_name, id FROM directory.tag_group WHERE name = $2;

    SELECT entity_tag.create_view($1, $3);

    SELECT * FROM entity_tag.type WHERE name = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "entity_tag"."transfer_to_staging"("name" name)
    RETURNS bigint
AS $$
DECLARE
    insert_count bigint;
BEGIN
    EXECUTE format('INSERT INTO entity_tag.entity_tag_link_staging(entity_id, tag_name, tag_group_id)
SELECT entity_id, tag, tag_group_id FROM entity_tag.%I, entity_tag.type WHERE type.name = $1', name)
    USING name;

    GET DIAGNOSTICS insert_count = ROW_COUNT;

    RETURN insert_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE VIEW "entity_tag"."_new_tags_in_staging" AS
 SELECT staging.tag_name AS name,
    staging.tag_group_id
   FROM (entity_tag.entity_tag_link_staging staging
     LEFT JOIN directory.tag ON ((lower((tag.name)::text) = lower(staging.tag_name))))
  WHERE (tag.name IS NULL)
  GROUP BY staging.tag_name, staging.tag_group_id;

GRANT SELECT ON TABLE "entity_tag"."_new_tags_in_staging" TO minerva;


CREATE FUNCTION "entity_tag"."add_new_tags"()
    RETURNS bigint
AS $$
WITH t AS (
        INSERT INTO directory.tag(name, tag_group_id, description)
        SELECT name, tag_group_id, 'created by entity_tag.update'
        FROM entity_tag._new_tags_in_staging
        RETURNING *
    )
    SELECT count(*) FROM t;
$$ LANGUAGE sql VOLATILE;


CREATE VIEW "entity_tag"."_new_links_in_staging" AS
 SELECT staging.entity_id,
    tag.id AS tag_id
   FROM ((entity_tag.entity_tag_link_staging staging
     JOIN directory.tag ON ((lower((tag.name)::text) = lower(staging.tag_name))))
     LEFT JOIN directory.entity_tag_link etl ON (((etl.entity_id = staging.entity_id) AND (etl.tag_id = tag.id))))
  WHERE (etl.entity_id IS NULL);

GRANT SELECT ON TABLE "entity_tag"."_new_links_in_staging" TO minerva;


CREATE FUNCTION "entity_tag"."add_new_links"("add_limit" integer)
    RETURNS bigint
AS $$
WITH t AS (
        INSERT INTO directory.entity_tag_link(entity_id, tag_id)
        SELECT entity_id, tag_id
        FROM entity_tag._new_links_in_staging
        LIMIT $1
        RETURNING *
    )
    SELECT count(*) FROM t;
$$ LANGUAGE sql VOLATILE;


CREATE VIEW "entity_tag"."_obsolete_links" AS
 SELECT etl.entity_id,
    etl.tag_id
   FROM ((directory.entity_tag_link etl
     JOIN directory.tag ON ((tag.id = etl.tag_id)))
     LEFT JOIN entity_tag.entity_tag_link_staging staging ON (((staging.tag_name = (tag.name)::text) AND (staging.entity_id = etl.entity_id))))
  WHERE (((tag.name)::text IN ( SELECT entity_tag_link_staging.tag_name
           FROM entity_tag.entity_tag_link_staging
          GROUP BY entity_tag_link_staging.tag_name)) AND (staging.entity_id IS NULL));

GRANT SELECT ON TABLE "entity_tag"."_obsolete_links" TO minerva;


CREATE FUNCTION "entity_tag"."remove_obsolete_links"()
    RETURNS bigint
AS $$
WITH t AS (
        DELETE FROM directory.entity_tag_link
        USING entity_tag._obsolete_links
        WHERE entity_tag_link.entity_id = _obsolete_links.entity_id AND entity_tag_link.tag_id = _obsolete_links.tag_id
        RETURNING *
    )
    SELECT count(*) FROM t;
$$ LANGUAGE sql VOLATILE;


CREATE TYPE "entity_tag"."process_staged_links_result" AS (
  "tags_added" bigint,
  "links_added" bigint,
  "links_removed" bigint
);



CREATE FUNCTION "entity_tag"."process_staged_links"("process_limit" integer)
    RETURNS entity_tag.process_staged_links_result
AS $$
DECLARE
    result entity_tag.process_staged_links_result;
BEGIN
    result.tags_added = entity_tag.add_new_tags();
    result.links_added = entity_tag.add_new_links($1);
    result.links_removed = entity_tag.remove_obsolete_links();

    TRUNCATE entity_tag.entity_tag_link_staging;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TYPE "entity_tag"."update_result" AS (
  "staged" bigint,
  "tags_added" bigint,
  "links_added" bigint,
  "links_removed" bigint
);



CREATE FUNCTION "entity_tag"."update"("type_name" name, "update_limit" integer DEFAULT 50000)
    RETURNS entity_tag.update_result
AS $$
DECLARE
    result entity_tag.update_result;
    process_result entity_tag.process_staged_links_result;
BEGIN
    result.staged = entity_tag.transfer_to_staging(type_name);

    process_result = entity_tag.process_staged_links(update_limit);

    result.tags_added = process_result.tags_added;
    result.links_added = process_result.links_added;
    result.links_removed = process_result.links_removed;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TYPE "trigger"."kpi_def" AS (
  "name" name,
  "data_type" name
);



CREATE SEQUENCE trigger.rule_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "trigger"."rule"
(
  "name" name,
  "notification_store_id" integer,
  "granularity" interval,
  "default_interval" interval,
  "id" integer NOT NULL DEFAULT nextval('trigger.rule_id_seq'::regclass),
  "enabled" bool NOT NULL DEFAULT false,
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "rule_name_key" ON "trigger"."rule" USING btree (name);

GRANT UPDATE ON TABLE "trigger"."rule" TO minerva_writer;

GRANT SELECT ON TABLE "trigger"."rule" TO minerva;



CREATE SEQUENCE trigger.exception_base_id_seq
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;


CREATE TABLE "trigger"."exception_base"
(
  "entity_id" integer,
  "start" timestamp with time zone,
  "expires" timestamp with time zone,
  "id" integer NOT NULL DEFAULT nextval('trigger.exception_base_id_seq'::regclass),
  "created" timestamp with time zone DEFAULT now()
);

GRANT UPDATE ON TABLE "trigger"."exception_base" TO minerva_writer;

GRANT SELECT ON TABLE "trigger"."exception_base" TO minerva;



CREATE TABLE "trigger"."rule_tag_link"
(
  "rule_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY (rule_id, tag_id)
);

GRANT UPDATE ON TABLE "trigger"."rule_tag_link" TO minerva_writer;

GRANT SELECT ON TABLE "trigger"."rule_tag_link" TO minerva;



CREATE FUNCTION "trigger"."table_exists"("schema_name" name, "table_name" name)
    RETURNS bool
AS $$
SELECT exists(
        SELECT 1
        FROM pg_class
        JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
        WHERE relname = $2 AND relkind = 'r' AND pg_namespace.nspname = $1
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."view_exists"("schema_name" name, "table_name" name)
    RETURNS bool
AS $$
SELECT exists(
        SELECT 1
        FROM pg_class
        JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
        WHERE relname = $2 AND relkind = 'v' AND pg_namespace.nspname = $1
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."action"(anyelement, "sql" text)
    RETURNS anyelement
AS $$
BEGIN
    EXECUTE sql;

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trigger"."action"(anyelement, "sql" text[])
    RETURNS anyelement
AS $$
DECLARE
    statement text;
BEGIN
    FOREACH statement IN ARRAY sql LOOP
        EXECUTE statement;
    END LOOP;

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trigger"."with_threshold_view_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_with_threshold')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."weight_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_weight')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."exception_weight_table_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_exception_weight')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."exception_threshold_table_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_exception_threshold')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."get_rule"(name)
    RETURNS trigger.rule
AS $$
SELECT rule FROM "trigger".rule WHERE name = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."add_rule"(name)
    RETURNS trigger.rule
AS $$
INSERT INTO "trigger".rule (name)
    VALUES ($1) RETURNING rule;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."define"(name)
    RETURNS trigger.rule
AS $$
SELECT COALESCE(trigger.get_rule($1), trigger.add_rule($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."threshold_view_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_threshold')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."rule_view_name"(trigger.rule)
    RETURNS name
AS $$
SELECT $1.name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."get_rule_view_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT
	pg_get_viewdef(oid, true)
FROM pg_class
WHERE relname = trigger.rule_view_name($1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."rule_view_sql"(trigger.rule, "where_clause" text)
    RETURNS text
AS $$
SELECT format(
    'SELECT * FROM trigger_rule.%I WHERE %s;',
    trigger.with_threshold_view_name($1), $2
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_rule_view_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP VIEW trigger_rule.%I CASCADE', $1.name);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_rule_view_sql"(trigger.rule, "rule_view_sql" text)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format('CREATE OR REPLACE VIEW trigger_rule.%I AS %s', trigger.rule_view_name($1), $2),
    format('ALTER VIEW trigger_rule.%I OWNER TO minerva_admin', trigger.rule_view_name($1)),
    format('GRANT SELECT ON trigger_rule.%I TO minerva', trigger.rule_view_name($1))
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_rule_view"(trigger.rule, "rule_view_sql" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, trigger.create_rule_view_sql($1, $2));
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "trigger"."kpi_view_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_kpi')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."get_kpi_view_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT
	pg_get_viewdef(oid, true)
FROM pg_class
WHERE relname = trigger.kpi_view_name($1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."kpi_view_sql"(trigger.rule, "sql" text)
    RETURNS text
AS $$
SELECT format(
    'CREATE OR REPLACE VIEW trigger_rule.%I AS %s',
    "trigger".kpi_view_name($1), $2
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_kpi_view_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP VIEW trigger_rule.%I CASCADE', "trigger".kpi_view_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_kpi_view_sql"(trigger.rule, "sql" text)
    RETURNS text[]
AS $$
SELECT ARRAY[
    trigger.kpi_view_sql($1, $2),
    format('ALTER VIEW trigger_rule.%I OWNER TO minerva_admin', trigger.kpi_view_name($1)),
    format('GRANT SELECT ON trigger_rule.%I TO minerva', trigger.kpi_view_name($1))
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_kpi_view"(trigger.rule, "sql" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, trigger.create_kpi_view_sql($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."notification_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_create_notification')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."get_notification_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT
	pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = trigger.notification_fn_name($1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_notification_fn_sql"(trigger.rule, "expression" text)
    RETURNS text
AS $$
SELECT format(
'CREATE OR REPLACE FUNCTION trigger_rule.%I(trigger_rule.%I)
	RETURNS text
AS $function$
SELECT (%s)::text
$function$ LANGUAGE SQL IMMUTABLE',
    trigger.notification_fn_name($1),
    $1.name,
    $2
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_notification_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION trigger_rule.%I(trigger_rule.%I)', trigger.notification_fn_name($1), $1.name);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_notification_fn"(trigger.rule, "expression" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, trigger.create_notification_fn_sql($1, $2));
    SELECT trigger.action($1, format('ALTER FUNCTION trigger_rule.%I(trigger_rule.%I) OWNER TO minerva_admin', trigger.notification_fn_name($1), $1.name));
    SELECT trigger.action($1, format('GRANT EXECUTE ON FUNCTION trigger_rule.%I(trigger_rule.%I) TO minerva', trigger.notification_fn_name($1), $1.name));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."notification_view_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_notification')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."notification_view_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'CREATE OR REPLACE VIEW trigger_rule.%I AS
SELECT
    n.entity_id,
    n.timestamp,
    COALESCE(exc.weight, trigger_rule.%I(n)) AS weight,
    trigger_rule.%I(n) AS details
FROM trigger_rule.%I AS n
LEFT JOIN trigger_rule.%I AS exc ON
    exc.entity_id = n.entity_id AND
    exc.start <= n.timestamp AND
    exc.expires > n.timestamp',
    trigger.notification_view_name($1),
    trigger.weight_fn_name($1),
    trigger.notification_fn_name($1),
    $1.name,
    trigger.exception_weight_table_name($1)
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_notification_view_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP VIEW trigger_rule.%I', trigger.notification_view_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_notification_view_sql"(trigger.rule)
    RETURNS text[]
AS $$
SELECT ARRAY[
    trigger.notification_view_sql($1),
    format('ALTER VIEW trigger_rule.%I OWNER TO minerva_admin', trigger.notification_view_name($1)),
    format('GRANT SELECT ON trigger_rule.%I TO minerva', trigger.notification_view_name($1))
];
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_notification_view"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, trigger.create_notification_view_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."notification_threshold_test_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_notification_test_threshold')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."notification_test_threshold_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'CREATE OR REPLACE FUNCTION trigger_rule.%I AS
SELECT
    n.entity_id,
    n.timestamp,
    trigger_rule.%I(n) AS weight,
    trigger_rule.%I(n) AS details
FROM trigger_rule.%I AS n',
    trigger.notification_threshold_test_fn_name($1),
    trigger.weight_fn_name($1),
    trigger.notification_fn_name($1),
    $1.name
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."get_with_threshold_view_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT
	pg_get_viewdef(oid, true)
FROM pg_class
WHERE relname = trigger.with_threshold_view_name($1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."get_threshold_defs"(trigger.rule)
    RETURNS SETOF trigger.kpi_def
AS $$
SELECT (attname, typname)::trigger.kpi_def
    FROM pg_type
    JOIN pg_attribute ON pg_attribute.atttypid = pg_type.oid
    JOIN pg_class ON pg_class.oid = pg_attribute.attrelid
    JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE
    nspname = 'trigger_rule' AND
    relname = "trigger".threshold_view_name($1) AND
    attnum > 0 AND
    NOT pg_attribute.attisdropped;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."with_threshold_view_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
$view$
SELECT
    kpi.*,
    %s
FROM trigger_rule.%I AS threshold, trigger_rule.%I AS kpi
LEFT JOIN trigger_rule.%I exc ON
    exc.entity_id = kpi.entity_id AND
    exc.start <= timestamp AND
    exc.expires > timestamp
$view$,
    array_to_string(array_agg(format('COALESCE(exc.%I, threshold.%I) AS %I', kpi.name, kpi.name, 'threshold_' || kpi.name)), ', '),
    trigger.threshold_view_name($1),
    trigger.kpi_view_name($1),
    trigger.exception_threshold_table_name($1)
)
FROM trigger.get_threshold_defs($1) kpi;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_with_threshold_view"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, format('CREATE OR REPLACE VIEW trigger_rule.%I AS %s', trigger.with_threshold_view_name($1), trigger.with_threshold_view_sql($1)));
SELECT trigger.action($1, format('ALTER VIEW trigger_rule.%I OWNER TO minerva_admin', trigger.with_threshold_view_name($1)));
SELECT trigger.action($1, format('GRANT SELECT ON trigger_rule.%I TO minerva', trigger.with_threshold_view_name($1)));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."drop_with_threshold_view_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP VIEW trigger_rule.%I', trigger.with_threshold_view_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."get_weight_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT
	pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = trigger.weight_fn_name($1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."weight_fn_sql"(trigger.rule, "expression" text)
    RETURNS text
AS $$
SELECT format(
$function$
CREATE OR REPLACE FUNCTION trigger_rule.%I(trigger_rule.%I)
    RETURNS integer AS
$weight_fn$SELECT (%s)$weight_fn$ LANGUAGE SQL IMMUTABLE;
$function$,
        trigger.weight_fn_name($1),
        $1.name,
        $2
    );
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_weight_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION trigger_rule.%I(trigger_rule.%I)', trigger.weight_fn_name($1), $1.name);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."exception_weight_table_sql"(trigger.rule)
    RETURNS text
AS $function$
SELECT format(
    $$CREATE TABLE trigger_rule.%I
    (
        id serial,
        entity_id integer references directory.entity(id),
        created timestamp with time zone not null default now(),
        start timestamp with time zone not null default now(),
        expires timestamp with time zone not null default now() + interval '3 months',
        weight integer not null
    );$$,
    trigger.exception_weight_table_name($1)
);
$function$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_exception_weight_table"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, trigger.exception_weight_table_sql($1));
SELECT trigger.action($1, format('ALTER TABLE trigger_rule.%I OWNER TO minerva_admin', trigger.exception_weight_table_name($1)));
SELECT trigger.action($1, format('GRANT SELECT ON trigger_rule.%I TO minerva', trigger.exception_weight_table_name($1)));
SELECT trigger.action($1, format('GRANT INSERT, UPDATE, DELETE ON trigger_rule.%I TO minerva_writer', trigger.exception_weight_table_name($1)));
SELECT trigger.action(
	$1,
	format(
		'GRANT USAGE, SELECT ON SEQUENCE %s TO minerva_writer',
		pg_get_serial_sequence(format('trigger_rule.%I', trigger.exception_weight_table_name($1)), 'id')
	)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."drop_exception_weight_table_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP TABLE IF EXISTS trigger_rule.%I', trigger.exception_weight_table_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."notification_type_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_notification_details')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_notification_type_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    $type$
    CREATE TYPE trigger_rule.%I AS (
        entity_id integer,
        timestamp timestamp with time zone,
        details text
    )
    $type$,
    trigger.notification_type_name($1)
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_notification_type_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP TYPE IF EXISTS trigger_rule.%I', trigger.notification_type_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_notification_type"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT trigger.action(
        $1,
        trigger.create_notification_type_sql($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."define_notification"(name, "expression" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.create_notification_fn(trigger.get_rule($1), $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_dummy_notification_fn"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT trigger.create_notification_fn($1, quote_literal($1.name));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."drop_exception_threshold_table_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP TABLE IF EXISTS trigger_rule.%I', trigger.exception_threshold_table_name($1))
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."get_kpi_defs"(trigger.rule)
    RETURNS SETOF trigger.kpi_def
AS $$
SELECT (attname, typname)::trigger.kpi_def
    FROM pg_type
    JOIN pg_attribute ON pg_attribute.atttypid = pg_type.oid
    JOIN pg_class ON pg_class.oid = pg_attribute.attrelid
    JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE
    nspname = 'trigger_rule' AND
    relname = "trigger".kpi_view_name($1) AND
    attnum > 0 AND
    NOT attname IN ('entity_id', 'timestamp') AND
    NOT pg_attribute.attisdropped;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."get_kpi_def"(trigger.rule, name)
    RETURNS trigger.kpi_def
AS $$
DECLARE
    result trigger.kpi_def;
BEGIN
    SELECT INTO result * FROM trigger.get_kpi_defs($1) WHERE name = $2;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'no such KPI: ''%''', $2;
    END IF;

    RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "trigger"."create_exception_threshold_table_sql"(trigger.rule, name[])
    RETURNS text
AS $$
SELECT format(
    'CREATE TABLE trigger_rule.%I
    (
        id serial,
        entity_id integer references directory.entity(id),
        created timestamp with time zone default now(),
        start timestamp with time zone,
        expires timestamp with time zone,
        remark text,
        %s
    );',
    trigger.exception_threshold_table_name($1),
    array_to_string(array_agg(quote_ident(kpi.name) || ' ' || kpi.data_type), ', ')
)
FROM (
    SELECT (trigger.get_kpi_def($1, kpi_name)).* FROM unnest($2) kpi_name
) kpi;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_exception_threshold_table"(trigger.rule, name[])
    RETURNS trigger.rule
AS $$
SELECT "trigger".action($1, trigger.create_exception_threshold_table_sql($1, $2));
SELECT trigger.action($1, format('ALTER TABLE trigger_rule.%I OWNER TO minerva_admin', trigger.exception_threshold_table_name($1)));
SELECT trigger.action($1, format('GRANT SELECT ON trigger_rule.%I TO minerva', trigger.exception_threshold_table_name($1)));
SELECT trigger.action($1, format('GRANT INSERT, UPDATE, DELETE ON trigger_rule.%I TO minerva_writer', trigger.exception_threshold_table_name($1)));
SELECT trigger.action(
	$1,
	format(
		'GRANT USAGE, SELECT ON SEQUENCE %s TO minerva_writer',
		pg_get_serial_sequence(format('trigger_rule.%I', trigger.exception_threshold_table_name($1)), 'id')
	)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."set_thresholds_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_set_thresholds')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."set_thresholds"(trigger.rule, "exprs" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, format(
        'CREATE OR REPLACE VIEW trigger_rule.%I AS '
        'SELECT %s',
        trigger.threshold_view_name($1),
        $2
    ));
    SELECT trigger.action($1, format(
        'ALTER VIEW trigger_rule.%I OWNER TO minerva_admin', trigger.threshold_view_name($1)
    ));
    SELECT trigger.action($1, format(
        'GRANT SELECT ON trigger_rule.%I TO minerva', trigger.threshold_view_name($1)
    ));

    SELECT $1;
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "trigger"."create_set_thresholds_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
        $def$CREATE OR REPLACE FUNCTION trigger_rule.%I(%s) RETURNS integer AS
$function$
BEGIN
    EXECUTE format('CREATE OR REPLACE VIEW trigger_rule.%I AS SELECT %s', %s);
    RETURN 42;
END;
$function$ LANGUAGE plpgsql VOLATILE$def$,
	trigger.set_thresholds_fn_name($1),
	array_to_string(array_agg(format('%I %s', t.name, t.data_type)), ', '),
	trigger.threshold_view_name($1),
	array_to_string(array_agg(format('%%L::%s AS %I', t.data_type, t.name)), ', '),
	array_to_string(array_agg(format('$%s', t.row_num)), ', ')
    ) FROM (SELECT d.*, row_number() over() AS row_num FROM trigger.get_threshold_defs($1) d) t;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_set_thresholds_fn"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, trigger.create_set_thresholds_fn_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."drop_set_thresholds_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION trigger_rule.%I(%s)',
    trigger.set_thresholds_fn_name($1),
    array_to_string(array_agg(format('%s', t.data_type)), ', ')
)
FROM trigger.get_threshold_defs($1) t;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_thresholds_view_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP VIEW trigger_rule.%I', trigger.threshold_view_name($1))
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."set_thresholds"(name, "exprs" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.set_thresholds(trigger.get_rule($1), $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_dummy_thresholds"(trigger.rule, name[])
    RETURNS trigger.rule
AS $$
SELECT trigger.set_thresholds(
        $1,
        array_to_string(array_agg(format('NULL::%I %I', kpi.data_type, kpi.name)), ', ')
    ) FROM (
        SELECT (trigger.get_kpi_def($1, kpi_name)).* FROM unnest($2) kpi_name
    ) kpi;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."set_weight"(trigger.rule, "expression" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, trigger.weight_fn_sql($1, $2));
    SELECT trigger.action($1, format('ALTER FUNCTION trigger_rule.%I(trigger_rule.%I) OWNER TO minerva_admin', trigger.weight_fn_name($1), $1.name));
    SELECT trigger.action($1, format('GRANT EXECUTE ON FUNCTION trigger_rule.%I(trigger_rule.%I) TO minerva', trigger.weight_fn_name($1), $1.name));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."set_weight"(name, "expression" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.set_weight(trigger.get_rule($1), $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_dummy_default_weight"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT trigger.set_weight($1, 'SELECT 1');
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."add_insert_trigger"(notification_directory.notification_store)
    RETURNS notification_directory.notification_store
AS $$
BEGIN
    EXECUTE format(
        $query$
        CREATE OR REPLACE FUNCTION notification.%I()
            RETURNS trigger AS
        $fnbody$
        BEGIN
            IF new.weight IS NULL THEN
                RAISE WARNING 'notification of rule %% entity %% timestamp %% has weight NULL', new.rule_id, new.entity_id, new.timestamp;
                RETURN NULL;
            ELSE
                RETURN new;
            END IF;
        END;
        $fnbody$ LANGUAGE plpgsql IMMUTABLE;
        $query$,
        notification_directory.staging_table_name($1) || '_insert_checks'
    );

    EXECUTE format(
        $query$
        CREATE TRIGGER check_notifications_trigger
            BEFORE INSERT
            ON notification.%I
            FOR EACH ROW
            EXECUTE PROCEDURE notification.%I();
        $query$,
        notification_directory.staging_table_name($1),
        notification_directory.staging_table_name($1) || '_insert_checks'
    );

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trigger"."create_trigger_notification_store"(name)
    RETURNS notification_directory.notification_store
AS $$
SELECT trigger.add_insert_trigger(
    notification_directory.create_staging_table(
        notification_directory.create_notification_store($1, ARRAY[
            ('created', 'timestamp with time zone', 'time of notification creation'),
            ('rule_id', 'integer', 'source rule for this notification'),
            ('weight', 'integer', 'weight/importance of the notification'),
            ('details', 'text', 'extra information')
        ]::notification_directory.attr_def[])
    )
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."transfer_notifications_from_staging"(notification_directory.notification_store)
    RETURNS integer
AS $$
DECLARE
    num_rows integer;
BEGIN
    EXECUTE format(
$query$
INSERT INTO notification.%I(entity_id, timestamp, created, rule_id, weight, details)
SELECT staging.entity_id, staging.timestamp, staging.created, staging.rule_id, staging.weight, staging.details
FROM notification.%I staging
LEFT JOIN notification.%I target ON target.entity_id = staging.entity_id AND target.timestamp = staging.timestamp AND target.rule_id = staging.rule_id
WHERE target.entity_id IS NULL;
$query$,
        notification_directory.table_name($1), notification_directory.staging_table_name($1), notification_directory.table_name($1));

    GET DIAGNOSTICS num_rows = ROW_COUNT;

    EXECUTE format('DELETE FROM notification.%I', notification_directory.staging_table_name($1));

    RETURN num_rows;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trigger"."create_notifications"(trigger.rule, notification_directory.notification_store, timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    num_rows integer;
BEGIN
    EXECUTE format(
$query$
INSERT INTO notification.%I(entity_id, timestamp, created, rule_id, weight, details)
(SELECT entity_id, timestamp, now(), $1, weight, details FROM trigger_rule.%I WHERE timestamp = $2)
$query$,
        notification_directory.staging_table_name($2), trigger.notification_view_name($1)
    )
    USING $1.id, $3;

    SELECT trigger.transfer_notifications_from_staging($2) INTO num_rows;

    RETURN num_rows;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trigger"."create_notifications"(trigger.rule, timestamp with time zone)
    RETURNS integer
AS $$
SELECT
        trigger.create_notifications($1, notification_store, $2)
    FROM notification_directory.notification_store
    WHERE id = $1.notification_store_id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_notifications"(trigger.rule, notification_directory.notification_store, interval)
    RETURNS integer
AS $$
DECLARE
    num_rows integer;
BEGIN
    EXECUTE format(
$query$
INSERT INTO notification.%I(entity_id, timestamp, created, rule_id, weight, details)
(SELECT entity_id, timestamp, now(), $1, weight, details FROM trigger_rule.%I WHERE timestamp > now() - $2)
$query$,
        notification_directory.staging_table_name($2), trigger.notification_view_name($1)
    )
    USING $1.id, $3;

    SELECT trigger.transfer_notifications_from_staging($2) INTO num_rows;

    RETURN num_rows;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trigger"."create_notifications"(trigger.rule, interval)
    RETURNS integer
AS $$
SELECT trigger.create_notifications($1, notification_store, $2)
    FROM notification_directory.notification_store
    WHERE id = $1.notification_store_id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_notifications"(trigger.rule)
    RETURNS integer
AS $$
SELECT trigger.create_notifications($1, notification_store, $1.default_interval)
    FROM notification_directory.notification_store
    WHERE id = $1.notification_store_id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_notifications"("rule_name" name, "notification_store_name" name, timestamp with time zone)
    RETURNS integer
AS $$
SELECT trigger.create_notifications(
        trigger.get_rule($1),
        notification_directory.get_notification_store($2),
        $3
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_notifications"("rule_name" name, timestamp with time zone)
    RETURNS integer
AS $$
SELECT trigger.create_notifications(rule, notification_store, $2)
    FROM trigger.rule
    JOIN notification_directory.notification_store ON notification_store.id = rule.notification_store_id
    WHERE rule.name = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_notifications"("rule_name" name, "notification_store_name" name, interval)
    RETURNS integer
AS $$
SELECT trigger.create_notifications(
        trigger.get_rule($1),
        notification_directory.get_notification_store($2),
        $3
    );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_notifications"("rule_name" name, interval)
    RETURNS integer
AS $$
SELECT trigger.create_notifications(trigger.get_rule($1), $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_notifications"("rule_name" name)
    RETURNS integer
AS $$
SELECT trigger.create_notifications(trigger.get_rule($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."setup_rule"(trigger.rule, "kpi_sql" text, name[], "sql" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.create_kpi_view($1, $2);
    SELECT trigger.create_dummy_thresholds($1, $3);
    SELECT trigger.create_exception_threshold_table($1, $3);
    SELECT trigger.create_with_threshold_view($1);
    SELECT trigger.create_exception_weight_table($1);
    SELECT trigger.create_rule_view($1, trigger.rule_view_sql($1, $4));
    SELECT trigger.create_notification_type($1);
    SELECT trigger.create_dummy_default_weight($1);
    SELECT trigger.create_dummy_notification_fn($1);
    SELECT trigger.create_notification_view($1);
    SELECT trigger.create_set_thresholds_fn($1);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_rule"(name, "kpi_sql" text, name[], "sql" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.setup_rule(trigger.define($1), $2, $3, $4);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."cleanup_rule"(trigger.rule)
    RETURNS trigger.rule
AS $$
BEGIN
    EXECUTE trigger.drop_set_thresholds_fn_sql($1);
    EXECUTE trigger.drop_rule_view_sql($1);
    EXECUTE trigger.drop_kpi_view_sql($1);
    --EXECUTE trigger.drop_notification_fn_sql($1);
    --EXECUTE trigger.drop_notification_view_sql($1);
    --EXECUTE trigger.drop_with_threshold_view_sql($1);
    --EXECUTE trigger.drop_weight_fn_sql($1);
    EXECUTE trigger.drop_exception_weight_table_sql($1);
    EXECUTE trigger.drop_thresholds_view_sql($1);
    EXECUTE trigger.drop_exception_threshold_table_sql($1);
    EXECUTE trigger.drop_notification_type_sql($1);

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trigger"."tag"("tag_name" varchar, "rule_id" integer)
    RETURNS trigger.rule_tag_link
AS $$
INSERT INTO trigger.rule_tag_link (rule_id, tag_id)
        SELECT $2, tag.id FROM directory.tag WHERE name = $1
        RETURNING *;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trigger"."tag"("tag_name" varchar, "rule_id" integer) IS 'Add tag with name tag_name to rule with id rule_id.
The tag must already exist.';


CREATE FUNCTION "trigger"."truncate"(timestamp with time zone, interval)
    RETURNS timestamp with time zone
AS $$
SELECT CASE
        WHEN $2 = '1 day' THEN
            date_trunc('day', $1)
        WHEN $2 = '1 week' THEN
            date_trunc('week', $1)
        ELSE
            to_timestamp((
                extract(epoch FROM $1)::integer / extract(epoch FROM $2)::integer
            )::integer * extract(epoch FROM $2))
        END;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."timestamps"(trigger.rule)
    RETURNS SETOF timestamp with time zone
AS $$
SELECT generate_series(
        trigger.truncate(now(), $1.granularity),
        trigger.truncate(now(), $1.granularity) - $1.default_interval,
        - $1.granularity
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."cleanup_on_rule_delete"()
    RETURNS trigger
AS $$
BEGIN
	PERFORM trigger.cleanup_rule(OLD);

	RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TRIGGER cleanup_on_rule_delete
  BEFORE DELETE ON "trigger"."rule"
  FOR EACH ROW
  EXECUTE PROCEDURE "trigger"."cleanup_on_rule_delete"();


CREATE TABLE "relation"."parent"
(
  PRIMARY KEY (source_id, target_id)
)INHERITS ("relation"."base");

CREATE INDEX "ix_parent_target_id" ON "relation"."parent" USING btree (target_id);

GRANT INSERT,UPDATE,DELETE ON TABLE "relation"."parent" TO minerva_writer;

GRANT SELECT ON TABLE "relation"."parent" TO minerva;



INSERT INTO "directory"."tag_group" (name, complementary, id) VALUES ('default', False, 1);


INSERT INTO "directory"."tag_group" (name, complementary, id) VALUES ('entity_type', True, 2);


INSERT INTO "relation_directory"."type" (name, cardinality, id) VALUES ('parent', null, 1);


INSERT INTO "alias_directory"."alias_type" (name, id) VALUES ('dn', 1);


ALTER TABLE "alias"."dn"
  ADD CONSTRAINT "dn_entity_id_fkey"
  FOREIGN KEY (entity_id)
  REFERENCES "directory"."entity" (id);

ALTER TABLE "attribute_directory"."attribute_store"
  ADD CONSTRAINT "attribute_attribute_store_entity_type_id_fkey"
  FOREIGN KEY (entity_type_id)
  REFERENCES "directory"."entity_type" (id) ON DELETE CASCADE;

ALTER TABLE "attribute_directory"."attribute_store"
  ADD CONSTRAINT "attribute_attribute_store_data_source_id_fkey"
  FOREIGN KEY (data_source_id)
  REFERENCES "directory"."data_source" (id);

ALTER TABLE "attribute_directory"."attribute"
  ADD CONSTRAINT "attribute_attribute_attribute_store_id_fkey"
  FOREIGN KEY (attribute_store_id)
  REFERENCES "attribute_directory"."attribute_store" (id) ON DELETE CASCADE;

ALTER TABLE "attribute_directory"."attribute_tag_link"
  ADD CONSTRAINT "attribute_tag_link_tag_id_fkey"
  FOREIGN KEY (tag_id)
  REFERENCES "directory"."tag" (id) ON DELETE CASCADE;

ALTER TABLE "attribute_directory"."attribute_tag_link"
  ADD CONSTRAINT "attribute_tag_link_attribute_id_fkey"
  FOREIGN KEY (attribute_id)
  REFERENCES "attribute_directory"."attribute" (id) ON DELETE CASCADE;

ALTER TABLE "attribute_directory"."attribute_store_modified"
  ADD CONSTRAINT "attribute_store_modified_attribute_store_id_fkey"
  FOREIGN KEY (attribute_store_id)
  REFERENCES "attribute_directory"."attribute_store" (id) ON DELETE CASCADE;

ALTER TABLE "attribute_directory"."attribute_store_curr_materialized"
  ADD CONSTRAINT "attribute_store_curr_materialized_attribute_store_id_fkey"
  FOREIGN KEY (attribute_store_id)
  REFERENCES "attribute_directory"."attribute_store" (id) ON DELETE CASCADE;

ALTER TABLE "attribute_directory"."attribute_store_compacted"
  ADD CONSTRAINT "attribute_store_compacted_attribute_store_id_fkey"
  FOREIGN KEY (attribute_store_id)
  REFERENCES "attribute_directory"."attribute_store" (id) ON DELETE CASCADE;

ALTER TABLE "directory"."entity"
  ADD CONSTRAINT "entity_entity_type_id_fkey"
  FOREIGN KEY (entity_type_id)
  REFERENCES "directory"."entity_type" (id) ON DELETE CASCADE;

ALTER TABLE "directory"."tag"
  ADD CONSTRAINT "tag_tag_group_id_fkey"
  FOREIGN KEY (tag_group_id)
  REFERENCES "directory"."tag_group" (id) ON DELETE CASCADE;

ALTER TABLE "directory"."entity_tag_link"
  ADD CONSTRAINT "entity_tag_link_entity_id_fkey"
  FOREIGN KEY (entity_id)
  REFERENCES "directory"."entity" (id) ON DELETE CASCADE;

ALTER TABLE "directory"."entity_tag_link"
  ADD CONSTRAINT "entity_tag_link_tag_id_fkey"
  FOREIGN KEY (tag_id)
  REFERENCES "directory"."tag" (id) ON DELETE CASCADE;

ALTER TABLE "entity_tag"."type"
  ADD CONSTRAINT "type_tag_group_id_fkey"
  FOREIGN KEY (tag_group_id)
  REFERENCES "directory"."tag_group" (id) ON DELETE CASCADE;

ALTER TABLE "notification_directory"."notification_store"
  ADD CONSTRAINT "notification_store_data_source_id_fkey"
  FOREIGN KEY (data_source_id)
  REFERENCES "directory"."data_source" (id) ON DELETE CASCADE;

ALTER TABLE "notification_directory"."attribute"
  ADD CONSTRAINT "attribute_notification_store_id_fkey"
  FOREIGN KEY (notification_store_id)
  REFERENCES "notification_directory"."notification_store" (id) ON DELETE CASCADE;

ALTER TABLE "notification_directory"."notification_set_store"
  ADD CONSTRAINT "notification_set_store_notification_store_id_fkey"
  FOREIGN KEY (notification_store_id)
  REFERENCES "notification_directory"."notification_store" (id) ON DELETE CASCADE;

ALTER TABLE "notification_directory"."set_attribute"
  ADD CONSTRAINT "set_attribute_notification_set_store_id_fkey"
  FOREIGN KEY (notification_set_store_id)
  REFERENCES "notification_directory"."notification_set_store" (id) ON DELETE CASCADE;

ALTER TABLE "system"."job"
  ADD CONSTRAINT "job_job_source_id_fkey"
  FOREIGN KEY (job_source_id)
  REFERENCES "system"."job_source" (id) ON DELETE CASCADE;

ALTER TABLE "system"."job_queue"
  ADD CONSTRAINT "job_queue_job_id_fkey"
  FOREIGN KEY (job_id)
  REFERENCES "system"."job" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."trend_store"
  ADD CONSTRAINT "trend_store_entity_type_id_fkey"
  FOREIGN KEY (entity_type_id)
  REFERENCES "directory"."entity_type" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."trend_store"
  ADD CONSTRAINT "trend_store_data_source_id_fkey"
  FOREIGN KEY (data_source_id)
  REFERENCES "directory"."data_source" (id);

ALTER TABLE "trend_directory"."table_trend_store_part"
  ADD CONSTRAINT "table_trend_store_part_trend_store_id_fkey"
  FOREIGN KEY (trend_store_id)
  REFERENCES "trend_directory"."table_trend_store" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."view_trend_store_part"
  ADD CONSTRAINT "view_trend_store_part_trend_store_id_fkey"
  FOREIGN KEY (trend_store_id)
  REFERENCES "trend_directory"."view_trend_store" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."table_trend"
  ADD CONSTRAINT "table_trend_trend_store_part_id_fkey"
  FOREIGN KEY (trend_store_part_id)
  REFERENCES "trend_directory"."table_trend_store_part" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."view_trend"
  ADD CONSTRAINT "view_trend_trend_store_part_id_fkey"
  FOREIGN KEY (trend_store_part_id)
  REFERENCES "trend_directory"."view_trend_store_part" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."partition"
  ADD CONSTRAINT "partition_table_trend_store_part_id_fkey"
  FOREIGN KEY (table_trend_store_part_id)
  REFERENCES "trend_directory"."table_trend_store_part" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."trend_tag_link"
  ADD CONSTRAINT "trend_tag_link_trend_id_fkey"
  FOREIGN KEY (trend_id)
  REFERENCES "trend_directory"."trend" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."trend_tag_link"
  ADD CONSTRAINT "trend_tag_link_tag_id_fkey"
  FOREIGN KEY (tag_id)
  REFERENCES "directory"."tag" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."modified"
  ADD CONSTRAINT "modified_table_trend_store_part_id_fkey"
  FOREIGN KEY (table_trend_store_part_id)
  REFERENCES "trend_directory"."table_trend_store_part" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."materialization"
  ADD CONSTRAINT "materialization_dst_trend_store_id_fkey"
  FOREIGN KEY (dst_trend_store_id)
  REFERENCES "trend_directory"."table_trend_store" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."state"
  ADD CONSTRAINT "materialization_state_materialization_id_fkey"
  FOREIGN KEY (materialization_id)
  REFERENCES "trend_directory"."materialization" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."materialization_tag_link"
  ADD CONSTRAINT "materialization_tag_link_tag_id_fkey"
  FOREIGN KEY (tag_id)
  REFERENCES "directory"."tag" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."materialization_tag_link"
  ADD CONSTRAINT "materialization_tag_link_materialization_id_fkey"
  FOREIGN KEY (materialization_id)
  REFERENCES "trend_directory"."materialization" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."group_priority"
  ADD CONSTRAINT "group_priority_tag_id_fkey"
  FOREIGN KEY (tag_id)
  REFERENCES "directory"."tag" (id);

ALTER TABLE "trend_directory"."materialization_trend_store_link"
  ADD CONSTRAINT "materialization_trend_store_link_materialization_id_fkey"
  FOREIGN KEY (materialization_id)
  REFERENCES "trend_directory"."materialization" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."materialization_trend_store_link"
  ADD CONSTRAINT "materialization_trend_store_link_trend_store_id_fkey"
  FOREIGN KEY (trend_store_id)
  REFERENCES "trend_directory"."table_trend_store" (id) ON DELETE CASCADE;

ALTER TABLE "trigger"."rule"
  ADD CONSTRAINT "rule_notification_store_id_fkey"
  FOREIGN KEY (notification_store_id)
  REFERENCES "notification_directory"."notification_store" (id);

ALTER TABLE "trigger"."exception_base"
  ADD CONSTRAINT "exception_base_entity_id_fkey"
  FOREIGN KEY (entity_id)
  REFERENCES "directory"."entity" (id);

ALTER TABLE "trigger"."rule_tag_link"
  ADD CONSTRAINT "rule_tag_link_rule_id_fkey"
  FOREIGN KEY (rule_id)
  REFERENCES "trigger"."rule" (id) ON DELETE CASCADE;

ALTER TABLE "trigger"."rule_tag_link"
  ADD CONSTRAINT "rule_tag_link_tag_id_fkey"
  FOREIGN KEY (tag_id)
  REFERENCES "directory"."tag" (id) ON DELETE CASCADE;
