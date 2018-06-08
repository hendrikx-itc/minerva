

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
GRANT USAGE ON SCHEMA "dimension" TO "minerva";
GRANT USAGE,CREATE ON SCHEMA "dimension" TO "minerva_writer";


CREATE SCHEMA IF NOT EXISTS "system";


CREATE SCHEMA IF NOT EXISTS "directory";
COMMENT ON SCHEMA "directory" IS 'Stores contextual information for the data. This includes the entities, entity_types, data_sources, etc. It is the entrypoint when looking for data.';
GRANT USAGE ON SCHEMA "directory" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "alias";


CREATE SCHEMA IF NOT EXISTS "alias_directory";


CREATE SCHEMA IF NOT EXISTS "relation";
COMMENT ON SCHEMA "relation" IS 'Stores the actual relations between entities in dynamically created tables.';
GRANT USAGE ON SCHEMA "relation" TO "minerva";
GRANT USAGE,CREATE ON SCHEMA "relation" TO "minerva_writer";


CREATE SCHEMA IF NOT EXISTS "relation_def";
COMMENT ON SCHEMA "relation_def" IS 'Stores definitions of relations in the form of views. These views are used to
populate the corresponding tables in the relation schema';
GRANT USAGE ON SCHEMA "relation_def" TO "minerva";
GRANT USAGE,CREATE ON SCHEMA "relation_def" TO "minerva_writer";


CREATE SCHEMA IF NOT EXISTS "relation_directory";


CREATE SCHEMA IF NOT EXISTS "trend";
COMMENT ON SCHEMA "trend" IS 'Stores information with fixed interval and format, like periodic measurements.';
GRANT USAGE ON SCHEMA "trend" TO "minerva";
GRANT USAGE,CREATE ON SCHEMA "trend" TO "minerva_writer";


CREATE SCHEMA IF NOT EXISTS "trend_partition";
COMMENT ON SCHEMA "trend_partition" IS 'Stores information with fixed interval and format, like periodic measurements.';


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

GRANT SELECT ON TABLE "dimension"."month" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."month" TO minerva_writer;



CREATE TABLE "dimension"."week"
(
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone,
  "end" timestamp with time zone,
  "year" smallint,
  "week_iso_8601" smallint,
  PRIMARY KEY (timestamp)
);

GRANT SELECT ON TABLE "dimension"."week" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."week" TO minerva_writer;



CREATE TABLE "dimension"."day"
(
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone,
  "end" timestamp with time zone,
  PRIMARY KEY (timestamp)
);

GRANT SELECT ON TABLE "dimension"."day" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."day" TO minerva_writer;



CREATE TABLE "dimension"."hour"
(
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone,
  "end" timestamp with time zone,
  PRIMARY KEY (timestamp)
);

GRANT SELECT ON TABLE "dimension"."hour" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."hour" TO minerva_writer;



CREATE TABLE "dimension"."quarter"
(
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone,
  "end" timestamp with time zone,
  PRIMARY KEY (timestamp)
);

GRANT SELECT ON TABLE "dimension"."quarter" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."quarter" TO minerva_writer;



CREATE TABLE "dimension"."5m"
(
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone,
  "end" timestamp with time zone,
  PRIMARY KEY (timestamp)
);

GRANT SELECT ON TABLE "dimension"."5m" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."5m" TO minerva_writer;



CREATE TABLE "dimension"."four_consec_qtr"
(
  "timestamp" timestamp with time zone NOT NULL,
  "start" timestamp with time zone,
  "end" timestamp with time zone,
  PRIMARY KEY (timestamp)
);

GRANT SELECT ON TABLE "dimension"."four_consec_qtr" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."four_consec_qtr" TO minerva_writer;



CREATE TABLE "dimension"."month_15m"
(
  "timestamp" timestamp with time zone,
  "timestamp_15m" timestamp with time zone NOT NULL,
  PRIMARY KEY (timestamp_15m)
);

CREATE INDEX month_15m_timestamp_idx ON "dimension"."month_15m" USING btree ("timestamp");

GRANT SELECT ON TABLE "dimension"."month_15m" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."month_15m" TO minerva_writer;



CREATE TABLE "dimension"."week_15m"
(
  "timestamp" timestamp with time zone,
  "timestamp_15m" timestamp with time zone NOT NULL,
  PRIMARY KEY (timestamp_15m)
);

CREATE INDEX week_15m_timestamp_idx ON "dimension"."week_15m" USING btree ("timestamp");

GRANT SELECT ON TABLE "dimension"."week_15m" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."week_15m" TO minerva_writer;



CREATE TABLE "dimension"."day_15m"
(
  "timestamp" timestamp with time zone,
  "timestamp_15m" timestamp with time zone NOT NULL,
  PRIMARY KEY (timestamp_15m)
);

GRANT SELECT ON TABLE "dimension"."day_15m" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "dimension"."day_15m" TO minerva_writer;



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

CREATE UNIQUE INDEX ix_system_job_source_name ON "system"."job_source" USING btree (name);

GRANT SELECT ON TABLE "system"."job_source" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "system"."job_source" TO minerva_writer;



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

GRANT SELECT ON TABLE "system"."job" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "system"."job" TO minerva_writer;



CREATE TABLE "system"."job_error_log"
(
  "job_id" integer NOT NULL,
  "message" varchar,
  PRIMARY KEY (job_id)
);

GRANT SELECT ON TABLE "system"."job_error_log" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "system"."job_error_log" TO minerva_writer;



CREATE TABLE "system"."job_queue"
(
  "job_id" integer NOT NULL,
  PRIMARY KEY (job_id)
);

GRANT SELECT ON TABLE "system"."job_queue" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "system"."job_queue" TO minerva_writer;



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

GRANT SELECT ON TABLE "system"."setting" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "system"."setting" TO minerva_writer;



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

CREATE UNIQUE INDEX ix_directory_data_source_name ON "directory"."data_source" USING btree (name);

GRANT SELECT ON TABLE "directory"."data_source" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."data_source" TO minerva_writer;



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

CREATE UNIQUE INDEX ix_directory_entity_type_name ON "directory"."entity_type" USING btree (lower((name)::text));

GRANT SELECT ON TABLE "directory"."entity_type" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."entity_type" TO minerva_writer;



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

CREATE INDEX ix_directory_entity_name ON "directory"."entity" USING btree (name);

CREATE INDEX ix_directory_entity_entity_type_id ON "directory"."entity" USING btree (entity_type_id);

GRANT SELECT ON TABLE "directory"."entity" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."entity" TO minerva_writer;



CREATE SEQUENCE directory.tag_group_id_seq
  START WITH 34
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

CREATE UNIQUE INDEX ix_directory_tag_group_name ON "directory"."tag_group" USING btree (lower((name)::text));

GRANT SELECT ON TABLE "directory"."tag_group" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."tag_group" TO minerva_writer;



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

CREATE UNIQUE INDEX ix_directory_tag_name ON "directory"."tag" USING btree (lower((name)::text));

CREATE INDEX tag_lower_id_idx ON "directory"."tag" USING btree (lower((name)::text), id);

GRANT SELECT ON TABLE "directory"."tag" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."tag" TO minerva_writer;



CREATE TABLE "directory"."entity_tag_link"
(
  "tag_id" integer NOT NULL,
  "entity_id" integer NOT NULL,
  PRIMARY KEY (entity_id, tag_id)
);

CREATE INDEX ix_directory_entity_tag_link_entity_id ON "directory"."entity_tag_link" USING btree (entity_id);

GRANT SELECT ON TABLE "directory"."entity_tag_link" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."entity_tag_link" TO minerva_writer;



CREATE TABLE "directory"."entity_tag_link_denorm"
(
  "entity_id" integer NOT NULL,
  "tags" text[] NOT NULL,
  "name" text NOT NULL,
  PRIMARY KEY (entity_id)
);

CREATE INDEX entity_tag_link_denorm_tags_idx ON "directory"."entity_tag_link_denorm" USING gin (tags);

CREATE INDEX entity_tag_link_denorm_name_idx ON "directory"."entity_tag_link_denorm" USING btree (name);

GRANT SELECT ON TABLE "directory"."entity_tag_link_denorm" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."entity_tag_link_denorm" TO minerva_writer;



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
  START WITH 34
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

CREATE UNIQUE INDEX alias_type_name_lower_idx ON "alias_directory"."alias_type" USING btree (name, lower((name)::text));



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
    RETURNS text
AS $$
BEGIN
    EXECUTE format(
        'INSERT INTO alias.%I(entity_id, %I) VALUES ($1, $2)',
        $2, $2
    ) USING $1, $3;

    RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "alias_directory"."define_alias_type"("name" name)
    RETURNS alias_directory.alias_type
AS $$
INSERT INTO alias_directory.alias_type(name) VALUES ($1) RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "alias_directory"."create_alias_type"("name" name)
    RETURNS alias_directory.alias_type
AS $$
SELECT alias_directory.initialize_alias_type(
        alias_directory.define_alias_type($1)
    );
$$ LANGUAGE sql VOLATILE;


CREATE TYPE "relation_directory"."type_cardinality_enum" AS ENUM (
  'one-to-one',
  'one-to-many',
  'many-to-one'
);



CREATE SEQUENCE relation_directory.type_id_seq
  START WITH 34
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

CREATE UNIQUE INDEX type_name_key ON "relation_directory"."type" USING btree (name);

GRANT SELECT ON TABLE "relation_directory"."type" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "relation_directory"."type" TO minerva_writer;



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

CREATE UNIQUE INDEX dn_dn_key ON "alias"."dn" USING btree (dn);



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


CREATE TABLE "relation"."parent"
(
  "source_id" integer NOT NULL,
  "target_id" integer NOT NULL,
  PRIMARY KEY (source_id, target_id)
)INHERITS ("relation"."base");

CREATE INDEX ix_parent_target_id ON "relation"."parent" USING btree (target_id);

GRANT SELECT ON TABLE "relation"."parent" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "relation"."parent" TO minerva_writer;



INSERT INTO "directory"."tag_group" (name, complementary, id) VALUES ('default', False, 1);


INSERT INTO "directory"."tag_group" (name, complementary, id) VALUES ('entity_type', True, 2);


INSERT INTO "relation_directory"."type" (name, cardinality, id) VALUES ('parent', null, 1);


INSERT INTO "alias_directory"."alias_type" (name, id) VALUES ('dn', 1);


ALTER TABLE "alias"."dn"
  ADD CONSTRAINT "dn_entity_id_fkey"
  FOREIGN KEY (entity_id)
  REFERENCES "directory"."entity" (id);

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

ALTER TABLE "system"."job"
  ADD CONSTRAINT "job_job_source_id_fkey"
  FOREIGN KEY (job_source_id)
  REFERENCES "system"."job_source" (id) ON DELETE CASCADE;

ALTER TABLE "system"."job_queue"
  ADD CONSTRAINT "job_queue_job_id_fkey"
  FOREIGN KEY (job_id)
  REFERENCES "system"."job" (id) ON DELETE CASCADE;
