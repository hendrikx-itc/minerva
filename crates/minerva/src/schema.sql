CREATE EXTENSION IF NOT EXISTS citus;



DO
$$
BEGIN
  IF NOT EXISTS(SELECT * FROM pg_roles WHERE rolname = 'postgres') THEN
    CREATE ROLE postgres
      SUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
  END IF;
END
$$;


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

GRANT postgres TO minerva_admin;


CREATE SCHEMA IF NOT EXISTS "public";


CREATE SCHEMA IF NOT EXISTS "system";


CREATE SCHEMA IF NOT EXISTS "directory";
COMMENT ON SCHEMA "directory" IS 'Stores contextual information for the data. This includes the entities, entity_types, data_sources, etc. It is the entrypoint when looking for data.';
GRANT USAGE ON SCHEMA "directory" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "directory" GRANT USAGE,SELECT ON sequences TO "minerva_writer";

SELECT run_command_on_workers($$ CREATE SCHEMA "directory"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "directory" GRANT USAGE,SELECT ON sequences TO "minerva_writer"; $$);


CREATE SCHEMA IF NOT EXISTS "entity";
GRANT USAGE,CREATE ON SCHEMA "entity" TO "minerva_writer";
GRANT USAGE ON SCHEMA "entity" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "entity" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "entity" GRANT SELECT ON tables TO "minerva";

ALTER DEFAULT PRIVILEGES IN SCHEMA "entity" GRANT USAGE,SELECT ON sequences TO "minerva_writer";

SELECT run_command_on_workers($$ CREATE SCHEMA "entity"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "entity" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "entity" GRANT SELECT ON tables TO "minerva"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "entity" GRANT USAGE,SELECT ON sequences TO "minerva_writer"; $$);


CREATE SCHEMA IF NOT EXISTS "alias";
GRANT USAGE,CREATE ON SCHEMA "alias" TO "minerva_writer";
GRANT USAGE ON SCHEMA "alias" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "alias" GRANT SELECT ON tables TO "minerva";

ALTER DEFAULT PRIVILEGES IN SCHEMA "alias" GRANT SELECT,UPDATE,DELETE ON tables TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "alias" GRANT USAGE,SELECT ON sequences TO "minerva_writer";

SELECT run_command_on_workers($$ CREATE SCHEMA "alias"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "alias" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "alias" GRANT SELECT ON tables TO "minerva"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "alias" GRANT USAGE,SELECT ON sequences TO "minerva_writer"; $$);


CREATE SCHEMA IF NOT EXISTS "alias_def";
GRANT USAGE,CREATE ON SCHEMA "alias_def" TO "minerva_writer";
GRANT USAGE ON SCHEMA "alias_def" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "alias_def" GRANT SELECT ON tables TO "minerva";

ALTER DEFAULT PRIVILEGES IN SCHEMA "alias_def" GRANT SELECT,UPDATE,DELETE ON tables TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "alias_def" GRANT USAGE,SELECT ON sequences TO "minerva_writer";

SELECT run_command_on_workers($$ CREATE SCHEMA "alias_def"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "alias_def" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "alias_def" GRANT SELECT ON tables TO "minerva"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "alias_def" GRANT USAGE,SELECT ON sequences TO "minerva_writer"; $$);


CREATE SCHEMA IF NOT EXISTS "alias_directory";
GRANT USAGE,CREATE ON SCHEMA "alias_directory" TO "minerva_writer";
GRANT USAGE ON SCHEMA "alias_directory" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "alias_directory" GRANT USAGE,SELECT ON sequences TO "minerva_writer";

SELECT run_command_on_workers($$ CREATE SCHEMA "alias_directory"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "alias_directory" GRANT USAGE,SELECT ON sequences TO "minerva_writer"; $$);


CREATE SCHEMA IF NOT EXISTS "relation";
COMMENT ON SCHEMA "relation" IS 'Stores the actual relations between entities in tables.
';
GRANT USAGE,CREATE ON SCHEMA "relation" TO "minerva_writer";
GRANT USAGE ON SCHEMA "relation" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "relation" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "relation" GRANT SELECT ON tables TO "minerva";

SELECT run_command_on_workers($$ CREATE SCHEMA "relation"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "relation" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "relation" GRANT SELECT ON tables TO "minerva"; $$);


CREATE SCHEMA IF NOT EXISTS "relation_def";
COMMENT ON SCHEMA "relation_def" IS 'Stores the views that define the contents of the relation tables.
';
GRANT USAGE,CREATE ON SCHEMA "relation_def" TO "minerva_writer";
GRANT USAGE ON SCHEMA "relation_def" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "relation_def" GRANT SELECT ON tables TO "minerva";

ALTER DEFAULT PRIVILEGES IN SCHEMA "relation_def" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "relation_def" GRANT USAGE,SELECT ON sequences TO "minerva_writer";

SELECT run_command_on_workers($$ CREATE SCHEMA "relation_def"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "relation_def" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "relation_def" GRANT SELECT ON tables TO "minerva"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "relation_def" GRANT USAGE,SELECT ON sequences TO "minerva_writer"; $$);


CREATE SCHEMA IF NOT EXISTS "relation_directory";
ALTER DEFAULT PRIVILEGES IN SCHEMA "relation_directory" GRANT USAGE,SELECT ON sequences TO "minerva_writer";

SELECT run_command_on_workers($$ CREATE SCHEMA "relation_directory"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "relation_directory" GRANT USAGE,SELECT ON sequences TO "minerva_writer"; $$);


CREATE SCHEMA IF NOT EXISTS "trend";
COMMENT ON SCHEMA "trend" IS 'Stores information with fixed interval and format, like periodic measurements.';
GRANT USAGE,CREATE ON SCHEMA "trend" TO "minerva_writer";
GRANT USAGE ON SCHEMA "trend" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "trend" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "trend" GRANT SELECT ON tables TO "minerva";

SELECT run_command_on_workers($$ CREATE SCHEMA "trend"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "trend" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "trend" GRANT SELECT ON tables TO "minerva"; $$);


CREATE SCHEMA IF NOT EXISTS "trend_partition";
COMMENT ON SCHEMA "trend_partition" IS 'Holds partitions of the trend store tables in the trend schema.';
GRANT USAGE,CREATE ON SCHEMA "trend_partition" TO "minerva_writer";
GRANT USAGE ON SCHEMA "trend_partition" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "trend_partition" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "trend_partition" GRANT SELECT ON tables TO "minerva";

SELECT run_command_on_workers($$ CREATE SCHEMA "trend_partition"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "trend_partition" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "trend_partition" GRANT SELECT ON tables TO "minerva"; $$);


CREATE SCHEMA IF NOT EXISTS "trend_directory";
GRANT USAGE ON SCHEMA "trend_directory" TO "minerva_writer";
GRANT USAGE ON SCHEMA "trend_directory" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "trend_directory" GRANT USAGE,SELECT ON sequences TO "minerva_writer";



CREATE SCHEMA IF NOT EXISTS "attribute";
GRANT USAGE,CREATE ON SCHEMA "attribute" TO "minerva_writer";
GRANT USAGE ON SCHEMA "attribute" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute" GRANT ALL ON tables TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute" GRANT SELECT ON tables TO "minerva";

SELECT run_command_on_workers($$ CREATE SCHEMA "attribute"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_base" GRANT ALL ON tables TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_base" GRANT SELECT ON tables TO "minerva"; $$);


CREATE SCHEMA IF NOT EXISTS "attribute_base";
GRANT USAGE,CREATE ON SCHEMA "attribute_base" TO "minerva_writer";
GRANT USAGE ON SCHEMA "attribute_base" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_base" GRANT ALL ON tables TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_base" GRANT SELECT ON tables TO "minerva";

SELECT run_command_on_workers($$ CREATE SCHEMA "attribute_base"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_base" GRANT ALL ON tables TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_base" GRANT SELECT ON tables TO "minerva"; $$);


CREATE SCHEMA IF NOT EXISTS "attribute_directory";
GRANT USAGE,CREATE ON SCHEMA "attribute_directory" TO "minerva_writer";
GRANT USAGE ON SCHEMA "attribute_directory" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_directory" GRANT USAGE,SELECT ON sequences TO "minerva_writer";

SELECT run_command_on_workers($$ CREATE SCHEMA "attribute_directory"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_directory" GRANT USAGE,SELECT ON sequences TO "minerva_writer"; $$);


CREATE SCHEMA IF NOT EXISTS "attribute_history";
GRANT USAGE,CREATE ON SCHEMA "attribute_history" TO "minerva_writer";
GRANT USAGE ON SCHEMA "attribute_history" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_history" GRANT ALL ON tables TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_history" GRANT SELECT ON tables TO "minerva";

ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_history" GRANT USAGE,SELECT ON sequences TO "minerva_writer";

SELECT run_command_on_workers($$ CREATE SCHEMA "attribute_history"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_history" GRANT ALL ON tables TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_history" GRANT SELECT ON tables TO "minerva"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_history" GRANT USAGE,SELECT ON sequences TO "minerva_writer"; $$);


CREATE SCHEMA IF NOT EXISTS "attribute_staging";
GRANT USAGE,CREATE ON SCHEMA "attribute_staging" TO "minerva_writer";
GRANT USAGE ON SCHEMA "attribute_staging" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_staging" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_staging" GRANT SELECT ON tables TO "minerva";

SELECT run_command_on_workers($$ CREATE SCHEMA "attribute_staging"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_staging" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "attribute_staging" GRANT SELECT ON tables TO "minerva"; $$);


CREATE SCHEMA IF NOT EXISTS "notification";
COMMENT ON SCHEMA "notification" IS 'Stores information of events that can occur at irregular intervals,
but still have a fixed, known format. This schema is dynamically populated.';
GRANT USAGE,CREATE ON SCHEMA "notification" TO "minerva_writer";
GRANT USAGE ON SCHEMA "notification" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "notification" GRANT ALL ON tables TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "notification" GRANT SELECT ON tables TO "minerva";

ALTER DEFAULT PRIVILEGES IN SCHEMA "notification" GRANT USAGE,SELECT ON sequences TO "minerva_writer";

SELECT run_command_on_workers($$ CREATE SCHEMA "notification"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "notification" GRANT ALL ON tables TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "notification" GRANT SELECT ON tables TO "minerva"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "notification" GRANT USAGE,SELECT ON sequences TO "minerva_writer"; $$);


CREATE SCHEMA IF NOT EXISTS "notification_directory";
COMMENT ON SCHEMA "notification_directory" IS 'Stores meta-data about notification data in the notification schema.';
GRANT USAGE,CREATE ON SCHEMA "notification_directory" TO "minerva_writer";
GRANT USAGE ON SCHEMA "notification_directory" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "notification_directory" GRANT USAGE,SELECT ON sequences TO "minerva_writer";

SELECT run_command_on_workers($$ CREATE SCHEMA "notification_directory"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "notification_directory" GRANT USAGE,SELECT ON sequences TO "minerva_writer"; $$);


CREATE SCHEMA IF NOT EXISTS "metric";
GRANT USAGE ON SCHEMA "metric" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "virtual_entity";
GRANT USAGE ON SCHEMA "virtual_entity" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "olap";
GRANT USAGE,CREATE ON SCHEMA "olap" TO "minerva_writer";
GRANT USAGE ON SCHEMA "olap" TO "minerva";


CREATE SCHEMA IF NOT EXISTS "trigger";
GRANT USAGE,CREATE ON SCHEMA "trigger" TO "minerva_writer";
GRANT USAGE ON SCHEMA "trigger" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "trigger" GRANT USAGE,SELECT ON sequences TO "minerva_writer";

SELECT run_command_on_workers($$ CREATE SCHEMA "trigger"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "trigger" GRANT USAGE,SELECT ON sequences TO "minerva_writer"; $$);


CREATE SCHEMA IF NOT EXISTS "trigger_rule";
GRANT USAGE,CREATE ON SCHEMA "trigger_rule" TO "minerva_writer";
GRANT USAGE ON SCHEMA "trigger_rule" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "trigger_rule" GRANT SELECT ON tables TO "minerva";

ALTER DEFAULT PRIVILEGES IN SCHEMA "trigger_rule" GRANT ALL ON tables TO "minerva_admin";

ALTER DEFAULT PRIVILEGES IN SCHEMA "trigger_rule" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "trigger_rule" GRANT USAGE,SELECT ON sequences TO "minerva_writer";

ALTER DEFAULT PRIVILEGES IN SCHEMA "trigger_rule" GRANT EXECUTE ON functions TO "minerva";

SELECT run_command_on_workers($$ CREATE SCHEMA "trigger_rule"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "trigger_rule" GRANT SELECT ON tables TO "minerva"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "trigger_rule" GRANT ALL ON tables TO "minerva_admin"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "trigger_rule" GRANT SELECT,INSERT,UPDATE,DELETE ON tables TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "trigger_rule" GRANT USAGE,SELECT ON sequences TO "minerva_writer"; $$);
SELECT run_command_on_workers($$ ALTER DEFAULT PRIVILEGES IN SCHEMA "trigger_rule" GRANT EXECUTE ON functions TO "minerva"; $$);


CREATE SCHEMA IF NOT EXISTS "logging";
GRANT USAGE ON SCHEMA "logging" TO "minerva";
ALTER DEFAULT PRIVILEGES IN SCHEMA "logging" GRANT USAGE,SELECT ON sequences TO "minerva_writer";



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


CREATE FUNCTION "public"."safe_division"("numerator" anyelement, "denominator" anyelement, "division_by_zero_indicator" anyelement)
    RETURNS anyelement
AS $$
SELECT CASE
    WHEN $2 = 0 THEN
        $3
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


CREATE FUNCTION "public"."array_to_text"(anyarray)
    RETURNS text
AS $$
SELECT array_to_string($1, ',')
$$ LANGUAGE sql IMMUTABLE STRICT;
SELECT create_distributed_function('array_to_text(anyarray)');


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
SELECT create_distributed_function('action(text)');


CREATE FUNCTION "public"."action_count"("sql" text)
    RETURNS integer
AS $$
DECLARE
    row_count integer;
BEGIN
    EXECUTE sql;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;
SELECT create_distributed_function('action_count(text)');


CREATE FUNCTION "public"."action"(anyelement, "sql" text)
    RETURNS anyelement
AS $$
BEGIN
    EXECUTE sql;

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;
SELECT create_distributed_function('action(anyelement,text)');


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
SELECT create_distributed_function('action(anyelement,text[])');


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


CREATE FUNCTION "public"."switch_off_citus"()
    RETURNS void
AS $function$
CREATE OR REPLACE FUNCTION create_distributed_table(text, text) RETURNS VOID AS $$ SELECT 42; $$ LANGUAGE sql STABLE;
CREATE OR REPLACE FUNCTION create_reference_table(text) RETURNS VOID AS $$ SELECT 42; $$ LANGUAGE sql STABLE;
CREATE OR REPLACE FUNCTION create_distributed_function(text) RETURNS VOID AS $$ SELECT 42; $$ LANGUAGE sql STABLE;
$function$ LANGUAGE sql VOLATILE;


CREATE AGGREGATE first (anyelement) (
    sfunc = fst,
    stype = anyelement
);

SELECT create_distributed_function('first(anyelement)');


CREATE AGGREGATE last (anyelement) (
    sfunc = snd,
    stype = anyelement
);

SELECT create_distributed_function('last(anyelement)');


CREATE TABLE "system"."setting"
(
  "id" serial NOT NULL,
  "name" text NOT NULL,
  "value" text,
  PRIMARY KEY (id)
);

GRANT SELECT ON TABLE "system"."setting" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "system"."setting" TO minerva_writer;



CREATE TYPE "system"."version_tuple" AS (
  "major" smallint,
  "minor" smallint,
  "patch" smallint
);



CREATE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (6,0,0)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


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


CREATE TABLE "directory"."data_source"
(
  "id" serial NOT NULL,
  "name" varchar NOT NULL,
  "description" varchar NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "directory"."data_source" IS 'Describes data_sources. A data_source is used to indicate where data came
from. Datasources are also used to prevent collisions between sets of
data from different sources, where names can be the same, but the meaning
of the data differs.';

CREATE UNIQUE INDEX "ix_directory_data_source_name" ON "directory"."data_source" USING btree (name);

GRANT SELECT ON TABLE "directory"."data_source" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."data_source" TO minerva_writer;



CREATE TABLE "directory"."entity_type"
(
  "id" serial NOT NULL,
  "name" varchar NOT NULL,
  "description" varchar NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "directory"."entity_type" IS 'Stores the entity types that exist in the entity table. Entity types are
also used to give context to data that is stored for entities.';

CREATE UNIQUE INDEX "ix_directory_entity_type_name" ON "directory"."entity_type" USING btree (lower((name)::text));

GRANT SELECT ON TABLE "directory"."entity_type" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."entity_type" TO minerva_writer;



CREATE TABLE "directory"."tag_group"
(
  "id" serial NOT NULL,
  "name" varchar NOT NULL,
  "complementary" bool NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "directory"."tag_group" IS 'Stores groups that can be related to by tags.';

CREATE UNIQUE INDEX "ix_directory_tag_group_name" ON "directory"."tag_group" USING btree (lower((name)::text));

GRANT SELECT ON TABLE "directory"."tag_group" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."tag_group" TO minerva_writer;



CREATE TABLE "directory"."tag"
(
  "id" serial NOT NULL,
  "name" varchar NOT NULL,
  "tag_group_id" integer NOT NULL,
  "description" varchar,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "directory"."tag" IS 'Stores all tags. A tag is a simple label that can be attached to a number of object types in the database, such as entities and trends.';

CREATE UNIQUE INDEX "ix_directory_tag_name" ON "directory"."tag" USING btree (lower((name)::text));

CREATE INDEX "tag_lower_id_idx" ON "directory"."tag" USING btree (lower((name)::text), id);

GRANT SELECT ON TABLE "directory"."tag" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "directory"."tag" TO minerva_writer;



CREATE FUNCTION "directory"."get_entity_type_name"(integer)
    RETURNS text
AS $$
SELECT name FROM directory.entity_type WHERE id = $1;
$$ LANGUAGE sql STABLE STRICT;


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
VALUES ($1, 'default');
SELECT * FROM directory.data_source WHERE name = $1;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "entity"."create_entity_table_sql"(directory.entity_type)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
      'CREATE TABLE IF NOT EXISTS entity.%I('
      'id serial,'
      'name text UNIQUE,'
      'created timestamp with time zone default now()'
      ');',
      $1.name
    ),
    format(
       'SELECT create_reference_table(''entity.%I'');',
       $1.name
    )
];
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "entity"."create_entity_table"(directory.entity_type)
    RETURNS directory.entity_type
AS $$
SELECT public.action($1, entity.create_entity_table_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "entity"."to_entity_function_name"(directory.entity_type)
    RETURNS name
AS $$
SELECT format('to_%s', $1.name)::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "entity"."get_entity_function_name"(directory.entity_type)
    RETURNS name
AS $$
SELECT format('get_%s', $1.name)::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "entity"."create_entity_function_name"(directory.entity_type)
    RETURNS name
AS $$
SELECT format('create_%s', $1.name)::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "entity"."create_create_entity_function_sql"(directory.entity_type)
    RETURNS text[]
AS $function$
SELECT ARRAY[
    format(
      'CREATE FUNCTION entity.%I(text) RETURNS entity.%I
      AS $$
        INSERT INTO entity.%I(name) VALUES ($1) ON CONFLICT DO NOTHING;
        SELECT e FROM entity.%I e WHERE name = $1;
      $$ LANGUAGE sql',
      entity.create_entity_function_name($1),
      $1.name,
      $1.name,
      $1.name,
      $1.name
    )
];
$function$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "entity"."create_create_entity_function"(directory.entity_type)
    RETURNS directory.entity_type
AS $$
SELECT public.action($1, entity.create_create_entity_function_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "entity"."create_get_entity_function_sql"(directory.entity_type)
    RETURNS text[]
AS $function$
SELECT ARRAY[
    format(
      'CREATE FUNCTION entity.%I(text) RETURNS entity.%I
      AS $$
        SELECT * FROM entity.%I WHERE name = $1;
      $$ LANGUAGE sql',
      entity.get_entity_function_name($1),
      $1.name,
      $1.name
    )
];
$function$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "entity"."create_get_entity_function"(directory.entity_type)
    RETURNS directory.entity_type
AS $$
SELECT public.action($1, entity.create_get_entity_function_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "entity"."create_to_entity_function_sql"(directory.entity_type)
    RETURNS text[]
AS $function$
SELECT ARRAY[
    format(
      'CREATE FUNCTION entity.%I(text) RETURNS entity.%I
      AS $$
        SELECT coalesce(entity.%I($1), entity.%I($1));
      $$ LANGUAGE sql',
      entity.to_entity_function_name($1),
      $1.name,
      entity.get_entity_function_name($1),
      entity.create_entity_function_name($1)
    )
];
$function$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "entity"."create_to_entity_function"(directory.entity_type)
    RETURNS directory.entity_type
AS $$
SELECT public.action($1, entity.create_to_entity_function_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "directory"."define_entity_type"(text)
    RETURNS directory.entity_type
AS $$
INSERT INTO directory.entity_type(name, description)
VALUES ($1, '')
ON CONFLICT DO NOTHING;
SELECT * FROM directory.entity_type WHERE name = $1;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."init_entity_type"(directory.entity_type)
    RETURNS directory.entity_type
AS $$
SELECT entity.create_entity_table($1);
SELECT entity.create_get_entity_function($1);
SELECT entity.create_create_entity_function($1);
SELECT entity.create_to_entity_function($1);
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."create_entity_type"(text)
    RETURNS directory.entity_type
AS $$
SELECT directory.init_entity_type(directory.define_entity_type($1));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."name_to_entity_type"(text)
    RETURNS directory.entity_type
AS $$
SELECT COALESCE(directory.get_entity_type($1), directory.create_entity_type($1));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "directory"."name_to_data_source"(text)
    RETURNS directory.data_source
AS $$
SELECT COALESCE(directory.get_data_source($1), directory.create_data_source($1));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE TABLE "alias_directory"."alias_type"
(
  "id" serial NOT NULL,
  "name" varchar NOT NULL,
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
        '  entity_id serial PRIMARY KEY,'
        '  alias text NOT NULL,'
        ');',
        alias_directory.alias_schema(),
        $1.name, $1.name
    ),
    format(
        'CREATE INDEX ON %I.%I USING btree(alias);',
        alias_directory.alias_schema(),
        $1.name
    )
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "alias_directory"."initialize_alias_type"(alias_directory.alias_type)
    RETURNS alias_directory.alias_type
AS $$
SELECT public.action($1, alias_directory.initialize_alias_type_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "alias_directory"."update_alias_sql"(alias_directory.alias_type)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'DELETE FROM %I.%I',
        alias_directory.alias_schema(),
        $1.name
    ),
    format(
        'INSERT INTO %I.%I(entity_id, alias) SELECT entity_id, alias FROM alias_def.%I'
        ');',
        alias_directory.alias_schema(),
        $1.name, $1.name
    )
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "alias_directory"."update_alias"(alias_directory.alias_type)
    RETURNS alias_directory.alias_type
AS $$
SELECT public.action($1, alias_directory.update_alias_sql($1));
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
        'SELECT alias FROM alias.%I WHERE entity_id = %s',
        $2, $1
    ) INTO result;
    RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "alias_directory"."define_alias_type"("name" name)
    RETURNS alias_directory.alias_type
AS $$
INSERT INTO alias_directory.alias_type(name) VALUES ($1) RETURNING *;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "alias_directory"."define_alias_type"("name" name) IS 'Define a new alias type, but do not create a table for it.';


CREATE FUNCTION "alias_directory"."get_alias_type"("name" name)
    RETURNS alias_directory.alias_type
AS $$
SELECT alias_type FROM alias_directory.alias_type WHERE name = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "alias_directory"."create_alias_type"("name" name)
    RETURNS alias_directory.alias_type
AS $$
SELECT alias_directory.initialize_alias_type(
    alias_directory.define_alias_type($1)
);
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "alias_directory"."create_alias_type"("name" name) IS 'Define a new alias type and created the table for storing the aliases.';


CREATE FUNCTION "alias_directory"."get_or_create_alias_type"("name" name)
    RETURNS alias_directory.alias_type
AS $$
SELECT COALESCE(
  alias_directory.get_alias_type($1),
  alias_directory.create_alias_type($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE TYPE "relation_directory"."type_cardinality_enum" AS ENUM (
  'one-to-one',
  'one-to-many',
  'many-to-one'
);



CREATE TABLE "relation_directory"."type"
(
  "id" serial,
  "name" name NOT NULL,
  "cardinality" relation_directory.type_cardinality_enum,
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "type_name_key" ON "relation_directory"."type" USING btree (name);

GRANT SELECT ON TABLE "relation_directory"."type" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "relation_directory"."type" TO minerva_writer;



CREATE FUNCTION "relation_directory"."table_schema"()
    RETURNS name
AS $$
SELECT 'relation'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "relation_directory"."get_type"(name)
    RETURNS relation_directory.type
AS $$
SELECT type FROM relation_directory.type WHERE name = $1;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "relation_directory"."register_type"(name)
    RETURNS relation_directory.type
AS $$
INSERT INTO relation_directory.type (name) VALUES ($1) RETURNING type;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "relation_directory"."name_to_type"(name)
    RETURNS relation_directory.type
AS $$
SELECT COALESCE(
  relation_directory.get_type($1),
  relation_directory.register_type($1)
);
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "relation_directory"."remove"(name)
    RETURNS text
AS $$
DECLARE
  result text;
BEGIN
  SELECT name FROM relation_directory.type WHERE name = $1 INTO result;
  PERFORM public.action(format('DROP TABLE IF EXISTS relation.%I', $1));
  PERFORM public.action(format('DROP FUNCTION IF EXISTS relation_directory.%I', format('materialize_%s', $1)));
  DELETE FROM relation_directory.type WHERE name = $1;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TABLE "logging"."job"
(
  "id" bigserial,
  "action" jsonb NOT NULL,
  "started" timestamp with time zone NOT NULL,
  "finished" timestamp with time zone,
  PRIMARY KEY (id)
);

GRANT SELECT ON TABLE "logging"."job" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "logging"."job" TO minerva_writer;



CREATE FUNCTION "logging"."start_job"("action" jsonb)
    RETURNS bigint
AS $$
INSERT INTO logging.job(action, started) VALUES ($1, clock_timestamp())
RETURNING job.id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "logging"."end_job"("job_id" bigint)
    RETURNS void
AS $$
UPDATE logging.job SET finished=clock_timestamp() WHERE id=$1;
$$ LANGUAGE sql VOLATILE;


CREATE TYPE "trend_directory"."fingerprint" AS (
  "modified" timestamp with time zone,
  "body" jsonb
);



CREATE TYPE "trend_directory"."trend_descr" AS (
  "name" name,
  "data_type" text,
  "description" text,
  "time_aggregation" text,
  "entity_aggregation" text,
  "extra_data" jsonb
);



CREATE TYPE "trend_directory"."generated_trend_descr" AS (
  "name" name,
  "data_type" text,
  "description" text,
  "expression" text,
  "extra_data" jsonb
);



CREATE TYPE "trend_directory"."trend_view_part_descr" AS (
  "name" name,
  "query" text
);



CREATE TYPE "trend_directory"."trend_store_part_descr" AS (
  "name" name,
  "trends" trend_directory.trend_descr[],
  "generated_trends" trend_directory.generated_trend_descr[]
);



CREATE TABLE "trend_directory"."trend_store"
(
  "id" serial NOT NULL,
  "entity_type_id" integer,
  "data_source_id" integer,
  "granularity" interval NOT NULL,
  "partition_size" interval NOT NULL,
  "retention_period" interval NOT NULL DEFAULT '1 mon'::interval,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "trend_directory"."trend_store" IS 'Table based trend stores describing the common properties of all its
partitions like entity type, data granularity, etc.';

CREATE UNIQUE INDEX "trend_store_unique_constraint" ON "trend_directory"."trend_store" USING btree (entity_type_id, data_source_id, granularity);

GRANT SELECT ON TABLE "trend_directory"."trend_store" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."trend_store" TO minerva_writer;



CREATE TABLE "trend_directory"."trend_store_part"
(
  "id" serial NOT NULL,
  "name" name NOT NULL,
  "trend_store_id" integer NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "trend_directory"."trend_store_part" IS 'The parts of a horizontally partitioned table trend store. Each table trend store has at least 1 part.';

GRANT SELECT ON TABLE "trend_directory"."trend_store_part" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."trend_store_part" TO minerva_writer;



CREATE TABLE "trend_directory"."partition"
(
  "id" serial NOT NULL,
  "trend_store_part_id" integer NOT NULL,
  "name" name NOT NULL,
  "index" integer NOT NULL,
  "from" timestamp with time zone NOT NULL,
  "to" timestamp with time zone NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "trend_directory"."partition" IS 'The parts of a vertically partitioned trend store part.';

GRANT SELECT ON TABLE "trend_directory"."partition" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."partition" TO minerva_writer;



CREATE TABLE "trend_directory"."trend_view"
(
  "id" serial NOT NULL,
  "entity_type_id" integer,
  "data_source_id" integer,
  "granularity" interval NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "trend_directory"."trend_view" IS 'View based trend stores describing the properties like entity type, data granularity, etc.';

CREATE UNIQUE INDEX "trend_view_unique_constraint" ON "trend_directory"."trend_view" USING btree (entity_type_id, data_source_id, granularity);



CREATE TABLE "trend_directory"."trend_view_part"
(
  "id" serial NOT NULL,
  "name" name NOT NULL,
  "trend_view_id" integer NOT NULL,
  PRIMARY KEY (id)
);



CREATE TABLE "trend_directory"."view_trend"
(
  "id" integer NOT NULL GENERATED BY DEFAULT AS IDENTITY,
  "trend_view_part_id" integer NOT NULL,
  "name" name NOT NULL,
  "data_type" text NOT NULL,
  "extra_data" jsonb NOT NULL DEFAULT '{}',
  "description" text NOT NULL,
  "time_aggregation" text NOT NULL,
  "entity_aggregation" text NOT NULL,
  PRIMARY KEY (id)
);

GRANT SELECT ON TABLE "trend_directory"."view_trend" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."view_trend" TO minerva_writer;



CREATE TABLE "trend_directory"."table_trend"
(
  "id" serial NOT NULL,
  "trend_store_part_id" integer NOT NULL,
  "name" name NOT NULL,
  "data_type" text NOT NULL,
  "extra_data" jsonb NOT NULL DEFAULT '{}',
  "description" text NOT NULL,
  "time_aggregation" text NOT NULL,
  "entity_aggregation" text NOT NULL,
  PRIMARY KEY (id)
);

GRANT SELECT ON TABLE "trend_directory"."table_trend" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."table_trend" TO minerva_writer;



CREATE TABLE "trend_directory"."generated_table_trend"
(
  "id" serial NOT NULL,
  "trend_store_part_id" integer NOT NULL,
  "name" name NOT NULL,
  "data_type" text NOT NULL,
  "expression" text NOT NULL,
  "extra_data" jsonb NOT NULL DEFAULT '{}',
  "description" text NOT NULL,
  PRIMARY KEY (id)
);

GRANT SELECT ON TABLE "trend_directory"."generated_table_trend" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."generated_table_trend" TO minerva_writer;



CREATE TABLE "trend_directory"."table_trend_tag_link"
(
  "table_trend_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY (table_trend_id, tag_id)
);



CREATE TABLE "trend_directory"."modified_log"
(
  "id" bigserial NOT NULL,
  "trend_store_part_id" integer NOT NULL,
  "timestamp" timestamp with time zone NOT NULL,
  "modified" timestamp with time zone NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "trend_directory"."modified_log" IS 'The ``modified_log`` table stores records of when what ``trend_store_part`` is modified and for what timestamp. This table is typically populated by data loading tools that call the ``trend_directory.mark_modified`` function. It is not populated automatically when inserting into the trend_store_part tables. The main purpose is to decouple the logging of data changes from actions triggered by those changes. There are no triggers on this table, and any actions should be triggered by changes on the ``trend_directory.modified`` table, which is updated by a separate processed based on the contents of this table.
';

COMMENT ON COLUMN "trend_directory"."modified_log"."id" IS 'Unique identifier for the log entry';

COMMENT ON COLUMN "trend_directory"."modified_log"."trend_store_part_id" IS 'Reference to the trend_store_part';

COMMENT ON COLUMN "trend_directory"."modified_log"."timestamp" IS 'Timestamp of the data in the trend_store_part';

COMMENT ON COLUMN "trend_directory"."modified_log"."modified" IS 'Timestamp of the moment of modification';

GRANT SELECT ON TABLE "trend_directory"."modified_log" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."modified_log" TO minerva_writer;



CREATE TABLE "trend_directory"."modified"
(
  "trend_store_part_id" integer NOT NULL,
  "timestamp" timestamp with time zone NOT NULL,
  "first" timestamp with time zone NOT NULL,
  "last" timestamp with time zone NOT NULL,
  PRIMARY KEY (trend_store_part_id, timestamp)
);

COMMENT ON TABLE "trend_directory"."modified" IS 'Stores information on when trend store parts have changed and for what timestamp. The information in this table is updated when the data has changed and any actions like materialization-state-updating can be triggered (using insert, update or delete triggers) from this table, because it is decoupled from the data loading processes.
';

COMMENT ON COLUMN "trend_directory"."modified"."first" IS 'Time of the first modification';

COMMENT ON COLUMN "trend_directory"."modified"."last" IS 'Time of the last modification';

GRANT SELECT ON TABLE "trend_directory"."modified" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."modified" TO minerva_writer;



CREATE TABLE "trend_directory"."trend_store_part_stats"
(
  "trend_store_part_id" integer NOT NULL,
  "timestamp" timestamp with time zone NOT NULL,
  "modified" timestamp with time zone NOT NULL,
  "count" integer NOT NULL,
  PRIMARY KEY (trend_store_part_id, timestamp)
);

COMMENT ON COLUMN "trend_directory"."trend_store_part_stats"."modified" IS 'Time of the last modification';

GRANT SELECT ON TABLE "trend_directory"."trend_store_part_stats" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."trend_store_part_stats" TO minerva_writer;



CREATE TABLE "trend_directory"."materialization"
(
  "id" serial NOT NULL,
  "dst_trend_store_part_id" integer NOT NULL,
  "processing_delay" interval NOT NULL,
  "stability_delay" interval NOT NULL,
  "reprocessing_period" interval NOT NULL,
  "enabled" bool NOT NULL DEFAULT false,
  "description" jsonb NOT NULL DEFAULT '{}',
  PRIMARY KEY (id)
);

COMMENT ON TABLE "trend_directory"."materialization" IS 'A ``materialization`` is a materialization that uses the data from
the view registered in the ``src_view`` column to populate the target trend
store.';

COMMENT ON COLUMN "trend_directory"."materialization"."id" IS 'The unique identifier of this materialization';

COMMENT ON COLUMN "trend_directory"."materialization"."dst_trend_store_part_id" IS 'The ID of the destination trend_store_part';

COMMENT ON COLUMN "trend_directory"."materialization"."processing_delay" IS 'The time after the destination timestamp before this materialization can be executed
';

COMMENT ON COLUMN "trend_directory"."materialization"."stability_delay" IS 'The time to wait after the most recent modified timestamp before the source data is considered ''stable''
';

COMMENT ON COLUMN "trend_directory"."materialization"."reprocessing_period" IS 'The maximum time after the destination timestamp that the materialization is allowed to be executed
';

COMMENT ON COLUMN "trend_directory"."materialization"."enabled" IS 'Indicates if jobs should be created for this materialization (manual execution is always possible)
';

COMMENT ON COLUMN "trend_directory"."materialization"."description" IS 'Gives a description of the function used for the materialization in json format
';

CREATE UNIQUE INDEX "ix_materialization_uniqueness" ON "trend_directory"."materialization" USING btree (dst_trend_store_part_id);

GRANT SELECT ON TABLE "trend_directory"."materialization" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."materialization" TO minerva_writer;



CREATE FUNCTION "trend_directory"."cleanup_for_materialization"(trend_directory.materialization)
    RETURNS void
AS $$
BEGIN
  EXECUTE format(
    'DROP FUNCTION trend.%I(timestamp with time zone)',
    trend_directory.fingerprint_function_name($1)
  );
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."cleanup_for_materialization"("materialization_name" text)
    RETURNS void
AS $$
SELECT trend_directory.cleanup_for_materialization(m)
  FROM trend_directory.materialization m
  WHERE m::text = $1;
$$ LANGUAGE sql VOLATILE;


CREATE TABLE "trend_directory"."materialization_metrics"
(
  "materialization_id" integer NOT NULL,
  "execution_count" integer NOT NULL DEFAULT 0,
  "total_duration" interval NOT NULL DEFAULT '0s',
  PRIMARY KEY (materialization_id)
);

COMMENT ON TABLE "trend_directory"."materialization_metrics" IS 'Metrics on individual materializations.';

COMMENT ON COLUMN "trend_directory"."materialization_metrics"."materialization_id" IS 'The ID of the materialization';

GRANT SELECT ON TABLE "trend_directory"."materialization_metrics" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."materialization_metrics" TO minerva_writer;



CREATE FUNCTION "trend_directory"."create_metrics_for_materialization"()
    RETURNS trigger
AS $$
BEGIN
    INSERT INTO trend_directory.materialization_metrics(materialization_id)
    VALUES (NEW.id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TRIGGER create_metrics_on_new_materialization
  AFTER INSERT ON "trend_directory"."materialization"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."create_metrics_for_materialization"();


CREATE FUNCTION "trend_directory"."to_char"(trend_directory.materialization)
    RETURNS text
AS $$
SELECT trend_store_part.name::text
FROM trend_directory.trend_store_part
WHERE trend_store_part.id = $1.dst_trend_store_part_id
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."materialization_to_char"("materialization_id" integer)
    RETURNS text
AS $$
SELECT trend_store_part.name::text
  FROM trend_directory.trend_store_part
  JOIN trend_directory.materialization
    ON trend_store_part.id = materialization.dst_trend_store_part_id
  WHERE materialization.id = $1;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."source_fingerprint_sql"("materialization_id" integer)
    RETURNS text
AS $$
SELECT format('SELECT * FROM trend.%I($1)', trend_directory.materialization_to_char($1) || '_fingerprint');
$$ LANGUAGE sql STABLE;

COMMENT ON FUNCTION "trend_directory"."source_fingerprint_sql"("materialization_id" integer) IS 'Returns the query to generate fingerprints for the specified view materialization.';


CREATE FUNCTION "trend_directory"."source_fingerprint"("materialization_id" integer, timestamp with time zone)
    RETURNS trend_directory.fingerprint
AS $$
DECLARE
    result trend_directory.fingerprint;
BEGIN
    EXECUTE trend_directory.source_fingerprint_sql($1) INTO result USING $2;

    RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION "trend_directory"."source_fingerprint"("materialization_id" integer, timestamp with time zone) IS 'Returns the fingerprint of the combined states of all sources required to calculate the data for the target timestamp.
';


CREATE TABLE "trend_directory"."view_materialization"
(
  "id" serial NOT NULL,
  "materialization_id" integer NOT NULL,
  "src_view" text NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "trend_directory"."view_materialization" IS 'A ``view_materialization`` is a materialization that uses the data
from the view registered in the ``src_view`` column to populate
the target ``trend_store_part``.';

COMMENT ON COLUMN "trend_directory"."view_materialization"."id" IS 'The unique identifier of this view materialization';

CREATE UNIQUE INDEX "ix_view_materialization_uniqueness" ON "trend_directory"."view_materialization" USING btree (materialization_id);

GRANT SELECT ON TABLE "trend_directory"."view_materialization" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."view_materialization" TO minerva_writer;



CREATE FUNCTION "trend_directory"."cleanup_for_view_materialization"()
    RETURNS trigger
AS $$
BEGIN
    EXECUTE format('DROP VIEW %s', OLD.src_view);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TRIGGER cleanup_on_view_materialization_delete
  BEFORE DELETE ON "trend_directory"."view_materialization"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."cleanup_for_view_materialization"();


CREATE FUNCTION "trend_directory"."define_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "description" jsonb)
    RETURNS trend_directory.materialization
AS $$
INSERT INTO trend_directory.materialization(dst_trend_store_part_id, processing_delay, stability_delay, reprocessing_period, description)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT DO NOTHING
RETURNING *;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."define_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "description" jsonb) IS 'Define a materialization';


CREATE FUNCTION "trend_directory"."undefine_materialization"("name" name)
    RETURNS void
AS $$
SELECT trend_directory."cleanup_for_materialization"($1);
DELETE FROM trend_directory.materialization
  WHERE materialization::text = $1;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."undefine_materialization"("name" name) IS 'Undefine and remove a materialization';


CREATE FUNCTION "trend_directory"."define_view_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_view" regclass, "description" jsonb)
    RETURNS trend_directory.view_materialization
AS $$
INSERT INTO trend_directory.view_materialization(materialization_id, src_view)
VALUES((trend_directory.define_materialization($1, $2, $3, $4, $6)).id, $5) RETURNING *;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."define_view_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_view" regclass, "description" jsonb) IS 'Define a materialization that uses a view as source';


CREATE FUNCTION "trend_directory"."define_view_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_view" regclass)
    RETURNS trend_directory.view_materialization
AS $$
SELECT trend_directory.define_view_materialization($1, $2, $3, $4, $5, '{}'::jsonb);
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."define_view_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_view" regclass) IS 'Define a materialization that uses a view as source';


CREATE TABLE "trend_directory"."function_materialization"
(
  "id" serial NOT NULL,
  "materialization_id" integer NOT NULL,
  "src_function" text NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "trend_directory"."function_materialization" IS 'A ``function_materialization`` is a materialization that uses the data
from the function registered in the ``src_function`` column to populate
the target ``trend_store_part``.

The function must have the form of::
  
  (timestamp with time zone) -> TABLE(
    entity_id integer,
    timestamp timestamp with time zone,
    ...
  )';

COMMENT ON COLUMN "trend_directory"."function_materialization"."id" IS 'The unique identifier of this function materialization';

CREATE UNIQUE INDEX "ix_function_materialization_uniqueness" ON "trend_directory"."function_materialization" USING btree (materialization_id);

GRANT SELECT ON TABLE "trend_directory"."function_materialization" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."function_materialization" TO minerva_writer;



CREATE FUNCTION "trend_directory"."define_function_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_function" regproc, "description" jsonb)
    RETURNS trend_directory.function_materialization
AS $$
INSERT INTO trend_directory.function_materialization(materialization_id, src_function)
VALUES((trend_directory.define_materialization($1, $2, $3, $4, $6)).id, $5::text)
ON CONFLICT DO NOTHING
RETURNING *;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."define_function_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_function" regproc, "description" jsonb) IS 'Define a materialization that uses a function as source';


CREATE FUNCTION "trend_directory"."define_function_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_function" regproc)
    RETURNS trend_directory.function_materialization
AS $$
SELECT trend_directory.define_function_materialization($1, $2, $3, $4, $5, '{}'::jsonb)
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."define_function_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_function" regproc) IS 'Define a materialization that uses a function as source';


CREATE FUNCTION "trend_directory"."cleanup_for_function_materialization"()
    RETURNS trigger
AS $$
BEGIN
    EXECUTE format('DROP FUNCTION %s', OLD.src_function);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TRIGGER cleanup_on_function_materialization_delete
  BEFORE DELETE ON "trend_directory"."function_materialization"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."cleanup_for_function_materialization"();


CREATE TABLE "trend_directory"."materialization_state"
(
  "materialization_id" integer NOT NULL,
  "timestamp" timestamp with time zone NOT NULL,
  "source_fingerprint" jsonb,
  "processed_fingerprint" jsonb,
  "max_modified" timestamp with time zone,
  "job_id" bigint,
  PRIMARY KEY (materialization_id, timestamp)
);

COMMENT ON TABLE "trend_directory"."materialization_state" IS 'Stores the relation between the state of the sources used for the materialization and the state of the materialized data, so that from this table, it can be decided if a new materialization should be done.
';

COMMENT ON COLUMN "trend_directory"."materialization_state"."materialization_id" IS 'The ID of the materialization type';

COMMENT ON COLUMN "trend_directory"."materialization_state"."timestamp" IS 'The timestamp of the materialized (materialization result) data';

COMMENT ON COLUMN "trend_directory"."materialization_state"."source_fingerprint" IS 'Aggregate state of all sources';

COMMENT ON COLUMN "trend_directory"."materialization_state"."processed_fingerprint" IS 'Snapshot of the source_fingerprint at the time of the most recent materialization
';

COMMENT ON COLUMN "trend_directory"."materialization_state"."max_modified" IS 'Date of last data received';

COMMENT ON COLUMN "trend_directory"."materialization_state"."job_id" IS 'ID of the most recent job for this materialization';

GRANT SELECT ON TABLE "trend_directory"."materialization_state" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."materialization_state" TO minerva_writer;



CREATE TABLE "trend_directory"."function_materialization_state"
(
  "materialization_id" integer NOT NULL,
  "timestamp" timestamp with time zone NOT NULL,
  "source_fingerprint" jsonb,
  "processed_fingerprint" jsonb,
  "job_id" bigint,
  PRIMARY KEY (materialization_id, timestamp)
);

COMMENT ON TABLE "trend_directory"."function_materialization_state" IS 'Stores the relation between the state of the sources used for the materialization and the state of the materialized data, so that from this table, it can be decided if a new materialization should be done.
';

COMMENT ON COLUMN "trend_directory"."function_materialization_state"."materialization_id" IS 'The ID of the materialization type';

COMMENT ON COLUMN "trend_directory"."function_materialization_state"."timestamp" IS 'The timestamp of the materialized (materialization result) data';

COMMENT ON COLUMN "trend_directory"."function_materialization_state"."source_fingerprint" IS 'Aggregate state of all sources';

COMMENT ON COLUMN "trend_directory"."function_materialization_state"."processed_fingerprint" IS 'Snapshot of the source_fingerprint at the time of the most recent materialization
';

COMMENT ON COLUMN "trend_directory"."function_materialization_state"."job_id" IS 'ID of the most recent job for this materialization';

GRANT SELECT ON TABLE "trend_directory"."function_materialization_state" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."function_materialization_state" TO minerva_writer;



CREATE FUNCTION "trend_directory"."max_modified"("dst_trend_store_part_id" integer, timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
SELECT max(last) FROM trend_directory.modified
  WHERE trend_store_part_id = $1
  AND timestamp < $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."update_source_fingerprint"("materialization_id" integer, timestamp with time zone)
    RETURNS void
AS $$
DECLARE
  materialization trend_directory.materialization;
BEGIN
  SELECT * FROM trend_directory.materialization WHERE id = $1 INTO materialization;
  IF action_count(format('SELECT * FROM trend_directory.materialization_state WHERE materialization_id = %s AND timestamp = ''%s''', $1, $2)) = 0
    THEN INSERT INTO trend_directory.materialization_state(materialization_id, timestamp, source_fingerprint, max_modified, processed_fingerprint, job_id)
      VALUES ($1, $2, (trend_directory.source_fingerprint($1, $2)).body, trend_directory.max_modified(materialization.dst_trend_store_part_id, $2), null, null);
    ELSE UPDATE trend_directory.materialization_state ms SET source_fingerprint = (trend_directory.source_fingerprint($1, $2)).body, max_modified = trend_directory.max_modified(materialization.dst_trend_store_part_id, $2) WHERE ms.materialization_id = $1 AND ms.timestamp = $2;
  END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."update_source_fingerprint"("materialization_id" integer, timestamp with time zone) IS 'Update the fingerprint of the sources in the materialization_state table.';


CREATE TABLE "trend_directory"."materialization_tag_link"
(
  "materialization_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY (materialization_id, tag_id)
);

COMMENT ON TABLE "trend_directory"."materialization_tag_link" IS 'Links tags to materializations. Examples of tags to link to a materialization
might be: online, offline, aggregation, kpi, etc.';

GRANT SELECT ON TABLE "trend_directory"."materialization_tag_link" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."materialization_tag_link" TO minerva_writer;



CREATE TABLE "trend_directory"."materialization_trend_store_link"
(
  "materialization_id" integer NOT NULL,
  "trend_store_part_id" integer NOT NULL,
  "timestamp_mapping_func" regprocedure NOT NULL,
  PRIMARY KEY (materialization_id, trend_store_part_id)
);

COMMENT ON TABLE "trend_directory"."materialization_trend_store_link" IS 'Stores the dependencies between a materialization and its source table trend store parts. Multiple levels of views and functions may exist between a materialization and its source table trend stores. These intermediate views and functions are not registered here, but only the table trend stores containing the actual source data used in the view.
The timestamp_mapping_func column stores the function to map a timestamp of the source (trend_store_part) to a timestamp of the target (the view and target trend_store_part).
';

COMMENT ON COLUMN "trend_directory"."materialization_trend_store_link"."materialization_id" IS 'Reference to a materialization.';

COMMENT ON COLUMN "trend_directory"."materialization_trend_store_link"."trend_store_part_id" IS 'Reference to a trend_store_part that is a source of the materialization referenced by materialization_id.
';

COMMENT ON COLUMN "trend_directory"."materialization_trend_store_link"."timestamp_mapping_func" IS 'The function that maps timestamps in the source table to timestamps in the materialized data. For example, for a view for an hour aggregation from 15 minute granularity data will need to map 4 timestamps in the source to 1 timestamp in the resulting data.
';

GRANT SELECT ON TABLE "trend_directory"."materialization_trend_store_link" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."materialization_trend_store_link" TO minerva_writer;



CREATE FUNCTION "trend_directory"."completeness"(name, "start" timestamp with time zone, "end" timestamp with time zone)
    RETURNS TABLE("timestamp" timestamptz, "count" bigint)
AS $$
DECLARE
    gran interval;
    truncated_start timestamptz;
    truncated_end timestamptz;
BEGIN
    SELECT granularity INTO gran
    FROM trend_directory.trend_store_part tsp
    JOIN trend_directory.trend_store ts ON ts.id = tsp.trend_store_id
    WHERE tsp.name = $1;

    CASE gran
    WHEN '1month' THEN
        SELECT date_trunc('month', $2) INTO truncated_start;
        SELECT date_trunc('month', $3) INTO truncated_end;
    WHEN '1w' THEN
        SELECT date_trunc('week', $2) INTO truncated_start;
        SELECT date_trunc('week', $3) INTO truncated_end;
    WHEN '1d' THEN
        SELECT date_trunc('day', $2) INTO truncated_start;
        SELECT date_trunc('day', $3) INTO truncated_end;
    WHEN '1h' THEN
        SELECT date_trunc('hour', $2) INTO truncated_start;
        SELECT date_trunc('hour', $3) INTO truncated_end;
    ELSE
        SELECT trend_directory.index_to_timestamp(gran, trend_directory.timestamp_to_index(gran, $2)) INTO truncated_start;
        SELECT trend_directory.index_to_timestamp(gran, trend_directory.timestamp_to_index(gran, $3)) INTO truncated_end;
    END CASE;

    RETURN QUERY
    WITH trend_data AS (
        SELECT s.timestamp, s.count from trend_directory.trend_store_part_stats s
        JOIN trend_directory.trend_store_part p ON s.trend_store_part_id = p.id
        WHERE s.timestamp >= truncated_start and s.timestamp <= truncated_end and p.name = $1
    )
    SELECT t, coalesce(d.count, 0)::bigint
        FROM generate_series(truncated_start, truncated_end, gran) t
        LEFT JOIN trend_data d on d.timestamp = t ORDER BY t asc;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."completeness"(name, "start" timestamp with time zone, "end" timestamp with time zone) IS 'Return table with record counts grouped by timestamp';


CREATE FUNCTION "trend_directory"."map_timestamp"("materialization_id" integer, "trend_store_part_id" integer, timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
DECLARE
  mts_link trend_directory.materialization_trend_store_link;
  result timestamp with time zone;
BEGIN
  SELECT * FROM trend_directory.materialization_trend_store_link tsl WHERE tsl.materialization_id = $1 AND tsl.trend_store_part_id = $2 INTO mts_link;
  EXECUTE format('SELECT %s($1)', mts_link.timestamp_mapping_func::regproc::name) INTO result USING $3;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."map_timestamp"("materialization_id" integer, "trend_store_part_id" integer, timestamp with time zone) IS 'Map timestamp using the mapping function defined in the link';


CREATE FUNCTION "trend_directory"."update_materialization_state"(integer, timestamp with time zone)
    RETURNS bigint
AS $$
SELECT count(*) FROM (
    WITH mapped_modified AS (
      SELECT
        materialization_id,
        trend_directory.map_timestamp(materialization_trend_store_link.materialization_id, materialization_trend_store_link.trend_store_part_id, $2) AS dst_timestamp
      FROM trend_directory.materialization_trend_store_link
      WHERE trend_store_part_id = $1
    )
    SELECT trend_directory.update_source_fingerprint(m.id, dst_timestamp)
    FROM mapped_modified
    JOIN trend_directory.materialization m ON m.id = materialization_id
    GROUP BY m.id, dst_timestamp
) update_result;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."new_modified"()
    RETURNS trigger
AS $$
BEGIN
    PERFORM "trend_directory"."update_materialization_state"(NEW.trend_store_part_id, NEW.timestamp);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TRIGGER update_materialization_state_on_new_modified
  AFTER INSERT OR UPDATE ON "trend_directory"."modified"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."new_modified"();


CREATE FUNCTION "trend_directory"."base_table_schema"()
    RETURNS name
AS $$
SELECT 'trend'::name;
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


CREATE FUNCTION "trend_directory"."base_table_name"(trend_directory.trend_store_part)
    RETURNS name
AS $$
SELECT $1.name;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "trend_directory"."base_table_name_by_trend_store_part_id"("trend_store_part_id" integer)
    RETURNS name
AS $$
SELECT name FROM trend_directory.trend_store_part
  WHERE id = $1;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "trend_directory"."view_name"(trend_directory.trend_view_part)
    RETURNS name
AS $$
SELECT $1.name;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."fingerprint_function_name"(trend_directory.materialization)
    RETURNS name
AS $$
SELECT format('%s_fingerprint', trend_directory.materialization_to_char($1.id))::name;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."to_char"(trend_directory.trend_store_part)
    RETURNS text
AS $$
SELECT $1.name::text;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."to_char"(trend_directory.trend_view_part)
    RETURNS text
AS $$
SELECT $1.name::text;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."get_trend_view"("data_source_name" text, "entity_type_name" text, "granularity" interval)
    RETURNS trend_directory.trend_view
AS $$
SELECT ts
    FROM trend_directory.trend_view ts
    JOIN directory.data_source ds ON ds.id = ts.data_source_id
    JOIN directory.entity_type et ON et.id = ts.entity_type_id
    WHERE lower(ds.name) = lower($1) AND lower(et.name) = lower($2) AND ts.granularity = $3;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."partition_schema"()
    RETURNS name
AS $$
SELECT 'trend_partition'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend_directory"."partition_name"(trend_directory.trend_store_part, integer)
    RETURNS name
AS $$
SELECT format('%s_%s', trend_directory.base_table_name($1), $2)::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."index_to_timestamp"("partition_size" interval, "index" integer)
    RETURNS timestamp with time zone
AS $$
SELECT to_timestamp(extract(epoch from $1) * $2);
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION "trend_directory"."timestamp_to_index"(interval, timestamp with time zone)
    RETURNS integer
AS $$
SELECT extract(epoch from $2)::integer / extract(epoch from $1)::integer;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."timestamp_to_index"(trend_directory.trend_store, timestamp with time zone)
    RETURNS integer
AS $$
SELECT trend_directory.timestamp_to_index($1.partition_size, $2);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."create_partition_sql"(trend_directory.trend_store_part, integer)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE TABLE %I.%I '
        'PARTITION OF %I.%I '
        'FOR VALUES FROM (''%s'') TO (''%s'')',
        trend_directory.partition_schema(),
        trend_directory.partition_name($1, $2),
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1),
        trend_directory.index_to_timestamp(trend_store.partition_size, $2),
        trend_directory.index_to_timestamp(trend_store.partition_size, $2 + 1)
    )
]
FROM trend_directory.trend_store WHERE id = $1.trend_store_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."get_partition_size"(trend_directory.trend_store_part)
    RETURNS interval
AS $$
SELECT partition_size FROM trend_directory.trend_store WHERE trend_store.id = $1.trend_store_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."create_partition"(trend_directory.trend_store_part, integer)
    RETURNS trend_directory.partition
AS $$
DECLARE
  result trend_directory.partition;
BEGIN
  PERFORM public.action($1, trend_directory.create_partition_sql($1, $2));

  INSERT INTO trend_directory.partition(trend_store_part_id, index, name, "from", "to")
    SELECT $1.id, $2, trend_directory.partition_name($1, $2), trend_directory.index_to_timestamp(trend_store.partition_size, $2), trend_directory.index_to_timestamp(trend_store.partition_size, $2 + 1)
    FROM trend_directory.trend_store WHERE id = $1.trend_store_id
    RETURNING * INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."create_partition"(trend_directory.trend_store_part, timestamp with time zone)
    RETURNS trend_directory.partition
AS $$
SELECT trend_directory.create_partition($1, trend_directory.timestamp_to_index(trend_directory.get_partition_size($1), $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."create_partition"("trend_store_part_id" integer, integer)
    RETURNS trend_directory.partition
AS $$
DECLARE
  tsp trend_directory.trend_store_part;
BEGIN
  SELECT * FROM trend_directory.trend_store_part WHERE id = $1 INTO tsp;
  RETURN trend_directory.create_partition(tsp, $2);
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."column_spec"(trend_directory.table_trend)
    RETURNS text
AS $$
SELECT format('%I %s', $1.name, $1.data_type);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend_directory"."trend_column_spec"("table_trend_id" integer)
    RETURNS text
AS $$
DECLARE
  tt trend_directory.table_trend;
BEGIN
  SELECT * FROM trend_directory.table_trend WHERE id = $1 INTO tt;
  RETURN trend_directory.column_spec(tt);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE FUNCTION "trend_directory"."column_spec"(trend_directory.generated_table_trend)
    RETURNS text
AS $$
SELECT format('%I %s GENERATED ALWAYS AS (%s) STORED', $1.name, $1.data_type, $1.expression);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend_directory"."generated_trend_column_spec"("generated_table_trend_id" integer)
    RETURNS text
AS $$
DECLARE
  tt trend_directory.generated_table_trend;
BEGIN
  SELECT * FROM trend_directory.generated_table_trend WHERE id = $1 INTO tt;
  RETURN trend_directory.column_spec(tt);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE FUNCTION "trend_directory"."column_specs"(trend_directory.trend_store_part)
    RETURNS text[]
AS $$
SELECT array_agg(c) FROM (
  SELECT trend_directory.trend_column_spec(t.id) AS c
  FROM trend_directory.table_trend t
  WHERE t.trend_store_part_id = $1.id
  UNION ALL
  SELECT trend_directory.generated_trend_column_spec(t.id) AS c
  FROM trend_directory.generated_table_trend t
  WHERE t.trend_store_part_id = $1.id
) combined_columns;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."create_base_table_sql"(trend_directory.trend_store_part)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE TABLE %I.%I ('
        'entity_id integer NOT NULL, '
        '"timestamp" timestamp with time zone NOT NULL, '
        'created timestamp with time zone NOT NULL, '
        '%s'
        ') PARTITION BY RANGE ("timestamp");',
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1),
        array_to_string(ARRAY['job_id bigint NOT NULL'] || trend_directory.column_specs($1), ',')
    ),
    format(
        'ALTER TABLE %I.%I ADD PRIMARY KEY (entity_id, "timestamp");',
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1)
    ),
    format(
        'CREATE INDEX ON %I.%I USING btree (job_id)',
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1)
    ),
    format(
        'CREATE INDEX ON %I.%I USING btree (timestamp);',
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1)
    ),
    format(
        'SELECT create_distributed_table(''%I.%I'', ''entity_id'')',
        trend_directory.base_table_schema(),
        trend_directory.base_table_name($1)
    )
];
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."create_base_table"(trend_directory.trend_store_part)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT public.action($1, trend_directory.create_base_table_sql($1))
$$ LANGUAGE sql VOLATILE STRICT SECURITY DEFINER;


CREATE FUNCTION "trend_directory"."drop_base_table_sql"(trend_directory.trend_store_part)
    RETURNS text
AS $$
SELECT format(
    'DROP TABLE %I.%I',
    trend_directory.base_table_schema(),
    trend_directory.base_table_name($1)
);
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "trend_directory"."drop_base_table"(trend_directory.trend_store_part)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT public.action($1, trend_directory.drop_base_table_sql($1))
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."staging_table_name"(trend_directory.trend_store_part)
    RETURNS name
AS $$
SELECT (trend_directory.base_table_name($1) || '_staging')::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."create_staging_table_sql"(trend_directory.trend_store_part)
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
    )
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."create_staging_table"(trend_directory.trend_store_part)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT public.action($1, trend_directory.create_staging_table_sql($1));
$$ LANGUAGE sql VOLATILE STRICT SECURITY DEFINER;


CREATE FUNCTION "trend_directory"."drop_staging_table_sql"(trend_directory.trend_store_part)
    RETURNS text
AS $$
SELECT format(
    'DROP TABLE %I.%I',
    trend_directory.staging_table_schema(),
    trend_directory.staging_table_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."drop_staging_table"(trend_directory.trend_store_part)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT public.action($1, trend_directory.drop_staging_table_sql($1));
$$ LANGUAGE sql VOLATILE STRICT SECURITY DEFINER;


CREATE FUNCTION "trend_directory"."initialize_trend_store_part"(trend_directory.trend_store_part)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT trend_directory.create_base_table($1);
SELECT trend_directory.create_staging_table($1);

SELECT $1;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."initialize_trend_store_part"(trend_directory.trend_store_part) IS 'Create all database objects required for the trend store part to be fully functional and capable of storing data.';


CREATE FUNCTION "trend_directory"."initialize_trend_store_part"(integer)
    RETURNS trend_directory.trend_store_part
AS $$
DECLARE
  tsp trend_directory.trend_store_part;
BEGIN
  SELECT * from trend_directory.trend_store_part WHERE id = $1 into tsp;
  PERFORM trend_directory.initialize_trend_store_part(tsp);
  RETURN tsp;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."deinitialize_trend_store_part"(trend_directory.trend_store_part)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT trend_directory.drop_base_table($1);
SELECT trend_directory.drop_staging_table($1);
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."deinitialize_trend_store_part"(trend_directory.trend_store_part) IS 'Remove all database objects related to the table trend store part';


CREATE FUNCTION "trend_directory"."deinitialize_trend_store_part"("trend_store_part_id" integer)
    RETURNS void
AS $$
DECLARE
  tsp trend_directory.trend_store_part;
BEGIN
  SELECT * FROM trend_directory.trend_store_part
    WHERE trend_store_part.id = $1 INTO tsp;
  EXECUTE trend_directory.drop_base_table_sql(tsp);
  EXECUTE trend_directory.drop_staging_table_sql(tsp);
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."get_default_partition_size"("granularity" interval)
    RETURNS interval
AS $$
SELECT CASE $1
    WHEN '300'::interval THEN
        '3 hours'::interval
    WHEN '900'::interval THEN
        '6 hours'::interval
    WHEN '1800'::interval THEN
        '6 hours'::interval
    WHEN '1 hour'::interval THEN
        '1 day'::interval
    WHEN '12 hours'::interval THEN
        '7 days'::interval
    WHEN '1 day'::interval THEN
        '7 days'::interval
    WHEN '1 week'::interval THEN
        '1 month'::interval
    WHEN '1 month'::interval THEN
        '1 year'::interval
    END;
$$ LANGUAGE sql IMMUTABLE STRICT;

COMMENT ON FUNCTION "trend_directory"."get_default_partition_size"("granularity" interval) IS 'Return the default partition size in seconds for a particular granularity';


CREATE FUNCTION "trend_directory"."define_table_trend"("trend_store_part_id" integer, trend_directory.trend_descr)
    RETURNS trend_directory.table_trend
AS $$
INSERT INTO trend_directory.table_trend (trend_store_part_id, name, data_type, description, time_aggregation, entity_aggregation)
VALUES ($1, $2.name, $2.data_type, $2.description, $2.time_aggregation, $2.entity_aggregation);
SELECT * FROM trend_directory.table_trend WHERE trend_store_part_id = $1 AND name = $2.name;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_generated_table_trend"("trend_store_part_id" integer, trend_directory.generated_trend_descr)
    RETURNS trend_directory.generated_table_trend
AS $$
INSERT INTO trend_directory.generated_table_trend (trend_store_part_id, name, data_type, expression, extra_data, description)
VALUES ($1, $2.name, $2.data_type, $2.expression, $2.extra_data, $2.description);
SELECT * FROM trend_directory.generated_table_trend WHERE trend_store_part_id = $1 AND name = $2.name;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_trend_view"(directory.data_source, directory.entity_type, "granularity" interval)
    RETURNS trend_directory.trend_view
AS $$
INSERT INTO trend_directory.trend_view (
    data_source_id,
    entity_type_id,
    granularity
)
VALUES (
    $1.id,
    $2.id,
    $3
) RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."create_view_sql"(trend_directory.trend_view_part, "sql" text)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format('CREATE VIEW %I.%I AS %s;', trend_directory.view_schema(), trend_directory.view_name($1), $2)
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."get_view_trends"("view_name" name)
    RETURNS SETOF trend_directory.trend_descr
AS $$
SELECT (a.attname, format_type(a.atttypid, a.atttypmod), 'deduced from view', 'sum', 'sum', '{}')::trend_directory.trend_descr
FROM pg_class c
JOIN pg_attribute a ON a.attrelid = c.oid
WHERE c.relname = $1 AND a.attnum >= 0 AND NOT a.attisdropped;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."show_trends"(trend_directory.trend_store_part)
    RETURNS SETOF trend_directory.trend_descr
AS $$
SELECT
    table_trend.name::name,
    format_type(a.atttypid, a.atttypmod)::text,
    table_trend.description,
    table_trend.time_aggregation,
    table_trend.entity_aggregation,
    table_trend.extra_data
FROM trend_directory.table_trend
JOIN pg_catalog.pg_class c ON c.relname = $1::text
JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid AND a.attname = table_trend.name
WHERE
    n.nspname = 'trend' AND
    a.attisdropped = false AND
    a.attnum > 0 AND table_trend.trend_store_part_id = $1.id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."initialize_trend_view_part"(trend_directory.trend_view_part, "query" text)
    RETURNS trend_directory.trend_view_part
AS $$
SELECT public.action($1, trend_directory.create_view_sql($1, $2));

SELECT $1;
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "trend_directory"."initialize_trend_view"(trend_directory.trend_view, trend_directory.trend_view_part_descr[])
    RETURNS trend_directory.trend_view
AS $$
SELECT $1;
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "trend_directory"."create_trend_view"("data_source_name" text, "entity_type_name" text, "granularity" interval, trend_directory.trend_view_part_descr[])
    RETURNS trend_directory.trend_view
AS $$
DECLARE
  dsource directory.data_source;
  etype directory.entity_type;
BEGIN
  SELECT directory.name_to_data_source($1) into dsource;
  SELECT directory.name_to_entity_type($2) into etype;
  RETURN trend_directory.initialize_trend_view(
    trend_directory.define_trend_view(dsource, etype, $3), $4
  );
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."define_table_trends"(trend_directory.trend_store_part, trend_directory.trend_descr[])
    RETURNS trend_directory.trend_store_part
AS $$
BEGIN
  INSERT INTO trend_directory.table_trend(name, data_type, trend_store_part_id, description, time_aggregation, entity_aggregation, extra_data) (
    SELECT name, data_type, $1.id, description, time_aggregation, entity_aggregation, extra_data
    FROM unnest($2)
  );
  RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."define_generated_table_trends"(trend_directory.trend_store_part, trend_directory.generated_trend_descr[])
    RETURNS trend_directory.trend_store_part
AS $$
BEGIN
  INSERT INTO trend_directory.generated_table_trend(trend_store_part_id, name, data_type, expression, extra_data, description) (
    SELECT $1.id, name, data_type, expression, extra_data, description
    FROM unnest($2)
  );

  RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."rename_trend_store_part"(trend_directory.trend_store_part, name)
    RETURNS trend_directory.trend_store_part
AS $$
BEGIN
  EXECUTE format(
    'ALTER TABLE %I.%I RENAME TO %I',
    trend_directory.base_table_schema(),
    $1.name,
    $2
  );
  RETURN $1;
END; 
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."rename_partitions"(trend_directory.trend_store_part, "new_name" name)
    RETURNS trend_directory.trend_store_part
AS $$
DECLARE
  partition trend_directory.partition;
BEGIN
  FOR partition in SELECT * FROM trend_directory.partition WHERE trend_store_part_id = $1.id
  LOOP
    EXECUTE format(
        'ALTER TABLE trend_partition.%I RENAME TO %I',
        partition.name,
        $2 || '_' || partition.index
    );
    EXECUTE format(
        'UPDATE trend_directory.partition SET name = ''%s'' WHERE id = %s',
        $2 || '_' || partition.index,
        partition.id
    );
  END LOOP;
  RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."rename_trend_store_part_full"(trend_directory.trend_store_part, name)
    RETURNS trend_directory.trend_store_part
AS $$
DECLARE
  old_name text;
  new_name text;
BEGIN
  SET LOCAL citus.multi_shard_modify_mode TO 'sequential';
  SELECT trend_directory.to_char($1) INTO old_name;
  SELECT $2::text INTO new_name;
  PERFORM trend_directory.rename_trend_store_part($1, $2);
  EXECUTE format(
      'ALTER TABLE %I.%I RENAME TO %I',
      trend_directory.staging_table_schema(),
      old_name || '_staging',
      new_name || '_staging'
  );
  PERFORM trend_directory.rename_partitions($1, $2);
  EXECUTE format(
      'UPDATE trend_directory.view_materialization '
      'SET src_view = ''%s'' '
      'WHERE src_view = ''%s''',
      'trend."_' || new_name || '"',
      'trend."_' || old_name || '"'
  );
  EXECUTE format(
      'UPDATE trend_directory.function_materialization '
      'SET src_function = ''%s'' '
      'WHERE src_function = ''%s''',
      'trend."' || new_name || '"',
      'trend."' || old_name || '"'
  );
  RETURN $1;
END
$$ LANGUAGE plpgsql VOLATILE;


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


CREATE FUNCTION "trend_directory"."trend_store"(trend_directory.trend_store_part)
    RETURNS trend_directory.trend_store
AS $$
SELECT *
FROM trend_directory.trend_store
WHERE id = $1.trend_store_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."get_trend_store"("data_source_name" text, "entity_type_name" text, "granularity" interval)
    RETURNS trend_directory.trend_store
AS $$
SELECT ts
FROM trend_directory.trend_store ts
JOIN directory.data_source ds ON ds.id = ts.data_source_id
JOIN directory.entity_type et ON et.id = ts.entity_type_id
WHERE
    lower(ds.name) = lower($1) AND
    lower(et.name) = lower($2) AND
    ts.granularity = $3;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."get_trend_store_id"(trend_directory.trend_store)
    RETURNS integer
AS $$
SELECT $1.id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_trend_store"(directory.data_source, directory.entity_type, "granularity" interval, "partition_size" interval)
    RETURNS trend_directory.trend_store
AS $$
INSERT INTO trend_directory.trend_store (
    data_source_id,
    entity_type_id,
    granularity,
    partition_size
)
VALUES (
    $1.id,
    $2.id,
    $3,
    $4
) RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."delete_trend_store"(integer)
    RETURNS void
AS $$
SELECT trend_directory.deinitialize_trend_store_part(part.id)
FROM trend_directory.trend_store_part AS part
WHERE trend_store_id = $1;

DELETE FROM trend_directory.trend_store WHERE id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."delete_trend_store"("data_source_name" text, "entity_type_name" text, "granularity" interval)
    RETURNS void
AS $$
SELECT trend_directory.delete_trend_store((trend_directory.get_trend_store($1, $2, $3)).id);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."delete_trend_store_part"(trend_directory.trend_store_part)
    RETURNS void
AS $$
DECLARE
    table_name text;
BEGIN

    EXECUTE format(
        'DROP TABLE IF EXISTS trend.%I CASCADE',
        trend_directory.base_table_name($1)
    );

    DELETE FROM trend_directory.trend_store_part tp WHERE tp.id = $1.id;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."initialize_trend_store"(trend_directory.trend_store)
    RETURNS trend_directory.trend_store
AS $$
SELECT trend_directory.initialize_trend_store_part(trend_store_part.id)
FROM trend_directory.trend_store_part WHERE trend_store_id = $1.id;

SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_trend_store_part"("trend_store_id" integer, "name" name)
    RETURNS trend_directory.trend_store_part
AS $$
INSERT INTO trend_directory.trend_store_part (trend_store_id, name)
VALUES ($1, $2)
RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_trend_store_part"("trend_store_id" integer, "name" name, "trends" trend_directory.trend_descr[], "generated_trends" trend_directory.generated_trend_descr[])
    RETURNS trend_directory.trend_store_part
AS $$
SELECT 
trend_directory.define_generated_table_trends(
  trend_directory.define_table_trends(
      trend_directory.define_trend_store_part($1, $2),
      $3
  ),
  $4
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."create_trend_store_part"("trend_store_id" integer, "name" name)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT trend_directory.initialize_trend_store_part(
    trend_directory.define_trend_store_part($1, $2)
  );
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."get_trend_store_parts"("trend_store_id" integer)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT trend_store_part FROM trend_directory.trend_store_part WHERE trend_store_id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."get_trend_store_part"("trend_store_id" integer, "name" name)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT * FROM trend_directory.trend_store_part WHERE trend_store_id = $1 AND name = $2;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."get_trend_store_part_id"(trend_directory.trend_store_part)
    RETURNS integer
AS $$
SELECT $1.id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."get_or_create_trend_store_part"("trend_store_id" integer, "name" name)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT COALESCE(
  trend_directory.get_trend_store_part($1, $2),
  trend_directory.create_trend_store_part($1, $2)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."add_missing_trend_store_parts"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS trend_directory.trend_store
AS $$
SELECT trend_directory.get_or_create_trend_store_part($1.id, name)
  FROM unnest($2);
SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_trend_store"(trend_directory.trend_store, trend_directory.trend_store_part_descr[])
    RETURNS trend_directory.trend_store
AS $$
SELECT trend_directory.define_trend_store_part($1.id, name, trends, generated_trends)
FROM unnest($2);

SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."define_trend_store"(directory.data_source, directory.entity_type, "granularity" interval, "partition_size" interval, "trends" trend_directory.trend_store_part_descr[])
    RETURNS trend_directory.trend_store
AS $$
SELECT trend_directory.define_trend_store(
    trend_directory.define_trend_store($1, $2, $3, $4),
    $5
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."create_trend_store"("data_source_name" text, "entity_type_name" text, "granularity" interval, "partition_size" interval, "parts" trend_directory.trend_store_part_descr[])
    RETURNS trend_directory.trend_store
AS $$
DECLARE
  dsource directory.data_source;
  etype directory.entity_type;
BEGIN
  SELECT * FROM directory.name_to_data_source($1) into dsource;
  SELECT * FROM directory.name_to_entity_type($2) into etype;
  RETURN trend_directory.initialize_trend_store(
    trend_directory.define_trend_store(dsource, etype, $3, $4, $5)
  );
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."staged_timestamps"("part" trend_directory.trend_store_part)
    RETURNS SETOF timestamp with time zone
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT timestamp FROM %I.%I GROUP BY timestamp',
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name(part)
    );
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "trend_directory"."transfer_staged"("trend_store_part" trend_directory.trend_store_part, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    row_count integer;
BEGIN
    EXECUTE format(
        'INSERT INTO %I.%I SELECT * FROM %I.%I WHERE timestamp = $1',
        trend_directory.base_table_schema(),
        trend_directory.base_table_name(trend_store_part),
        trend_directory.staging_table_schema(),
        trend_directory.staging_table_name(trend_store_part)
    ) USING timestamp;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."transfer_staged"("trend_store_part" trend_directory.trend_store_part)
    RETURNS trend_directory.trend_store_part
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


CREATE FUNCTION "trend_directory"."changes_on_trend_update"("trend_directory.table_trend_id" integer, "oldname" text, "newname" text)
    RETURNS void
AS $$
DECLARE
    base_table_name text;
BEGIN
    IF $3 <> $2 THEN
        FOR base_table_name IN
            SELECT trend_directory.base_table_name_by_trend_store_part_id(trend_store_part.id)
            FROM trend_directory.table_trend
            JOIN trend_directory.trend_store_part ON table_trend.trend_store_part_id = trend_store_part.id
            WHERE table_trend.id = $1
        LOOP
            EXECUTE format('ALTER TABLE trend.%I RENAME COLUMN %I TO %I', base_table_name, $2, $3);
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."alter_trend_name"(trend_directory.trend_store_part, "trend_name" name, "new_name" name)
    RETURNS trend_directory.trend_store_part
AS $$
DECLARE
  table_trend_id integer;
BEGIN
  FOR table_trend_id IN
    SELECT id FROM trend_directory.table_trend WHERE trend_store_part_id = $1.id AND name = $2
  LOOP
    UPDATE trend_directory.table_trend SET name = $3 WHERE id = table_trend_id;
    PERFORM trend_directory.changes_on_trend_update(table_trend_id, $2, $3);
  END LOOP;
  RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


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


CREATE FUNCTION "trend_directory"."drop_view_sql"(trend_directory.trend_view_part)
    RETURNS text
AS $$
SELECT format(
    'DROP VIEW IF EXISTS %I.%I',
    trend_directory.view_schema(),
    trend_directory.view_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."drop_view"(trend_directory.trend_view_part)
    RETURNS trend_directory.trend_view_part
AS $$
SELECT public.action($1, trend_directory.drop_view_sql($1));

SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."delete_trend_view"(trend_directory.trend_view)
    RETURNS void
AS $$
SELECT trend_directory.drop_view(tvp)
  FROM trend_directory.trend_view_part tvp
  WHERE tvp.trend_view_id = $1.id;
DELETE FROM trend_directory.trend_view WHERE id = $1.id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."add_column_sql_part"(trend_directory.table_trend)
    RETURNS text
AS $$
SELECT format('ADD COLUMN %I %s', $1.name, $1.data_type);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."add_trends_to_trend_store_part"(trend_directory.trend_store_part, trend_directory.table_trend[])
    RETURNS trend_directory.trend_store_part
AS $$
SELECT public.action(
  $1,
  ARRAY[
    format(
      'ALTER TABLE %I.%I %s;',
      trend_directory.base_table_schema(),
      trend_directory.base_table_name($1),
      (SELECT string_agg(trend_directory.add_column_sql_part(t), ',') FROM unnest($2) AS t)
    ),
    format(
      'ALTER TABLE %I.%I %s;',
      trend_directory.staging_table_schema(),
      trend_directory.staging_table_name($1),
      (SELECT string_agg(trend_directory.add_column_sql_part(t), ',') FROM unnest($2) AS t)
    )
  ]
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."create_table_trends"(trend_directory.trend_store_part, trend_directory.trend_descr[])
    RETURNS trend_directory.trend_store_part
AS $$
SELECT trend_directory.add_trends_to_trend_store_part(
  $1,
  array_agg(trend_directory.define_table_trend($1.id, t))
) FROM unnest($2) AS t
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."add_generated_column_sql_part"(trend_directory.generated_table_trend)
    RETURNS text
AS $$
SELECT format(
  'ADD COLUMN %I %s GENERATED ALWAYS AS (%s) STORED',
  $1.name, $1.data_type, $1.expression
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."add_generated_trends_to_trend_store_part"(trend_directory.trend_store_part, trend_directory.generated_table_trend[])
    RETURNS trend_directory.trend_store_part
AS $$
SELECT public.action(
  $1,
  ARRAY[
    format(
      'ALTER TABLE %I.%I %s;',
      trend_directory.base_table_schema(),
      trend_directory.base_table_name($1),
      (SELECT string_agg(trend_directory.add_generated_column_sql_part(t), ',') FROM unnest($2) AS t)
    )
  ]
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."create_generated_table_trends"(trend_directory.trend_store_part, trend_directory.generated_trend_descr[])
    RETURNS trend_directory.trend_store_part
AS $$
SELECT trend_directory.add_generated_trends_to_trend_store_part(
  $1,
  array_agg(trend_directory.define_generated_table_trend($1.id, t))
) FROM unnest($2) AS t
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."missing_table_trends"(trend_directory.trend_store_part, "required" trend_directory.trend_descr[])
    RETURNS SETOF trend_directory.trend_descr
AS $$
SELECT required
FROM unnest($2) required
LEFT JOIN trend_directory.table_trend ON table_trend.name = required.name AND table_trend.trend_store_part_id = $1.id
WHERE table_trend.id IS NULL;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."missing_generated_table_trends"(trend_directory.trend_store_part, "required" trend_directory.generated_trend_descr[])
    RETURNS SETOF trend_directory.generated_trend_descr
AS $$
SELECT required
FROM unnest($2) required
LEFT JOIN trend_directory.generated_table_trend
ON generated_table_trend.name = required.name AND generated_table_trend.trend_store_part_id = $1.id
WHERE generated_table_trend.id IS NULL;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."missing_generated_table_trends"("trend_store_part" name, "required" trend_directory.generated_trend_descr[])
    RETURNS SETOF trend_directory.generated_trend_descr
AS $$
SELECT trend_directory.missing_generated_table_trends(trend_store_part, $2)
FROM trend_directory.trend_store_part WHERE name = $1
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."assure_table_trends_exist"("trend_store_id" integer, "trend_store_part_name" text, trend_directory.trend_descr[], trend_directory.generated_trend_descr[])
    RETURNS text[]
AS $$
DECLARE
  tsp trend_directory.trend_store_part;
  result text[];
BEGIN
  SELECT * FROM trend_directory.get_or_create_trend_store_part($1, $2) INTO tsp;

  CREATE TEMP TABLE missing_trends(trend trend_directory.trend_descr);
  CREATE TEMP TABLE missing_generated_trends(trend trend_directory.generated_trend_descr);

  -- Normal trends
  INSERT INTO missing_trends SELECT trend_directory.missing_table_trends(tsp, $3);

  IF EXISTS (SELECT * FROM missing_trends LIMIT 1) THEN
    PERFORM trend_directory.create_table_trends(tsp, ARRAY(SELECT trend FROM missing_trends));
  END IF;

  -- Generated trends
  INSERT INTO missing_generated_trends SELECT trend_directory.missing_generated_table_trends(tsp, $4);

  IF EXISTS (SELECT * FROM missing_generated_trends LIMIT 1) THEN
    PERFORM trend_directory.create_generated_table_trends(tsp, missing_generated_trends);
  END IF;

  SELECT ARRAY(SELECT (mt).trend.name FROM missing_trends mt UNION SELECT (mt).trend.name FROM missing_generated_trends mt) INTO result;
  DROP TABLE missing_trends;
  DROP TABLE missing_generated_trends;

  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."add_trends"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
  partresult text[];
BEGIN
  FOR partresult IN
    SELECT trend_directory.assure_table_trends_exist(
      $1.id,
      name,
      trends,
      generated_trends
    )
    FROM unnest($2)
  LOOP
    SELECT result || partresult INTO result;
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."add_trends"("part" trend_directory.trend_store_part_descr)
    RETURNS text[]
AS $$
SELECT trend_directory.assure_table_trends_exist(
  trend_store_part.trend_store_id,
  $1.name,
  $1.trends,
  $1.generated_trends
)
FROM trend_directory.trend_store_part
WHERE name = $1.name;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."remove_table_trend"("trend" trend_directory.table_trend)
    RETURNS trend_directory.table_trend
AS $$
BEGIN
  EXECUTE FORMAT('ALTER TABLE trend.%I DROP COLUMN %I',
    trend_directory.trend_store_part_name_for_trend(trend), trend.name);
  EXECUTE FORMAT('ALTER TABLE trend.%I DROP COLUMN %I',
    trend_directory.trend_store_part_name_for_trend(trend)::text || '_staging', trend.name);
  DELETE FROM trend_directory.table_trend WHERE id = trend.id;
  RETURN t FROM trend_directory.table_trend t WHERE 0=1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."trend_store_part_name_for_trend"("trend" trend_directory.table_trend)
    RETURNS name
AS $$
SELECT trend_store_part.name FROM trend_directory.table_trend LEFT JOIN trend_directory.trend_store_part
  ON table_trend.trend_store_part_id = trend_store_part.id
  WHERE table_trend.id = trend.id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."trend_store_part_name_for_trend"("trend_id" integer)
    RETURNS name
AS $$
SELECT trend_store_part.name FROM trend_directory.table_trend LEFT JOIN trend_directory.trend_store_part
  ON table_trend.trend_store_part_id = trend_store_part.id
  WHERE table_trend.id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."get_trends_for_trend_store"("trend_store_id" integer)
    RETURNS SETOF trend_directory.table_trend
AS $$
SELECT table_trend
  FROM trend_directory.table_trend
  LEFT JOIN trend_directory.trend_store_part
  ON table_trend.trend_store_part_id = trend_store_part.id
  WHERE trend_store_part.trend_store_id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."get_trends_for_trend_store"(trend_directory.trend_store)
    RETURNS SETOF trend_directory.table_trend
AS $$
SELECT trend_directory.get_trends_for_trend_store($1.id);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."get_trend_if_defined"("trend" trend_directory.table_trend, "trends" trend_directory.trend_descr[])
    RETURNS name
AS $$
SELECT t.name FROM trend_directory.table_trend t JOIN unnest($2) t2
  ON t.name = t2.name WHERE t.id = $1.id
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."get_trend_if_defined"("trend" trend_directory.table_trend, "trends" trend_directory.trend_descr[]) IS 'Return the trend, but only if it is a trend defined by trends';


CREATE FUNCTION "trend_directory"."remove_trend_if_extraneous"("trend" trend_directory.table_trend, "trends" trend_directory.trend_descr[])
    RETURNS text
AS $$
DECLARE
  result text;
  defined_trend name;
BEGIN
  SELECT trend_directory.get_trend_if_defined($1, $2) INTO defined_trend;
  IF defined_trend IS NULL THEN
    SELECT $1.name INTO result;
    PERFORM trend_directory.remove_table_trend($1);
  END IF;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."remove_trend_if_extraneous"("trend" trend_directory.table_trend, "trends" trend_directory.trend_descr[]) IS 'Remove the trend if it is not one that is described by trends';


CREATE FUNCTION "trend_directory"."get_trends_for_trend_store_part"("trend_store_part_id" integer)
    RETURNS SETOF trend_directory.table_trend
AS $$
BEGIN
  RETURN QUERY EXECUTE FORMAT('SELECT * FROM trend_directory.table_trend WHERE table_trend.trend_store_part_id = %s;', $1);
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "trend_directory"."get_trends_for_trend_store_part"(trend_directory.trend_store_part)
    RETURNS SETOF trend_directory.table_trend
AS $$
BEGIN
  RETURN QUERY EXECUTE FORMAT('SELECT trend_directory.get_trends_for_trend_store_part(%s);', $1.id);
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "trend_directory"."remove_extra_trends"("trend_store_part_id" integer, trend_directory.trend_descr[])
    RETURNS text[]
AS $$
DECLARE
  trend trend_directory.table_trend;
  removal_result text;
  result text[];
BEGIN
  FOR trend IN SELECT * FROM trend_directory.get_trends_for_trend_store_part($1)
  LOOP
    SELECT trend_directory.remove_trend_if_extraneous(trend, $2) INTO removal_result;
    IF removal_result IS NOT NULL THEN
      SELECT result || removal_result INTO result;
    END IF;
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."remove_extra_trends"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
  partresult text[];
BEGIN
  FOR partresult IN
    SELECT trend_directory.remove_extra_trends(
      trend_directory.get_trend_store_part($1.id, name), trends)
    FROM unnest($2)
  LOOP
    SELECT result || partresult INTO result;
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."remove_extra_trends"("part" trend_directory.trend_store_part_descr)
    RETURNS text[]
AS $$
SELECT trend_directory.remove_extra_trends(
  id,
  $1.trends
)
FROM trend_directory.trend_store_part
WHERE name = $1.name;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."change_table_trend_data_unsafe"("trend_id" integer, "data_type" text, "entity_aggregation" text, "time_aggregation" text)
    RETURNS text
AS $$
DECLARE
  result text;
  trend trend_directory.table_trend;
BEGIN
  SELECT * FROM trend_directory.table_trend WHERE id = $1 INTO trend;
  IF trend.data_type <> $2 OR trend.entity_aggregation <> $3 OR trend.time_aggregation <> $4
  THEN
    UPDATE trend_directory.table_trend SET
      data_type = $2,
      entity_aggregation = $3,
      time_aggregation = $4
    WHERE id = $1;
    SELECT trend.name INTO result;
  END IF;

  IF trend.data_type <> $2
  THEN
    EXECUTE format('ALTER TABLE trend.%I ALTER %I TYPE %s USING CAST(%I AS %s)',
      trend_directory.trend_store_part_name_for_trend($1),
      trend.name,
      $2,
      trend.name,
      $2);
  END IF;

  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


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
        WHEN 'numeric[]' THEN
            RETURN 10;
        WHEN 'text[]' THEN
            RETURN 11;
        WHEN 'text' THEN
            RETURN 12;
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


CREATE FUNCTION "trend_directory"."change_table_trend_data_safe"("trend_id" integer, "data_type" text, "entity_aggregation" text, "time_aggregation" text)
    RETURNS text
AS $$
DECLARE
  trend trend_directory.table_trend;
BEGIN
  SELECT * FROM trend_directory.table_trend WHERE id = $1 INTO trend;
  RETURN trend_directory.change_table_trend_data_unsafe(
    $1,
    trend_directory.greatest_data_type($2, trend.data_type),
    $3,
    $4);
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trend_data_unsafe"("trend" trend_directory.table_trend, "trends" trend_directory.trend_descr[], "partname" text)
    RETURNS text
AS $$
SELECT trend_directory.change_table_trend_data_unsafe($1.id, t.data_type, t.entity_aggregation, t.time_aggregation)
  FROM unnest($2) t
  WHERE t.name = $1.name AND trend_directory.trend_store_part_name_for_trend($1) = $3;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trend_data_safe"("trend" trend_directory.table_trend, "trends" trend_directory.trend_descr[], "partname" text)
    RETURNS text
AS $$
SELECT trend_directory.change_table_trend_data_safe($1.id, t.data_type, t.entity_aggregation, t.time_aggregation)
  FROM unnest($2) t
  WHERE t.name = $1.name AND trend_directory.trend_store_part_name_for_trend($1) = $3;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."change_all_trend_data"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
  partresult text;
BEGIN
  FOR partresult IN
    SELECT trend_directory.change_trend_data_unsafe(
      trend_directory.get_trends_for_trend_store($1), trends, name)
    FROM unnest($2)
  LOOP
    IF partresult IS NOT null THEN
      SELECT result || partresult INTO result;
    END IF;
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trend_data_upward"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
  partresult text;
BEGIN
  FOR partresult IN
    SELECT trend_directory.change_trend_data_safe(
      trend_directory.get_trends_for_trend_store($1), trends, name)
    FROM unnest($2)
  LOOP
    IF partresult IS NOT null THEN
      SELECT result || partresult INTO result;
    END IF;
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trend_data"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
  partresult text;
BEGIN
  FOR partresult IN
    SELECT trend_directory.change_trend_data_unsafe(
      trend_directory.get_trends_for_trend_store($1), trends, name)
    FROM unnest($2)
  LOOP
    IF partresult IS NOT null THEN
      SELECT result || partresult INTO result;
    END IF;
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."trend_has_update"("trend_id" integer, "trend_update" trend_directory.trend_descr)
    RETURNS boolean
AS $$
DECLARE
  trend trend_directory.table_trend;
BEGIN
  SELECT * FROM trend_directory.table_trend WHERE id = $1 INTO trend;
  RETURN
    trend.data_type != $2.data_type
      OR
    trend.time_aggregation != $2.time_aggregation
      OR
    trend.entity_aggregation != $2.entity_aggregation;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trend_data_upward"("part" trend_directory.trend_store_part_descr)
    RETURNS text[]
AS $$
SELECT array_agg(trend_directory.change_table_trend_data_safe(
  table_trend.id,
  t.data_type,
  t.entity_aggregation,
  t.time_aggregation
))
FROM trend_directory.trend_store_part
  JOIN trend_directory.table_trend ON table_trend.trend_store_part_id = trend_store_part.id
  JOIN UNNEST($1.trends) AS t ON t.name = table_trend.name
  WHERE trend_store_part.name = $1.name AND trend_directory.trend_has_update(table_trend.id, t);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trend_data"("part" trend_directory.trend_store_part_descr)
    RETURNS text[]
AS $$
SELECT array_agg(trend_directory.change_table_trend_data_unsafe(
  table_trend.id,
  t.data_type,
  t.entity_aggregation,
  t.time_aggregation
))
FROM trend_directory.trend_store_part
  JOIN trend_directory.table_trend ON table_trend.trend_store_part_id = trend_store_part.id
  JOIN UNNEST($1.trends) AS t ON t.name = table_trend.name
  WHERE trend_store_part.name = $1.name AND trend_directory.trend_has_update(table_trend.id, t);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trendstore_strong"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
  partresult text[];
BEGIN
  SELECT trend_directory.add_trends($1, $2) INTO partresult;
  IF array_ndims(partresult) > 0
  THEN
    SELECT result || ARRAY['added trends:'] || partresult INTO result;
  ELSE
    SELECT result || ARRAY['no trends added'] INTO result;
  END IF;
  
  SELECT trend_directory.remove_extra_trends($1, $2) INTO partresult;
  IF array_ndims(partresult) > 0
  THEN
    SELECT result || ARRAY['removed trends:'] || partresult INTO result;
  ELSE
    SELECT result || ARRAY['no trends removed'] INTO result;
  END IF;

  SELECT trend_directory.change_all_trend_data($1, $2) INTO partresult;
  IF array_ndims(partresult) > 0
  THEN
    SELECT result || ARRAY['changed trends:'] || partresult INTO result;
  ELSE
    SELECT result || ARRAY['no trends changed'] INTO result;
  END IF;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trendstore_weak"(trend_directory.trend_store, "parts" trend_directory.trend_store_part_descr[])
    RETURNS text[]
AS $$
DECLARE
  result text[];
  partresult text[];
BEGIN
  SELECT trend_directory.add_trends($1, $2) INTO partresult;
  IF array_ndims(partresult) > 0
  THEN
    SELECT result || ARRAY['added trends:'] || partresult INTO result;
  ELSE
    SELECT result || ARRAY['no trends added'] INTO result;
  END IF;
  
  SELECT trend_directory.remove_extra_trends($1, $2) INTO partresult;
  IF array_ndims(partresult) > 0
  THEN
    SELECT result || ARRAY['removed trends:'] || partresult INTO result;
  ELSE
    SELECT result || ARRAY['no trends removed'] INTO result;
  END IF;

  SELECT trend_directory.change_trend_data_upward($1, $2) INTO partresult;
  IF array_ndims(partresult) > 0
  THEN
    SELECT result || ARRAY['changed trends:'] || partresult INTO result;
  ELSE
    SELECT result || ARRAY['no trends changed'] INTO result;
  END IF;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TYPE "trend_directory"."change_trend_store_part_result" AS (
  "added_trends" text[],
  "removed_trends" text[],
  "changed_trends" text[]
);



CREATE FUNCTION "trend_directory"."change_trend_store_part_weak"("part" trend_directory.trend_store_part_descr)
    RETURNS trend_directory.change_trend_store_part_result
AS $$
DECLARE
  result trend_directory.change_trend_store_part_result;
BEGIN
  SELECT trend_directory.add_trends($1) INTO result.added_trends;

  SELECT trend_directory.remove_extra_trends($1) INTO result.removed_trends;

  SELECT trend_directory.change_trend_data_upward($1) INTO result.changed_trends;

  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."change_trend_store_part_strong"("part" trend_directory.trend_store_part_descr)
    RETURNS trend_directory.change_trend_store_part_result
AS $$
DECLARE
  result trend_directory.change_trend_store_part_result;
BEGIN
  SELECT trend_directory.add_trends($1) INTO result.added_trends;

  SELECT trend_directory.remove_extra_trends($1) INTO result.removed_trends;

  SELECT trend_directory.change_trend_data($1) INTO result.changed_trends;

  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


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


CREATE FUNCTION "trend_directory"."get_table_trend"(trend_directory.trend_store_part, name)
    RETURNS trend_directory.table_trend
AS $$
SELECT table_trend
FROM trend_directory.table_trend
WHERE trend_store_part_id = $1.id AND name = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."trend_store_part_has_trend_with_name"("part" trend_directory.trend_store_part, "trend_name" name)
    RETURNS bool
AS $$
SELECT exists(
    SELECT 1
    FROM trend_directory.table_trend
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


CREATE AGGREGATE trend_directory.max_data_type (text) (
    sfunc = trend_directory.greatest_data_type,
    stype = text
);



CREATE TYPE "trend_directory"."upgrade_record" AS (
  "timestamp" timestamp with time zone,
  "number_of_rows" integer
);



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


CREATE FUNCTION "trend_directory"."update_modified"("trend_store_part_id" integer, "timestamp" timestamp with time zone, "modified" timestamp with time zone)
    RETURNS void
AS $$
INSERT INTO trend_directory.modified AS m (trend_store_part_id, timestamp, first, last)
VALUES ($1, $2, $3, $3)
ON CONFLICT ON CONSTRAINT modified_pkey DO UPDATE SET last = EXCLUDED.last;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."process_modified_log"("start_id" bigint)
    RETURNS bigint
AS $$
WITH process_log AS (
  SELECT
    max(id) AS max_id,
    trend_directory.update_modified(trend_store_part_id, timestamp, max(modified)) AS update
  FROM trend_directory.modified_log
  WHERE id > $1
  GROUP BY trend_store_part_id, timestamp
) SELECT coalesce(max(max_id), $1) FROM process_log;
$$ LANGUAGE sql VOLATILE;


CREATE TABLE "trend_directory"."modified_log_processing_state"
(
  "name" text NOT NULL,
  "last_processed_id" bigint NOT NULL,
  "updated" timestamp with time zone NOT NULL DEFAULT now(),
  PRIMARY KEY (name)
);

GRANT SELECT ON TABLE "trend_directory"."modified_log_processing_state" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "trend_directory"."modified_log_processing_state" TO minerva_writer;



CREATE FUNCTION "trend_directory"."process_modified_log"()
    RETURNS bigint
AS $$
WITH processed AS (
  SELECT trend_directory.process_modified_log(coalesce(max(last_processed_id), 0)) AS last_processed_id
  FROM trend_directory.modified_log_processing_state WHERE name = 'current'
)
INSERT INTO trend_directory.modified_log_processing_state(name, last_processed_id)
SELECT 'current', processed.last_processed_id
FROM processed
ON CONFLICT (name) DO UPDATE SET last_processed_id = EXCLUDED.last_processed_id
RETURNING last_processed_id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."mark_modified"("trend_store_part_id" integer, "timestamp" timestamp with time zone, "modified" timestamp with time zone)
    RETURNS void
AS $$
INSERT INTO trend_directory.modified_log(trend_store_part_id, timestamp, modified)
VALUES ($1, $2, $3);
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."mark_modified"("trend_store_part_id" integer, "timestamp" timestamp with time zone, "modified" timestamp with time zone) IS 'Stores a record in the trend_directory.modified_log table.
';


CREATE FUNCTION "trend_directory"."mark_modified"("trend_store_id" integer, "timestamp" timestamp with time zone)
    RETURNS void
AS $$
INSERT INTO trend_directory.modified_log(trend_store_part_id, timestamp, modified)
VALUES ($1, $2, now());
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."mark_modified"("trend_store_id" integer, "timestamp" timestamp with time zone) IS 'Stores a record in the trend_directory.modified_log table.
';


CREATE VIEW "trend_directory"."trend_store_part_stats_to_update" AS
SELECT tsps.trend_store_part_id,
    tsps.timestamp
  FROM trend_directory.trend_store_part_stats tsps
  JOIN trend_directory.modified m
  ON tsps.trend_store_part_id = m.trend_store_part_id
    AND tsps.timestamp = m.timestamp
  WHERE tsps.modified < m.last + interval '1 second';


CREATE FUNCTION "trend_directory"."get_count"("trend_store_part_id" integer, "timestamp" timestamptz)
    RETURNS integer
AS $$
DECLARE
  result integer;
BEGIN
  EXECUTE FORMAT('SELECT COUNT(*)::integer FROM trend.%I WHERE timestamp = ''%s''',
    trend_directory.base_table_name_by_trend_store_part_id($1),
    $2) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "trend_directory"."recalculate_trend_store_part_stats"("trend_store_part_id" integer, "timestamp" timestamptz)
    RETURNS void
AS $$
UPDATE trend_directory.trend_store_part_stats
  SET modified = now(), count = trend_directory.get_count($1, $2)
  WHERE trend_store_part_id = $1
    AND timestamp = $2;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."update_trend_store_part_stats"()
    RETURNS void
AS $$
SELECT trend_directory.recalculate_trend_store_part_stats(trend_store_part_id, timestamp)
  FROM trend_directory.trend_store_part_stats_to_update;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."create_missing_trend_store_part_stats"()
    RETURNS void
AS $$
INSERT INTO trend_directory.trend_store_part_stats (trend_store_part_id, timestamp, modified, count)
  SELECT m.trend_store_part_id, m.timestamp, '2000-01-01 00:00:00+02', 0
    FROM trend_directory.modified m
      LEFT JOIN trend_directory.trend_store_part_stats s
      ON s.trend_store_part_id = m.trend_store_part_id AND s.timestamp = m.timestamp
      WHERE s IS NULL;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."create_missing_trend_store_part_stats"() IS 'Create trend_store_part_stat where it does not exist yet.';


CREATE TYPE "trend_directory"."transfer_result" AS (
  "row_count" integer,
  "max_modified" timestamp with time zone
);



CREATE FUNCTION "trend_directory"."clear_trend_store_part_sql"("trend_store_part_id" integer)
    RETURNS text
AS $$
SELECT format('DELETE FROM trend.%I WHERE timestamp = $1', ttsp.name)
FROM trend_directory.trend_store_part ttsp WHERE id = $1;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."clear_trend_store_part_sql"("trend_store_part_id" integer) IS 'Return the query to remove all records of the specified timestamp from the trend_store_part.
';


CREATE FUNCTION "trend_directory"."clear_trend_store_part"("trend_store_part_id" integer, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    row_count integer;
BEGIN
    EXECUTE trend_directory.clear_trend_store_part_sql($1) USING $2;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."clear_trend_store_part"("trend_store_part_id" integer, "timestamp" timestamp with time zone) IS 'Removes all records of the specified timestamp from the trend_store_part and returns the removed record count.
';


CREATE FUNCTION "trend_directory"."view_materialization_transfer"("materialization_id" integer, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    mat trend_directory.view_materialization;
    columns_part text;
    row_count integer;
    job_id bigint;
BEGIN
    SELECT * FROM trend_directory.view_materialization WHERE view_materialization.materialization_id = $1 INTO mat;
    SELECT logging.start_job(format('{"view_materialization": "%s", "timestamp": "%s"}', m::text, $2::text)::jsonb) INTO job_id
    FROM trend_directory.materialization m WHERE id = $1;

    SELECT trend_directory.view_materialization_columns_part($1) INTO columns_part;

    EXECUTE format(
        'INSERT INTO trend.%I (entity_id, timestamp, created, job_id, %s) SELECT entity_id, timestamp, now(), %s, %s FROM %s WHERE timestamp = $1',
        (trend_directory.dst_trend_store_part($1)).name,
        columns_part,
        job_id,
        columns_part,
        mat.src_view::name
    ) USING timestamp;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    PERFORM logging.end_job(job_id);

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."view_materialization_transfer"("materialization_id" integer, "timestamp" timestamp with time zone) IS 'Transfer all records of the specified timestamp from the view to the target trend store of the materialization.';


CREATE FUNCTION "trend_directory"."function_materialization_transfer"("materialization_id" integer, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    mat trend_directory.function_materialization;
    columns_part text;
    row_count integer;
    job_id bigint;
BEGIN
    SELECT * FROM trend_directory.function_materialization fm WHERE fm.materialization_id = $1 into mat;
    IF mat IS NULL
      THEN RETURN NULL;
    END IF;
    SELECT logging.start_job(format('{"function_materialization": "%s", "timestamp": "%s"}', m::text, $2::text)::jsonb) INTO job_id
    FROM trend_directory.materialization m WHERE id = $1;

    SELECT trend_directory.function_materialization_columns_part($1) INTO columns_part;

    EXECUTE format(
        'INSERT INTO trend.%I (entity_id, timestamp, created, job_id, %s) SELECT entity_id, timestamp, now(), %s, %s FROM %s($1)',
        (trend_directory.dst_trend_store_part($1)).name,
        columns_part,
        job_id,
        columns_part,
        mat.src_function::regproc
    ) USING timestamp;

    GET DIAGNOSTICS row_count = ROW_COUNT;

    PERFORM logging.end_job(job_id);

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."transfer"("materialization_id" integer, "timestamp" timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
  row_count integer;
BEGIN
  SELECT trend_directory.function_materialization_transfer($1, $2) INTO row_count;

  IF row_count IS NULL THEN
    SELECT trend_directory.view_materialization_transfer($1, $2) INTO row_count;
  END IF;

  RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."materialize"("materialization_id" integer, "timestamp" timestamp with time zone)
    RETURNS trend_directory.transfer_result
AS $$
DECLARE
    mat trend_directory.materialization;
    start timestamp with time zone;
    duration interval;
    columns_part text;
    result trend_directory.transfer_result;
BEGIN
    SELECT * FROM trend_directory.materialization WHERE id = $1 INTO mat;

    start = clock_timestamp();

    -- Remove all records in the target table for the timestamp to materialize
    PERFORM trend_directory.clear_trend_store_part(
        mat.dst_trend_store_part_id, $2
    );

    result.row_count = trend_directory.transfer($1, $2);

    -- Update the state of this materialization
    UPDATE trend_directory.materialization_state vms
    SET processed_fingerprint = vms.source_fingerprint
    WHERE vms.materialization_id = $1 AND vms.timestamp = $2;

    -- Log the change in the target trend store part
    PERFORM trend_directory.mark_modified(mat.dst_trend_store_part_id, $2, now());

    duration = clock_timestamp() - start;

    UPDATE trend_directory.materialization_metrics
    SET execution_count = execution_count + 1, total_duration = total_duration + duration
    WHERE materialization_metrics.materialization_id = $1;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."materialize"("materialization_id" integer, "timestamp" timestamp with time zone) IS 'Materialize the data produced by the referenced view of the materialization by clearing the timestamp in the target trend_store_part and inserting the data resulting from the view into it.
';


CREATE FUNCTION "trend_directory"."materialize"(trend_directory.materialization, "timestamp" timestamp with time zone)
    RETURNS trend_directory.transfer_result
AS $$
SELECT trend_directory.materialize($1.id, $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trend_directory"."show_trends"("trend_store_part_id" integer)
    RETURNS SETOF trend_directory.trend_descr
AS $$
SELECT trend_directory.show_trends(trend_store_part)
FROM trend_directory.trend_store_part
WHERE id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."clear"(trend_directory.trend_store_part, timestamp with time zone)
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


CREATE FUNCTION "trend_directory"."dst_trend_store_part"(trend_directory.materialization)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT * FROM trend_directory.trend_store_part WHERE id = $1.dst_trend_store_part_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."dst_trend_store_part"("materialization_id" integer)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT tsp.* FROM trend_directory.trend_store_part tsp
  JOIN trend_directory.materialization m ON tsp.id = m.dst_trend_store_part_id
  WHERE m.id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."dst_trend_store_part"(trend_directory.view_materialization)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT p.*
FROM trend_directory.trend_store_part p
JOIN trend_directory.materialization m ON m.dst_trend_store_part_id = p.id
WHERE m.id = $1.materialization_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."dst_trend_store_part"(trend_directory.function_materialization)
    RETURNS trend_directory.trend_store_part
AS $$
SELECT p.*
FROM trend_directory.trend_store_part p
JOIN trend_directory.materialization m ON m.dst_trend_store_part_id = p.id
WHERE m.id = $1.materialization_id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."columns_part"("trend_store_part_id" integer)
    RETURNS text
AS $$
WITH columns AS (
  SELECT t.name
  FROM trend_directory.trend_store_part ttsp
  JOIN trend_directory.table_trend t ON t.trend_store_part_id = ttsp.id
  WHERE ttsp.id = $1
)
SELECT
  array_to_string(array_agg(quote_ident(name)), ', ')
FROM columns;
$$ LANGUAGE sql STABLE;

COMMENT ON FUNCTION "trend_directory"."columns_part"("trend_store_part_id" integer) IS 'Return the comma separated, quoted list of column names to be used in queries';


CREATE FUNCTION "trend_directory"."view_materialization_columns_part"("materialization_id" integer)
    RETURNS text
AS $$
SELECT trend_directory.columns_part(m.dst_trend_store_part_id)
  FROM trend_directory.materialization m
  WHERE id = $1;
$$ LANGUAGE sql STABLE;

COMMENT ON FUNCTION "trend_directory"."view_materialization_columns_part"("materialization_id" integer) IS 'Return the comma separated, quoted list of column names to be used in queries';


CREATE FUNCTION "trend_directory"."function_materialization_columns_part"("materialization_id" integer)
    RETURNS text
AS $$
SELECT trend_directory.columns_part(m.dst_trend_store_part_id)
FROM trend_directory.materialization m
WHERE id = $1;
$$ LANGUAGE sql STABLE;

COMMENT ON FUNCTION "trend_directory"."function_materialization_columns_part"("materialization_id" integer) IS 'Return the comma separated, quoted list of column names to be used in queries';


CREATE CAST ("trend_directory"."trend_store_part" AS text)
  WITH FUNCTION "trend_directory"."to_char"("trend_directory"."trend_store_part") AS IMPLICIT;


CREATE CAST ("trend_directory"."trend_store_part" AS name)
  WITH FUNCTION "trend_directory"."base_table_name"("trend_directory"."trend_store_part") AS IMPLICIT;


CREATE CAST ("trend_directory"."trend_view_part" AS text)
  WITH FUNCTION "trend_directory"."to_char"("trend_directory"."trend_view_part") AS IMPLICIT;


CREATE CAST ("trend_directory"."trend_view_part" AS name)
  WITH FUNCTION "trend_directory"."view_name"("trend_directory"."trend_view_part") AS IMPLICIT;


CREATE CAST ("trend_directory"."materialization" AS text)
  WITH FUNCTION "trend_directory"."to_char"("trend_directory"."materialization");


CREATE FUNCTION "trend_directory"."update_modified_column"()
    RETURNS trigger
AS $$
BEGIN
    NEW.modified = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trend_directory"."create_stats_on_creation"()
    RETURNS trigger
AS $$
BEGIN
  INSERT INTO trend_directory.trend_store_part_stats (trend_store_part_id, timestamp, modified, count)
    VALUES (NEW.trend_store_part_id, NEW.timestamp, '2000-01-01 00:00:00+02', 1);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TRIGGER create_stats_on_creation
  AFTER INSERT ON "trend_directory"."modified"
  FOR EACH ROW
  EXECUTE PROCEDURE "trend_directory"."create_stats_on_creation"();


CREATE TABLE "attribute_directory"."attribute_store"
(
  "id" serial NOT NULL,
  "data_source_id" integer NOT NULL,
  "entity_type_id" integer NOT NULL,
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "attribute_store_uniqueness" ON "attribute_directory"."attribute_store" USING btree (data_source_id, entity_type_id);

GRANT SELECT ON TABLE "attribute_directory"."attribute_store" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "attribute_directory"."attribute_store" TO minerva_writer;



CREATE FUNCTION "attribute_directory"."get_attribute_store"("data_source_id" integer, "entity_type_id" integer)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_store
FROM attribute_directory.attribute_store
WHERE data_source_id = $1 AND entity_type_id = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."get_attribute_store"("data_source" text, "entity_type" text)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_store
FROM attribute_directory.attribute_store
LEFT JOIN directory.data_source
  ON data_source_id = data_source.id
LEFT JOIN directory.entity_type
  ON entity_type_id = entity_type.id
WHERE data_source.name = $1 AND lower(entity_type.name) = lower($2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."get_attribute_store"("attribute_store_id" integer)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_store
FROM attribute_directory.attribute_store
WHERE id = $1

$$ LANGUAGE sql STABLE;


CREATE TABLE "attribute_directory"."sampled_view_materialization"
(
  "id" serial NOT NULL,
  "attribute_store_id" integer NOT NULL,
  "src_view" text NOT NULL
);



CREATE TYPE "attribute_directory"."attribute_descr" AS (
  "name" name,
  "data_type" text,
  "description" text
);



CREATE TABLE "attribute_directory"."attribute"
(
  "id" serial NOT NULL,
  "attribute_store_id" integer NOT NULL,
  "description" text,
  "name" name NOT NULL,
  "data_type" text NOT NULL,
  "extra_data" jsonb NOT NULL DEFAULT '{}',
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "attribute_uniqueness" ON "attribute_directory"."attribute" USING btree (attribute_store_id, name);

GRANT SELECT ON TABLE "attribute_directory"."attribute" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "attribute_directory"."attribute" TO minerva_writer;



CREATE TABLE "attribute_directory"."attribute_tag_link"
(
  "attribute_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY (attribute_id, tag_id)
);

GRANT SELECT ON TABLE "attribute_directory"."attribute_tag_link" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "attribute_directory"."attribute_tag_link" TO minerva_writer;



CREATE TABLE "attribute_directory"."attribute_store_modified"
(
  "attribute_store_id" integer NOT NULL,
  "modified" timestamp with time zone NOT NULL,
  PRIMARY KEY (attribute_store_id)
);

GRANT SELECT ON TABLE "attribute_directory"."attribute_store_modified" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "attribute_directory"."attribute_store_modified" TO minerva_writer;



CREATE TABLE "attribute_directory"."attribute_store_curr_materialized"
(
  "attribute_store_id" integer NOT NULL,
  "materialized" timestamp with time zone NOT NULL,
  PRIMARY KEY (attribute_store_id)
);

GRANT SELECT ON TABLE "attribute_directory"."attribute_store_curr_materialized" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "attribute_directory"."attribute_store_curr_materialized" TO minerva_writer;



CREATE TABLE "attribute_directory"."attribute_store_compacted"
(
  "attribute_store_id" integer NOT NULL,
  "compacted" integer NOT NULL,
  PRIMARY KEY (attribute_store_id)
);

GRANT SELECT ON TABLE "attribute_directory"."attribute_store_compacted" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "attribute_directory"."attribute_store_compacted" TO minerva_writer;



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


CREATE FUNCTION "attribute_directory"."attribute_store_to_char"("attribute_store_id" integer)
    RETURNS text
AS $$
SELECT data_source.name || '_' || entity_type.name
  FROM attribute_directory.attribute_store
    JOIN directory.data_source ON data_source.id = attribute_store.data_source_id
    JOIN directory.entity_type ON entity_type.id = attribute_store.entity_type_id
  WHERE attribute_store.id = $1;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION "attribute_directory"."attribute_name"("attribute_store_id" integer)
    RETURNS text
AS $$
DECLARE
  attribute attribute_directory.attribute_store;
BEGIN
  SELECT * FROM attribute_directory.attribute_store WHERE id = $1 INTO attribute;
  RETURN attribute_directory.to_char(attribute);
END;
$$ LANGUAGE plpgsql STABLE STRICT;


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


CREATE FUNCTION "attribute_directory"."hash_query_part"(attribute_directory.attribute)
    RETURNS text
AS $$
SELECT CASE
  WHEN $1.data_type LIKE '%[]'
  THEN format('array_to_text(%I)', $1.name)
  ELSE format('%I::text', $1.name)
END;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."hash_query"(attribute_directory.attribute_store)
    RETURNS text
AS $$
BEGIN
  IF action_count(format('SELECT 1 FROM attribute_directory.attribute WHERE attribute_store_id = %s', $1.id)) = 0
    THEN RETURN '''Q''';
  ELSE 
    RETURN 'md5(' ||
      array_to_string(array_agg(format('(CASE WHEN %I IS NULL THEN '''' ELSE %s END)', name, attribute_directory.hash_query_part(a))), ' || ') ||
      ')' FROM attribute_directory.attribute a WHERE attribute_store_id = $1.id;
  END IF;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "attribute_directory"."changes_view_query"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format('SELECT entity_id, timestamp, COALESCE(hash <> lag(hash) OVER w, true) AS change
FROM attribute_history.%I WINDOW w AS (PARTITION BY entity_id ORDER BY timestamp asc)', attribute_directory.to_table_name($1));
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
    min(id) AS id,
    public.first(entity_id) AS entity_id,
    min(timestamp) AS "start",
    max(timestamp) AS "end",
    min(first_appearance) AS first_appearance,
    max(modified) AS modified,
    count(*) AS run_length
FROM
(
    SELECT id, entity_id, timestamp, first_appearance, modified, sum(change) OVER w2 AS run
    FROM
    (
        SELECT id, entity_id, timestamp, first_appearance, modified, CASE WHEN hash <> lag(hash) OVER w THEN 1 ELSE 0 END AS change
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


CREATE FUNCTION "attribute_directory"."drop_run_length_view_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'DROP VIEW attribute_history.%I',
    attribute_directory.run_length_view_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."drop_run_length_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.drop_run_length_view_sql($1)
);
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "attribute_directory"."drop_run_length_view"(attribute_directory.attribute_store) IS 'Drop the run-length view of the attribute store.';


CREATE FUNCTION "attribute_directory"."drop_changes_view"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    format('DROP VIEW attribute_history.%I', attribute_directory.changes_view_name($1))
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."curr_view_query"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'SELECT h.* FROM attribute_history.%I h JOIN attribute_history.%I c ON h.id = c.id',
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
SELECT format('DROP VIEW attribute.%I CASCADE', attribute_directory.to_table_name($1));
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
        id integer,
        PRIMARY KEY (id))',
        attribute_directory.curr_ptr_table_name($1)
    ),
    format(
        'CREATE INDEX ON attribute_history.%I (id)',
        attribute_directory.curr_ptr_table_name($1)
    ),
    format(
        'ALTER TABLE attribute_history.%I OWNER TO minerva_writer',
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


CREATE FUNCTION "attribute_directory"."drop_curr_ptr_table_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'DROP TABLE attribute_history.%I',
    attribute_directory.curr_ptr_table_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."drop_curr_ptr_table"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.drop_curr_ptr_table_sql($1)
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
        'SELECT DISTINCT ON (entity_id) '
        'a.id '
        'FROM attribute_history.%I a '
        'ORDER BY entity_id, timestamp DESC',
        table_name
    );

    RETURN ARRAY[
        format('CREATE VIEW attribute_history.%I AS %s', view_name, view_sql),
        format(
            'ALTER TABLE attribute_history.%I '
            'OWNER TO minerva_writer',
            view_name
        )
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
    '"timestamp" timestamp with time zone NOT NULL',
    '"end" timestamp with time zone DEFAULT NULL'
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
        'SELECT create_distributed_table(''attribute_base.%I'', ''entity_id'')',
        attribute_directory.to_table_name($1)
    )
]
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."create_base_table"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action($1, attribute_directory.create_base_table_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_base_table_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'DROP TABLE attribute_base.%I',
    attribute_directory.to_table_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."drop_base_table"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action($1, attribute_directory.drop_base_table_sql($1));
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
        id serial,
        first_appearance timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
        modified timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
        hash character varying GENERATED ALWAYS AS (%s) STORED,
        %s,
        PRIMARY KEY (id, entity_id)
        )',
        attribute_directory.to_table_name($1),
        attribute_directory.hash_query($1),
        array_to_string(attribute_directory.column_specs($1), ',')
    ),
    format(
        'CREATE INDEX ON attribute_history.%I (id)',
        attribute_directory.to_table_name($1)
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
        'SELECT create_distributed_table(''attribute_history.%I'', ''entity_id'')',
        attribute_directory.to_table_name($1)
    )
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."create_history_table"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action($1, attribute_directory.create_history_table_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_history_table_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'DROP TABLE attribute_history.%I',
    attribute_directory.to_table_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."drop_history_table"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action($1, attribute_directory.drop_history_table_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_staging_table_sql"(attribute_directory.attribute_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE UNLOGGED TABLE attribute_staging.%I (%s)',
        attribute_directory.to_table_name($1),
        array_to_string(attribute_directory.column_specs($1), ',')
    ),
    format(
        'CREATE INDEX ON attribute_staging.%I USING btree (entity_id, timestamp)',
        attribute_directory.to_table_name($1)
    ),
    format(
        'ALTER TABLE attribute_staging.%I OWNER TO minerva_writer',
        attribute_directory.to_table_name($1)
    ),
    format(
        'SELECT create_distributed_table(''attribute_staging.%I'', ''entity_id'')',
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


CREATE FUNCTION "attribute_directory"."drop_staging_table_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'DROP TABLE attribute_staging.%I',
    attribute_directory.to_table_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."drop_staging_table"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.drop_staging_table_sql($1)
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


CREATE FUNCTION "attribute_directory"."last_history_id"("attribute_store_id" integer)
    RETURNS integer
AS $$
DECLARE
  result integer;
BEGIN
  EXECUTE FORMAT(
    'SELECT COALESCE(MAX(id), 0) FROM attribute_history.%I', 
    attribute_directory.to_table_name(attribute_directory.get_attribute_store($1))
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "attribute_directory"."update_compacted"("attribute_store_id" integer, "compacted" integer)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
UPDATE attribute_directory.attribute_store_compacted
  SET compacted = greatest(compacted, $2)
  WHERE attribute_store_id = $1
RETURNING attribute_store_compacted;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."store_compacted"("attribute_store_id" integer, "compacted" integer)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
INSERT INTO attribute_directory.attribute_store_compacted (attribute_store_id, compacted)
VALUES ($1, $2)
RETURNING attribute_store_compacted;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."mark_compacted"("attribute_store_id" integer, "compacted" integer)
    RETURNS attribute_directory.attribute_store_compacted
AS $$
SELECT COALESCE(attribute_directory.update_compacted($1, $2), attribute_directory.store_compacted($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."mark_modified"("attribute_store_id" integer, "modified" timestamp with time zone)
    RETURNS attribute_directory.attribute_store_modified
AS $$
INSERT INTO attribute_directory.attribute_store_modified (attribute_store_id, modified)
VALUES ($1, $2)
ON CONFLICT (attribute_store_id) DO UPDATE
SET modified = EXCLUDED.modified
RETURNING attribute_store_modified;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."mark_modified"("attribute_store_id" integer)
    RETURNS attribute_directory.attribute_store_modified
AS $$
SELECT attribute_directory.mark_modified($1, now())
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_hash_function"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
BEGIN
    EXECUTE format('DROP FUNCTION attribute_history.values_hash(attribute_history.%I)', attribute_directory.to_table_name($1));

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


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
VALUES ((directory.name_to_data_source($1)).id, (directory.name_to_entity_type($2)).id);
SELECT * FROM attribute_directory.attribute_store WHERE data_source_id = (directory.name_to_data_source($1)).id
  AND entity_type_id = (directory.name_to_entity_type($2)).id;
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
    RETURNS integer
AS $$
DECLARE
    table_name name;
    columns_part text;
    set_columns_part text;
    default_columns text[];
    row_count integer;
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

    GET DIAGNOSTICS row_count = ROW_COUNT;

    PERFORM attribute_directory.mark_modified($1.id);

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

    PERFORM attribute_directory.mark_modified($1.id);

    RETURN row_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."transfer_staged"("attribute_store_id" integer)
    RETURNS integer
AS $$
DECLARE
  attribute attribute_directory.attribute_store;
BEGIN
  SELECT * FROM attribute_directory.attribute_store WHERE id = $1 INTO attribute;
  RETURN attribute_directory.transfer_staged(attribute);
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
        '    id integer,'
        '    first_appearance timestamp with time zone,'
        '    modified timestamp with time zone,'
        '    hash text,'
        '    %s'
        ')',
        attribute_directory.compacted_tmp_table_name($1),
        array_to_string(attribute_directory.column_specs($1), ',')
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
    ),
    format(
        'SELECT create_distributed_table(''attribute_history.%I'', ''entity_id'')',
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


CREATE FUNCTION "attribute_directory"."drop_compacted_tmp_table_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'DROP TABLE attribute_history.%I',
    attribute_directory.compacted_tmp_table_name($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_compacted_tmp_table"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.drop_compacted_tmp_table_sql($1)
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
        ARRAY['rl.id', 'rl.entity_id', 'rl.start AS timestamp', 'rl."end"', 'rl.first_appearance', 'rl.modified', 'history.hash'] || array_agg(quote_ident(name)),
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


CREATE FUNCTION "attribute_directory"."insert_into_compacted_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT FORMAT(
  'INSERT INTO attribute_directory.attribute_store_compacted '
  '(attribute_store_id, compacted) '
  'VALUES (%s, 0)',
  $1.id
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."remove_from_compacted_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT FORMAT(
  'DELETE FROM attribute_directory.attribute_store_compacted '
  'WHERE attribute_store_id = %s',
  $1.id
);
  
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."insert_into_compacted"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.insert_into_compacted_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."remove_from_compacted"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.remove_from_compacted_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."requires_compacting"("attribute_store_id" integer)
    RETURNS bool
AS $$
DECLARE
  result bool;
BEGIN
  SELECT attribute_directory.last_history_id($1) > compacted
    FROM attribute_directory.attribute_store_compacted
    WHERE attribute_store_compacted.attribute_store_id = $1
  INTO result;
  RETURN COALESCE(result, attribute_directory.last_history_id($1) > 0);
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "attribute_directory"."requires_compacting"(attribute_directory.attribute_store)
    RETURNS bool
AS $$
SELECT attribute_directory.requires_compacting($1.id);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."last_compacted"("attribute_store_id" integer)
    RETURNS integer
AS $$
SELECT COALESCE(compacted, 0) FROM attribute_directory.attribute_store_compacted WHERE attribute_store_id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."compact"(attribute_directory.attribute_store, "max_compacting" integer)
    RETURNS attribute_directory.attribute_store
AS $$
DECLARE
    last_to_compact integer;
    table_name name := attribute_directory.to_table_name($1);
    compacted_tmp_table_name name := table_name || '_compacted_tmp';
    compacted_view_name name := attribute_directory.compacted_view_name($1);
    default_columns text[] := ARRAY['id', 'entity_id', 'timestamp', '"end"', 'first_appearance', 'modified'];
    extended_default_columns text[] := ARRAY[
        format('%I.id', compacted_view_name), format('%I.entity_id', compacted_view_name), 'timestamp', '"end"', 'first_appearance', 'modified'
    ];
    attribute_columns text[];
    columns_part text;
    extended_columns_part text;
    row_count integer;
BEGIN
    SELECT attribute_directory.last_compacted($1.id) + max_compacting INTO last_to_compact;
    IF max_compacting = 0 OR attribute_directory.last_history_id($1.id) < last_to_compact
        THEN last_to_compact = attribute_directory.last_history_id($1.id);
    END IF;
    
    SELECT array_agg(quote_ident(name)) INTO attribute_columns
        FROM attribute_directory.attribute
        WHERE attribute_store_id = $1.id;
       
    columns_part = array_to_string(default_columns || attribute_columns, ',');
    extended_columns_part = array_to_string(extended_default_columns || attribute_columns, ',');
    EXECUTE format(
        'TRUNCATE attribute_history.%I',
        compacted_tmp_table_name
    );

    EXECUTE format(
        'WITH to_compact AS '
           '(SELECT entity_id, MIN(id) AS first_id FROM attribute_history.%I '
           'WHERE id > attribute_directory.last_compacted(%s) GROUP BY entity_id) '
        'INSERT INTO attribute_history.%I(%s) '
             'SELECT %s FROM attribute_history.%I '
             'JOIN to_compact '
             'ON %I.entity_id = to_compact.entity_id '
             'WHERE first_id <= %s;',
        table_name,
        $1.id,
        compacted_tmp_table_name, columns_part,
        extended_columns_part,
        compacted_view_name,
        compacted_view_name,
        last_to_compact
    );


    EXECUTE format(
        'UPDATE attribute_history.%I SET modified = now()',
        compacted_tmp_table_name
    );

    GET DIAGNOSTICS row_count = ROW_COUNT;

    RAISE NOTICE 'compacted % rows', row_count;

    EXECUTE format(
        'UPDATE attribute_history.%I '
        'SET "end" = "timestamp" '
        'WHERE "end" IS NULL;',
        table_name
    );

    EXECUTE format(
        'DELETE FROM attribute_history.%I history '
        'USING attribute_history.%I tmp '
        'WHERE '
             'history.entity_id = tmp.entity_id AND '
             'history.timestamp >= tmp.timestamp AND '
             'history.timestamp <= tmp."end";',
        table_name, compacted_tmp_table_name
    );

    columns_part = array_to_string(
        ARRAY['id', 'entity_id', 'timestamp', '"end"', 'first_appearance', 'modified'] || attribute_columns,
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

    PERFORM attribute_directory.mark_modified($1.id);

    PERFORM attribute_directory.mark_compacted($1.id, last_to_compact);

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "attribute_directory"."compact"(attribute_directory.attribute_store, "max_compacting" integer) IS 'Remove at most max_compacting subsequent records with duplicate attribute values and update the modified of the first';


CREATE FUNCTION "attribute_directory"."compact"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_directory.compact($1, 0);
$$ LANGUAGE sql VOLATILE;

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
        'INSERT INTO attribute_history.%I (id) '
        'SELECT id '
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
RETURNS TABLE(id integer)
AS $$
    BEGIN
        RETURN QUERY SELECT DISTINCT ON (entity_id) s.id
            FROM attribute_history.%I s
            WHERE timestamp <= $1
            ORDER BY entity_id, timestamp DESC;
    END;
$$ LANGUAGE plpgsql STABLE',
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
BEGIN
  RETURN public.action(
    $1,
    attribute_directory.create_at_func_ptr_sql($1)
  );
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_at_func_ptr_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION attribute_history.%I(timestamp with time zone)',
    attribute_directory.at_ptr_function_name($1)
)
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "attribute_directory"."drop_at_func_ptr"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.drop_at_func_ptr_sql($1)
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_entity_at_func_ptr_sql"(attribute_directory.attribute_store)
    RETURNS text[]
AS $function$
SELECT ARRAY[
    format(
        'CREATE FUNCTION attribute_history.%I(entity_id integer, timestamp with time zone)
RETURNS integer
AS $$
  BEGIN
    RETURN a.id
    FROM
        attribute_history.%I a
    WHERE a.timestamp <= $2 AND a.entity_id = $1
    ORDER BY a.timestamp DESC LIMIT 1;
  END;
$$ LANGUAGE plpgsql STABLE',
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
BEGIN
  RETURN public.action(
    $1,
    attribute_directory.create_entity_at_func_ptr_sql($1)
  );
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_entity_at_func_ptr_sql"(attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION attribute_history.%I(entity_id integer, timestamp with time zone)',
    attribute_directory.at_ptr_function_name($1)
)
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_entity_at_func_ptr"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    attribute_directory.drop_entity_at_func_ptr_sql($1)
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
          BEGIN
            RETURN QUERY SELECT a.*
            FROM
                attribute_history.%I a
            JOIN
                attribute_HISTORY.%I($1) at
            ON at.id = a.id;
          END;
        $$ LANGUAGE plpgsql STABLE;',
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


CREATE FUNCTION "attribute_directory"."drop_at_func"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    format(
        'DROP FUNCTION attribute_history.%I(timestamp with time zone)',
        attribute_directory.at_function_name($1)
    )
);
$$ LANGUAGE sql VOLATILE;


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
DECLARE
  result attribute_history.%I;
BEGIN
  SELECT *
    FROM attribute_history.%I
    WHERE id = attribute_history.%I($1, $2)
  INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;',
            attribute_directory.at_function_name($1),
            attribute_directory.to_table_name($1),
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
BEGIN
  RETURN public.action(
    $1,
    attribute_directory.create_entity_at_func_sql($1)
  );
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_dependees"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_directory.create_staging_new_view($1);
SELECT attribute_directory.create_staging_modified_view($1);
SELECT attribute_directory.create_curr_ptr_view($1);
SELECT attribute_directory.create_curr_view($1);
SELECT attribute_directory.create_compacted_view($1);
SELECT attribute_directory.insert_into_compacted($1);
SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_dependees"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT attribute_directory.drop_compacted_view($1);
SELECT attribute_directory.drop_curr_view($1);
SELECT attribute_directory.drop_curr_ptr_view($1);
SELECT attribute_directory.drop_staging_modified_view($1);
SELECT attribute_directory.drop_staging_new_view($1);
SELECT attribute_directory.remove_from_compacted($1);
SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."update_data_type"(attribute_directory.attribute, "new_data_type" text)
    RETURNS attribute_directory.attribute
AS $$
UPDATE attribute_directory.attribute SET data_type = $2
  WHERE id = $1.id;
SELECT
    attribute_directory.create_dependees(
        attribute_directory.modify_column_type(
            attribute_directory.drop_dependees(attribute_store),
            $1.name,
            $2
        )
    )
FROM attribute_directory.attribute_store
WHERE id = $1.attribute_store_id;

SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."check_attribute_types"(attribute_directory.attribute_store, attribute_directory.attribute_descr[])
    RETURNS SETOF attribute_directory.attribute
AS $$
SELECT attribute_directory.update_data_type(attribute, n.data_type)
  FROM unnest($2) n
  JOIN attribute_directory.attribute
    ON attribute.name = n.name
  WHERE attribute.attribute_store_id = $1.id
    AND attribute.data_type <> trend_directory.greatest_data_type(n.data_type, attribute.data_type);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_hash"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    ARRAY[
        format('SELECT attribute_directory.drop_compacted_view(%s)', $1),
        format('SELECT attribute_directory.drop_curr_view(%s)', $1),
        format('SELECT attribute_directory.drop_run_length_view(%s)', $1),
        format('SELECT attribute_directory.drop_changes_view(%s)', $1),
        format('ALTER TABLE attribute_history.%I DROP COLUMN hash CASCADE', attribute_directory.attribute_store_to_char($1.id))
    ]
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."add_hash"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    ARRAY[
        format(
            'ALTER TABLE attribute_history.%I ADD COLUMN hash character varying GENERATED ALWAYS AS (%s) STORED',
            attribute_directory.attribute_store_to_char($1.id),
            attribute_directory.hash_query($1)
        ),
        format('SELECT attribute_directory.create_changes_view(%s)', $1),
        format('SELECT attribute_directory.create_run_length_view(%s)', $1),
        format('SELECT attribute_directory.create_compacted_view(%s)', $1),
        format('SELECT attribute_directory.create_curr_view(%s)', $1)
    ]
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_staging_dependees"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    ARRAY[
        format('SELECT attribute_directory.drop_staging_modified_view(%s)', $1),
        format('SELECT attribute_directory.drop_staging_new_view(%s)', $1)
    ]
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."add_staging_dependees"(attribute_directory.attribute_store)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    ARRAY[
        format('SELECT attribute_directory.create_staging_new_view(%s)', $1),
        format('SELECT attribute_directory.create_staging_modified_view(%s)', $1)
    ]
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."add_attribute_column"(attribute_directory.attribute_store, name, text)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    ARRAY[
        format('ALTER TABLE attribute_base.%I ADD COLUMN %I %s', attribute_directory.to_char($1), $2, $3),
        format('SELECT attribute_directory.drop_hash(%s::attribute_directory.attribute_store)', $1),
        format('ALTER TABLE attribute_history.%I ADD COLUMN %I %s', attribute_directory.to_char($1), $2, $3),
        format('SELECT attribute_directory.add_hash(%s::attribute_directory.attribute_store)', $1),
        format('ALTER TABLE attribute_history.%I ADD COLUMN %I %s', attribute_directory.compacted_tmp_table_name($1), $2, $3),
        format('SELECT attribute_directory.drop_staging_dependees(%s)', $1),
        format('ALTER TABLE attribute_staging.%I ADD COLUMN %I %s', attribute_directory.to_char($1), $2, $3),
        format('SELECT attribute_directory.add_staging_dependees(%s)', $1)
    ]
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."add_attribute_columns"(attribute_directory.attribute_store, attribute_directory.attribute[])
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    ARRAY[
        format('SELECT attribute_directory.drop_dependees(attribute_store) FROM attribute_directory.attribute_store WHERE id = %s', $1.id),
        format(
            'ALTER TABLE attribute_base.%I %s',
            attribute_directory.to_char($1),
            (SELECT array_to_string(array_agg(format('ADD COLUMN %I %s', attribute.name, attribute.data_type)), ',') FROM unnest($2) AS attribute)
        ),
        format('SELECT attribute_directory.create_dependees(attribute_store) FROM attribute_directory.attribute_store WHERE id = %s', $1.id)
    ]
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."create_attribute"(attribute_directory.attribute_store, name, text, text)
    RETURNS attribute_directory.attribute
AS $$
INSERT INTO attribute_directory.attribute(attribute_store_id, name, data_type, description)
VALUES ($1.id, $2, $3, $4);

SELECT attribute_directory.add_attribute_column($1, $2, $3);

SELECT attribute FROM attribute_directory.attribute WHERE attribute_store_id = $1.id AND name = $2;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."remove_attribute_column"(attribute_directory.attribute_store, name)
    RETURNS attribute_directory.attribute_store
AS $$
SELECT public.action(
    $1,
    ARRAY[
        format('SELECT attribute_directory.drop_hash(%s::attribute_directory.attribute_store)', $1),
        format('ALTER TABLE attribute_base.%I DROP COLUMN %I CASCADE', attribute_directory.to_char($1), $2),
        format('ALTER TABLE attribute_history.%I DROP COLUMN %I CASCADE', attribute_directory.to_char($1), $2),
        format('ALTER TABLE attribute_history.%I DROP COLUMN %I CASCADE', attribute_directory.compacted_tmp_table_name($1), $2),
        format('SELECT attribute_directory.add_hash(%s::attribute_directory.attribute_store)', $1),
        format('SELECT attribute_directory.drop_staging_dependees(%s)', $1),
        format('ALTER TABLE attribute_staging.%I DROP COLUMN %I CASCADE', attribute_directory.to_char($1), $2),
        format('SELECT attribute_directory.add_staging_dependees(%s)', $1)
    ]
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."drop_attribute"(attribute_directory.attribute_store, name)
    RETURNS attribute_directory.attribute_store
AS $$
DELETE FROM attribute_directory.attribute
WHERE attribute_store_id = $1.id AND name = $2;

SELECT attribute_directory.remove_attribute_column($1, $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."init"(attribute_directory.attribute)
    RETURNS attribute_directory.attribute
AS $$
SELECT public.action(
    $1,
    format('SELECT attribute_directory.add_attribute_column(attribute_store, %L, %L) FROM attribute_directory.attribute_store WHERE id = %s', $1.name, $1.data_type, $1.attribute_store_id)
)
$$ LANGUAGE sql VOLATILE;


CREATE CAST ("attribute_directory"."attribute_store" AS text)
  WITH FUNCTION "attribute_directory"."to_char"("attribute_directory"."attribute_store");


CREATE PROCEDURE "attribute_directory"."init"(attribute_directory.attribute_store)
AS $$
BEGIN
  -- Base table
  PERFORM attribute_directory.create_base_table($1);

  -- Dependent tables
  PERFORM attribute_directory.create_history_table($1);
  PERFORM attribute_directory.create_staging_table($1);
  PERFORM attribute_directory.create_compacted_tmp_table($1);

  -- Separate table
  PERFORM attribute_directory.create_curr_ptr_table($1);

  -- Other
  PERFORM attribute_directory.create_at_func_ptr($1);
  PERFORM attribute_directory.create_at_func($1);

  PERFORM attribute_directory.create_entity_at_func_ptr($1);
  PERFORM attribute_directory.create_entity_at_func($1);

  PERFORM attribute_directory.create_changes_view($1);

  PERFORM attribute_directory.create_run_length_view($1);

  PERFORM attribute_directory.create_dependees($1);

END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION "attribute_directory"."deinit"(attribute_directory.attribute_store)
    RETURNS void
AS $$
-- Other
SELECT attribute_directory.drop_dependees($1);

SELECT attribute_directory.drop_run_length_view($1);

SELECT attribute_directory.drop_changes_view($1);

SELECT attribute_directory.drop_entity_at_func($1);
SELECT attribute_directory.drop_entity_at_func_ptr($1);

SELECT attribute_directory.drop_at_func($1);
SELECT attribute_directory.drop_at_func_ptr($1);

SELECT attribute_directory.drop_curr_ptr_table($1);

-- Dependent tables
SELECT attribute_directory.drop_compacted_tmp_table($1);
SELECT attribute_directory.drop_staging_table($1);
SELECT attribute_directory.drop_history_table($1);

-- Base/parent table
SELECT attribute_directory.drop_base_table($1);
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


CREATE PROCEDURE "attribute_directory"."create_attribute_store"("data_source_name" text, "entity_type_name" text)
AS $$
BEGIN
  CALL attribute_directory.init(attribute_directory.define_attribute_store($1, $2));
END;
$$ LANGUAGE plpgsql;


CREATE PROCEDURE "attribute_directory"."create_attribute_store"("data_source_name" text, "entity_type_name" text, "attributes" attribute_directory.attribute_descr[])
AS $$
DECLARE
  store attribute_directory.attribute_store;
BEGIN
  SELECT * FROM attribute_directory.define_attribute_store($1, $2) INTO store;
  PERFORM attribute_directory.add_attributes(store, $3);
  CALL attribute_directory.init(store);
END;
$$ LANGUAGE plpgsql;


CREATE PROCEDURE "attribute_directory"."create_attribute_store"("data_source_id" integer, "entity_type_id" integer, "attributes" attribute_directory.attribute_descr[])
AS $$
CALL attribute_directory.init(
    attribute_directory.add_attributes(attribute_directory.define_attribute_store($1, $2), $3)
);
$$ LANGUAGE sql;


CREATE FUNCTION "attribute_directory"."delete_attribute_store"("attribute_store" attribute_directory.attribute_store)
    RETURNS void
AS $$
SELECT attribute_directory.deinit($1);
DELETE FROM attribute_directory.attribute_store WHERE id = $1.id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."delete_attribute_store"("name" text)
    RETURNS void
AS $$
DECLARE
  store attribute_directory.attribute_store;
BEGIN
  SELECT * FROM attribute_directory.attribute_store WHERE attribute_directory.attribute_store_to_char(attribute_store.id) = $1 INTO store;
  PERFORM attribute_directory.delete_attribute_store(store);
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "attribute_directory"."delete_attribute_store"("attribute_store_id" integer)
    RETURNS void
AS $$
DECLARE
  store attribute_directory.attribute_store;
BEGIN
  SELECT * FROM attribute_directory.attribute_store WHERE id = $1 INTO store;
  PERFORM attribute_directory.delete_attribute_store(store);
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "directory"."delete_entity_type"(directory.entity_type)
    RETURNS void
AS $$
SELECT attribute_directory.delete_attribute_store(s.id) FROM attribute_directory.attribute_store s WHERE s.entity_type_id = $1.id;
DELETE FROM directory.entity_type WHERE id = $1.id;
$$ LANGUAGE sql VOLATILE;


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


CREATE FUNCTION "attribute_directory"."view_to_attribute_staging_sql"("view" text, attribute_directory.attribute_store)
    RETURNS text
AS $$
SELECT format(
    'INSERT INTO attribute_staging.%1$I(%2$s) SELECT %2$s FROM %3$s',
    attribute_directory.to_table_name($2),
    array_to_string(ARRAY['entity_id', 'timestamp']::text[] || array_agg(quote_ident(attribute.name)), ', '),
    $1::regclass::text
)
FROM attribute_directory.attribute
WHERE attribute_store_id = $2.id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."stage_sample"(attribute_directory.sampled_view_materialization)
    RETURNS integer
AS $$
SELECT public.action_count(
    attribute_directory.view_to_attribute_staging_sql($1.src_view, attribute_store)
)
FROM attribute_directory.attribute_store
WHERE id = $1.attribute_store_id
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."materialize"(attribute_directory.sampled_view_materialization)
    RETURNS integer
AS $$
SELECT attribute_directory.stage_sample($1);

SELECT attribute_directory.transfer_staged(attribute_store)
FROM attribute_directory.attribute_store
WHERE id = $1.attribute_store_id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "attribute_directory"."modify_data_type"(attribute_directory.attribute)
    RETURNS attribute_directory.attribute
AS $$
DECLARE
  store attribute_directory.attribute_store;
BEGIN
  SELECT * FROM attribute_directory.attribute_store WHERE id = $1.attribute_store_id INTO store;
  RETURN public.action(
      $1,
      ARRAY[
          format('ALTER TABLE attribute_base.%I ALTER %I TYPE %s', attribute_directory.to_char(store), $1.name, $1.data_type),
          format('SELECT attribute_directory.drop_hash(%s::attribute_directory.attribute_store)', store),
          format('ALTER TABLE attribute_history.%I ALTER %I TYPE %s', attribute_directory.to_char(store), $1.name, $1.data_type),
          format('SELECT attribute_directory.add_hash(%s::attribute_directory.attribute_store)', store),
          format('ALTER TABLE attribute_history.%I ALTER %I TYPE %s', attribute_directory.compacted_tmp_table_name(store), $1.name, $1.data_type),
          format('SELECT attribute_directory.drop_staging_dependees(%s)', store),
          format('ALTER TABLE attribute_staging.%I ALTER %I TYPE %s', attribute_directory.to_char(store), $1.name, $1.data_type),
          format('SELECT attribute_directory.add_staging_dependees(%s)', store)
      ]
  );
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


CREATE TRIGGER update_attribute_type
  AFTER UPDATE ON "attribute_directory"."attribute"
  FOR EACH ROW
  EXECUTE PROCEDURE "attribute_directory"."update_data_type_on_change"();


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
  "id" serial NOT NULL,
  "data_source_id" integer,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "notification_directory"."notification_store" IS 'Describes notification_stores. Each notification_store maps to a set of
tables and functions that can store and manage notifications of a certain
type. These corresponding tables and functions are created automatically
for each notification_store. Because each notification_store maps
one-on-one to a data_source, the name of the notification_store is the
same as that of the data_source. Use the create_notification_store
function to create new notification_stores.';

CREATE UNIQUE INDEX "uniqueness" ON "notification_directory"."notification_store" USING btree (data_source_id);

GRANT SELECT ON TABLE "notification_directory"."notification_store" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "notification_directory"."notification_store" TO minerva_writer;



CREATE TABLE "notification_directory"."attribute"
(
  "id" serial NOT NULL,
  "notification_store_id" integer,
  "name" name NOT NULL,
  "data_type" name NOT NULL,
  "description" varchar NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "notification_directory"."attribute" IS 'Describes attributes of notification stores. An attribute of a
notification store is an attribute that each notification stored in that
notification store has. An attribute corresponds directly to a column in
the main notification store table';

GRANT SELECT ON TABLE "notification_directory"."attribute" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "notification_directory"."attribute" TO minerva_writer;



CREATE TABLE "notification_directory"."notification_set_store"
(
  "id" serial NOT NULL,
  "name" name NOT NULL,
  "notification_store_id" integer,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "notification_directory"."notification_set_store" IS 'Describes notification_set_stores. A notification_set_store can hold information over sets of notifications that are related to each other.';

GRANT SELECT ON TABLE "notification_directory"."notification_set_store" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "notification_directory"."notification_set_store" TO minerva_writer;



CREATE TABLE "notification_directory"."set_attribute"
(
  "id" serial NOT NULL,
  "notification_set_store_id" integer,
  "name" name NOT NULL,
  "data_type" name NOT NULL,
  "description" varchar NOT NULL,
  PRIMARY KEY (id)
);

COMMENT ON TABLE "notification_directory"."set_attribute" IS 'Describes attributes of notification_set_stores. A set_attribute of a
notification_set_store is an attribute that each notification set has. A
set_attribute corresponds directly to a column in the main
notification_set_store table.';

GRANT SELECT ON TABLE "notification_directory"."set_attribute" TO minerva;

GRANT INSERT,UPDATE,DELETE ON TABLE "notification_directory"."set_attribute" TO minerva_writer;



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


CREATE FUNCTION "notification_directory"."notification_store_to_char"("notification_store_id" integer)
    RETURNS text
AS $$
SELECT data_source.name
  FROM notification_directory.notification_store
    JOIN directory.data_source ON data_source.id = notification_store.data_source_id
  WHERE notification_store.id = $1;
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
            '  %s'
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


CREATE FUNCTION "notification_directory"."create_staging_table_sql"(notification_directory.notification_store)
    RETURNS text[]
AS $$
SELECT ARRAY[
        format(
            'CREATE TABLE %I.%I ('
            '  entity_id integer NOT NULL,'
            '  "timestamp" timestamp with time zone NOT NULL'
            '  %s'
            ');',
            notification_directory.notification_store_schema(),
            notification_directory.staging_table_name($1),
            (SELECT array_to_string(array_agg(format(',%I %s', name, data_type)), ' ') FROM notification_directory.attribute WHERE notification_store_id = $1.id)
        ),
        format(
            'ALTER TABLE %I.%I OWNER TO minerva_writer;',
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


CREATE FUNCTION "notification_directory"."drop_staging_table_sql"(notification_directory.notification_store)
    RETURNS text
AS $$
SELECT format(
    'DROP TABLE %I.%I',
    notification_directory.notification_store_schema(),
    notification_directory.staging_table_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "notification_directory"."drop_staging_table"(notification_directory.notification_store)
    RETURNS notification_directory.notification_store
AS $$
SELECT public.action($1, notification_directory.drop_staging_table_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."initialize_notification_store"(notification_directory.notification_store)
    RETURNS notification_directory.notification_store
AS $$
SELECT notification_directory.create_table($1);
SELECT notification_directory.create_staging_table($1);
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


CREATE FUNCTION "notification_directory"."delete_notification_store"(notification_directory.notification_store)
    RETURNS void
AS $$
BEGIN
    EXECUTE format(
        'DROP TABLE IF EXISTS %I.%I CASCADE',
        notification_directory.notification_store_schema(),
        notification_directory.staging_table_name($1)
    );

    EXECUTE format(
        'DROP TABLE IF EXISTS %I.%I CASCADE',
        notification_directory.notification_store_schema(),
        notification_directory.table_name($1)
    );

    DELETE FROM notification_directory.notification_store WHERE id = $1.id;
END;
$$ LANGUAGE plpgsql VOLATILE;


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


CREATE FUNCTION "notification_directory"."delete_notification_set_store"(notification_directory.notification_set_store)
    RETURNS void
AS $$
BEGIN
    EXECUTE format(
        'DROP TABLE IF EXISTS %I.%I',
        notification_directory.notification_store_schema(),
        $1.name || '_link'
    );

    EXECUTE format(
        'DROP TABLE IF EXISTS %I.%I',
        notification_directory.notification_store_schema(),
        $1.name
    );

    DELETE FROM notification_directory.notification_set_store WHERE id = $1.id;
END;
$$ LANGUAGE plpgsql VOLATILE;


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
SELECT public.action(
    $1,
    notification_directory.add_attribute_column_sql(
        notification_directory.table_name(notification_store),
        $1
    )
)
FROM notification_directory.notification_store WHERE id = $1.notification_store_id;

SELECT public.action(
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


CREATE FUNCTION "directory"."cleanup_on_data_source_delete"("data_source_id" integer)
    RETURNS void
AS $$
SELECT attribute_directory.delete_attribute_store(s.id) FROM attribute_directory.attribute_store s WHERE s.data_source_id = $1;
DELETE FROM notification_directory.notification_store WHERE data_source_id = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "directory"."delete_data_source"(text)
    RETURNS directory.data_source
AS $$
SELECT directory.cleanup_on_data_source_delete(s.id) FROM directory.data_source s WHERE s.name = $1;
DELETE FROM directory.data_source WHERE name = $1 RETURNING *;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION "virtual_entity"."update"("name" name)
    RETURNS integer
AS $$
DECLARE
    result integer;
BEGIN
    EXECUTE format(
        'SELECT count(entity.%I(v.name)) FROM virtual_entity.%I v LEFT JOIN entity.%I e ON e.name = v.name WHERE e.name IS NULL',
        format('to_%s', name), name, name
    ) INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TYPE "trigger"."threshold_def" AS (
  "name" name,
  "data_type" name
);



CREATE TYPE "trigger"."kpi_def" AS (
  "name" name,
  "data_type" name
);



CREATE TYPE "trigger"."notification" AS (
  "entity_id" integer,
  "timestamp" timestamp with time zone,
  "weight" integer,
  "details" text,
  "data" json
);



CREATE TABLE "trigger"."rule"
(
  "id" serial NOT NULL,
  "name" name,
  "notification_store_id" integer,
  "granularity" interval,
  "default_interval" interval,
  "enabled" bool NOT NULL DEFAULT false,
  "description" text,
  PRIMARY KEY (id)
);

CREATE UNIQUE INDEX "rule_name_key" ON "trigger"."rule" USING btree (name);

GRANT SELECT ON TABLE "trigger"."rule" TO minerva;

GRANT UPDATE ON TABLE "trigger"."rule" TO minerva_writer;



CREATE TABLE "trigger"."rule_trend_store_link"
(
  "rule_id" integer NOT NULL,
  "trend_store_part_id" integer NOT NULL,
  "timestamp_mapping_func" regprocedure NOT NULL,
  PRIMARY KEY (rule_id, trend_store_part_id)
);

COMMENT ON TABLE "trigger"."rule_trend_store_link" IS 'Stores the dependencies between a trigger rule and its source table trend store parts. Multiple levels of views and functions may exist between a materialization and its source table trend stores. These intermediate views and functions are not registered here, but only the table trend stores containing the actual source data used in the trigger rule.
The timestamp_mapping_func column stores the function to map a timestamp of the source (trend_store_part) to a timestamp of the target notification.
';

COMMENT ON COLUMN "trigger"."rule_trend_store_link"."rule_id" IS 'Reference to a trigger rule.';

COMMENT ON COLUMN "trigger"."rule_trend_store_link"."trend_store_part_id" IS 'Reference to a trend_store_part that is a source of the materialization referenced by materialization_id.
';

COMMENT ON COLUMN "trigger"."rule_trend_store_link"."timestamp_mapping_func" IS 'The function that maps timestamps in the source table to timestamps in the materialized data. For example, for a view for an hour aggregation from 15 minute granularity data will need to map 4 timestamps in the source to 1 timestamp in the resulting data.
';



CREATE TABLE "trigger"."exception_base"
(
  "id" serial NOT NULL,
  "entity_id" integer,
  "start" timestamp with time zone,
  "expires" timestamp with time zone,
  "created" timestamp with time zone DEFAULT now()
);

GRANT SELECT ON TABLE "trigger"."exception_base" TO minerva;

GRANT UPDATE ON TABLE "trigger"."exception_base" TO minerva_writer;



CREATE TABLE "trigger"."rule_tag_link"
(
  "rule_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY (rule_id, tag_id)
);

GRANT SELECT ON TABLE "trigger"."rule_tag_link" TO minerva;

GRANT UPDATE ON TABLE "trigger"."rule_tag_link" TO minerva_writer;



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


CREATE FUNCTION "trigger"."notification_view_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_notification')::name;
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
    format('ALTER VIEW trigger_rule.%I OWNER TO minerva_admin', trigger.rule_view_name($1))
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


CREATE FUNCTION "trigger"."kpi_function_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_kpi')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."get_kpi_view_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT pg_get_viewdef(oid, true)
FROM pg_class
WHERE relname = trigger.kpi_view_name($1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."kpi_view_sql"(trigger.rule, "sql" text)
    RETURNS text
AS $$
SELECT format(
    'DROP VIEW IF EXISTS trigger_rule.%I',
    "trigger".kpi_view_name($1)
);
SELECT format(
    'CREATE VIEW trigger_rule.%I AS %s',
    "trigger".kpi_view_name($1), $2
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_kpi_view_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP VIEW trigger_rule.%I CASCADE', "trigger".kpi_view_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_kpi_function_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION trigger_rule.%I(timestamp with time zone) CASCADE', "trigger".kpi_function_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_kpi_view_sql"(trigger.rule, "sql" text)
    RETURNS text[]
AS $$
SELECT ARRAY[
    trigger.kpi_view_sql($1, $2),
    format('ALTER VIEW trigger_rule.%I OWNER TO minerva_admin', trigger.kpi_view_name($1))
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_kpi_view"(trigger.rule, "sql" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, trigger.create_kpi_view_sql($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."kpi_type_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_kpi')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."details_type_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_details')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."notification_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_create_notification')::name;
$$ LANGUAGE sql IMMUTABLE;


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
SELECT pg_get_viewdef(oid, true) FROM pg_class WHERE relname = trigger.with_threshold_view_name($1);
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
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."drop_with_threshold_view_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP VIEW trigger_rule.%I', trigger.with_threshold_view_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."get_weight_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = trigger.weight_fn_name($1);
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
  trigger.details_type_name($1),
  $2
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_weight_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION trigger_rule.%I(trigger_rule.%I)',
    trigger.weight_fn_name($1),
    trigger.details_type_name($1)
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."exception_weight_table_sql"(trigger.rule)
    RETURNS text
AS $function$
SELECT format(
    $$CREATE TABLE trigger_rule.%I
    (
        id serial,
        entity_id integer,
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
SELECT format(
    'DROP TYPE IF EXISTS trigger_rule.%I',
    trigger.notification_type_name($1)
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_notification_type"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT trigger.action(
    $1,
    trigger.create_notification_type_sql($1)
);
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


CREATE FUNCTION "trigger"."get_exception_threshold_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_get_exception_threshold')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_exception_threshold_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_create_exception_threshold')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."get_or_create_exception_threshold_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_get_or_create_exception_threshold')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."change_exception_threshold_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_add_or_change_threshold_exception')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."get_exception_threshold_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
  'CREATE OR REPLACE FUNCTION trigger_rule.%I(entity integer) RETURNS trigger_rule.%I AS $fn$%s$fn$ LANGUAGE sql VOLATILE',
  trigger.get_exception_threshold_fn_name($1),
  trigger.exception_threshold_table_name($1),
  format(
    'SELECT * FROM trigger_rule.%I WHERE entity_id = entity;',
    trigger.exception_threshold_table_name($1)
  )
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_exception_threshold_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
  'CREATE OR REPLACE FUNCTION trigger_rule.%I(entity integer) RETURNS trigger_rule.%I AS $fn$%s$fn$ LANGUAGE sql VOLATILE',
  trigger.create_exception_threshold_fn_name($1),
  trigger.exception_threshold_table_name($1),
  format(
    'INSERT INTO trigger_rule.%I(entity_id) VALUES ($1) RETURNING *;',
    trigger.exception_threshold_table_name($1)
  )
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."get_or_create_exception_threshold_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
  'CREATE OR REPLACE FUNCTION trigger_rule.%I(entity integer) RETURNS trigger_rule.%I AS $fn$%s$fn$ LANGUAGE sql VOLATILE',
  trigger.get_or_create_exception_threshold_fn_name($1),
  trigger.exception_threshold_table_name($1),
  format('SELECT COALESCE(trigger_rule.%I($1), trigger_rule.%I($1));',
     trigger.get_exception_threshold_fn_name($1),
     trigger.create_exception_threshold_fn_name($1)
     )
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_change_exception_threshold_fn_sql"(trigger.rule, trigger.threshold_def[])
    RETURNS text
AS $$
SELECT format(
  'CREATE OR REPLACE FUNCTION trigger_rule.%I(entity integer, new_start timestamp with time zone, new_expires timestamp with time zone, %s) RETURNS VOID AS $fn$%s$fn$ LANGUAGE sql VOLATILE',
  trigger.change_exception_threshold_fn_name($1),
  string_agg(threshold.name || '_new ' || threshold.data_type, ', '),
  format(
    'SELECT trigger_rule.%I(entity); '
    'UPDATE trigger_rule.%I SET (start, expires, %s) = (new_start, new_expires, %s) WHERE entity_id = entity;',
    trigger.get_or_create_exception_threshold_fn_name($1),
    trigger.exception_threshold_table_name($1),
    string_agg(threshold.name, ', '),
    string_agg(threshold.name || '_new', ', ')
  )
) FROM unnest($2) threshold;
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
    'DROP VIEW IF EXISTS  trigger_rule.%I',
    trigger.threshold_view_name($1)
));
SELECT trigger.action($1, format(
    'CREATE VIEW trigger_rule.%I AS '
    'SELECT %s',
    trigger.threshold_view_name($1),
    $2
));
SELECT trigger.action($1, format(
    'ALTER VIEW trigger_rule.%I OWNER TO minerva_admin',
    trigger.threshold_view_name($1)
));

SELECT $1;
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION "trigger"."create_set_thresholds_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    $def$CREATE OR REPLACE FUNCTION trigger_rule.%I(%s)
    RETURNS integer AS
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
SELECT public.action(
    $1,
    ARRAY[
        trigger.weight_fn_sql($1, $2),
        format(
            'ALTER FUNCTION trigger_rule.%I(trigger_rule.%I) OWNER TO minerva_admin',
            trigger.weight_fn_name($1), trigger.details_type_name($1)
        )
    ]
);
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
        notification_directory.create_notification_store($1, ARRAY[
            ('created', 'timestamp with time zone', 'time of notification creation'),
            ('rule_id', 'integer', 'source rule for this notification'),
            ('weight', 'integer', 'weight/importance of the notification'),
            ('details', 'text', 'extra information')
        ]::notification_directory.attr_def[])
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
INSERT INTO notification.%I(entity_id, timestamp, created, rule_id, weight, details, data)
SELECT staging.entity_id, staging.timestamp, staging.created, staging.rule_id, staging.weight, staging.details, staging.data
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
INSERT INTO notification.%I(entity_id, timestamp, created, rule_id, weight, details, data)
(SELECT entity_id, timestamp, now(), $1, weight, details, data FROM trigger_rule.%I($2) WHERE data IS NOT NULL)
$query$,
        notification_directory.staging_table_name($2), trigger.notification_fn_name($1)
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


CREATE FUNCTION "trigger"."with_threshold_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_with_threshold')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."kpi_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_kpi')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."fingerprint_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_fingerprint')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."rule_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT $1.name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."runnable_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_runnable')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."notification_message_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_notification_message')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."notification_data_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_notification_data')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_kpi_type_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP TYPE IF EXISTS trigger_rule.%I CASCADE;',
    trigger.kpi_type_name($1)
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_details_type_sql"(trigger.rule, trigger.threshold_def[])
    RETURNS text
AS $$
SELECT format(
    'CREATE TYPE trigger_rule.%I AS ('
    '%s'
    ');',
    trigger.details_type_name($1),
    array_to_string(
        array_agg(format('%I %s', (c.col).name, (c.col).data_type)),
        ','
    )
) FROM (
    SELECT unnest(
        ARRAY[
            ('entity_id', 'integer'),
            ('timestamp', 'timestamp with time zone')
        ]::trigger.threshold_def[]
    ) AS col
    UNION ALL
    SELECT (kpi.name, kpi.data_type)::trigger.threshold_def AS col
    FROM trigger.get_kpi_defs($1) kpi
    UNION ALL
    SELECT unnest($2) AS col
) c;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."drop_details_type_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP TYPE IF EXISTS trigger_rule.%I CASCADE;',
    trigger.details_type_name($1)
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_details_type"(trigger.rule, trigger.threshold_def[])
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.create_details_type_sql($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."drop_details_type"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.drop_details_type_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_dummy_thresholds"(trigger.rule, trigger.threshold_def[])
    RETURNS trigger.rule
AS $$
SELECT trigger.set_thresholds(
    $1,
    array_to_string(array_agg(format('NULL::%s %I', threshold.data_type, threshold.name)), ', ')
) FROM unnest($2) threshold;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_exception_threshold_table_sql"(trigger.rule, trigger.threshold_def[])
    RETURNS text
AS $$
SELECT format(
    'CREATE TABLE trigger_rule.%I(%s);',
    trigger.exception_threshold_table_name($1),
    array_to_string(col_def, ',')
)
FROM (
    SELECT
        ARRAY[
            'id serial',
            'entity_id integer',
            'created timestamp with time zone default now()',
            'start timestamp with time zone',
            'expires timestamp with time zone',
            'remark text'
        ]::text[] ||
        array_agg(quote_ident(threshold.name) || ' ' || threshold.data_type) AS col_def
    FROM unnest($2) threshold
) c;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_exception_threshold_table"(trigger.rule, trigger.threshold_def[])
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.create_exception_threshold_table_sql($1, $2));
SELECT public.action($1, trigger.get_exception_threshold_fn_sql($1));
SELECT public.action($1, trigger.create_exception_threshold_fn_sql($1));
SELECT public.action($1, trigger.get_or_create_exception_threshold_fn_sql($1));
SELECT public.action($1, trigger.create_change_exception_threshold_fn_sql($1, $2));
SELECT public.action($1, format('ALTER TABLE trigger_rule.%I OWNER TO minerva_admin', trigger.exception_threshold_table_name($1)));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."with_threshold_fn_sql_normal"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
$view$
SELECT %s
FROM trigger_rule.%I AS threshold, trigger_rule.%I($1) AS kpi
LEFT JOIN trigger_rule.%I exc ON
    exc.entity_id = kpi.entity_id AND
    exc.start <= timestamp AND
    exc.expires > timestamp
$view$,
    array_to_string(col_def, ','),
    trigger.threshold_view_name($1),
    trigger.kpi_fn_name($1),
    trigger.exception_threshold_table_name($1)
)
FROM (
    SELECT
        ARRAY['kpi.*']::text[] || array_agg(format('COALESCE(exc.%I, threshold.%I) AS %I', threshold.name, threshold.name, threshold.name)) AS col_def
    FROM trigger.get_threshold_defs($1) threshold
) c;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."with_threshold_fn_sql_no_thresholds"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'SELECT * FROM trigger_rule.%I($1)',
    trigger.kpi_fn_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."has_thresholds"(trigger.rule)
    RETURNS boolean
AS $$
SELECT EXISTS(
    SELECT 1
    FROM pg_class
    WHERE relname = trigger.threshold_view_name($1) AND relkind = 'v'
);
$$ LANGUAGE sql STABLE;

COMMENT ON FUNCTION "trigger"."has_thresholds"(trigger.rule) IS 'Return true if there is a view with thresholds for the specified rule';


CREATE FUNCTION "trigger"."with_threshold_fn_sql"(trigger.rule)
    RETURNS text
AS $$
--SELECT CASE WHEN trigger.has_thresholds($1) THEN
SELECT CASE WHEN true THEN
    trigger.with_threshold_fn_sql_normal($1)
ELSE
    trigger.with_threshold_fn_sql_no_thresholds($1)
END;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_with_threshold_fn"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT public.action(
    $1,
    ARRAY[
        format(
            'CREATE OR REPLACE FUNCTION trigger_rule.%I(timestamp with time zone) RETURNS SETOF trigger_rule.%I AS $fn$%s$fn$ LANGUAGE sql STABLE',
            trigger.with_threshold_fn_name($1),
            trigger.details_type_name($1),
            trigger.with_threshold_fn_sql($1)
        ),
        format(
            'ALTER FUNCTION trigger_rule.%I(timestamp with time zone) OWNER TO minerva_admin',
            trigger.with_threshold_fn_name($1)
        )
    ]
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."drop_with_threshold_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION trigger_rule.%I(timestamp with time zone)',
    trigger.with_threshold_fn_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."define_thresholds"(trigger.rule, trigger.threshold_def[])
    RETURNS trigger.rule
AS $$
SELECT trigger.create_details_type($1, $2);
SELECT CASE WHEN array_length($2, 1) > 0 THEN
    trigger.create_dummy_thresholds($1, $2)
END;
SELECT trigger.create_exception_threshold_table($1, $2);
SELECT CASE WHEN array_length($2, 1) > 0 THEN
    trigger.create_set_thresholds_fn($1)
END;
SELECT trigger.create_with_threshold_fn($1);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."notification_message_fn_sql"(trigger.rule, "expression" text)
    RETURNS text
AS $$
SELECT format(
'CREATE OR REPLACE FUNCTION trigger_rule.%I(trigger_rule.%I)
    RETURNS text
AS $function$
SELECT (%s)::text
$function$ LANGUAGE SQL IMMUTABLE',
    trigger.notification_message_fn_name($1),
    trigger.details_type_name($1),
    $2
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."drop_notification_message_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION trigger_rule.%I',
    trigger.notification_message_fn_name($1),
    trigger.details_type_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_notification_message_fn"(trigger.rule, "expression" text)
    RETURNS trigger.rule
AS $$
SELECT public.action(
    $1,
    ARRAY[
        trigger.notification_message_fn_sql($1, $2),
        format(
            'ALTER FUNCTION trigger_rule.%I(trigger_rule.%I) OWNER TO minerva_admin',
            trigger.notification_message_fn_name($1),
            trigger.details_type_name($1)
        )
    ]
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_dummy_notification_message_fn"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT trigger.create_notification_message_fn($1, quote_literal($1.name));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."define_notification_message"(name, "expression" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.create_notification_message_fn(trigger.get_rule($1), $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_notification_data_fn_sql"(trigger.rule, "expression" text)
    RETURNS text
AS $$
SELECT format(
'CREATE OR REPLACE FUNCTION trigger_rule.%I(trigger_rule.%I)
    RETURNS json
AS $function$
DECLARE
  data json;
BEGIN
SELECT (%s) INTO data;
RETURN data;
END;
$function$ LANGUAGE PLPGSQL STABLE',
    trigger.notification_data_fn_name($1),
    trigger.details_type_name($1),
    $2
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."drop_notification_data_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION trigger_rule.%I',
    trigger.notification_data_fn_name($1),
    trigger.details_type_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_notification_data_fn"(trigger.rule, "expression" text)
    RETURNS trigger.rule
AS $$
SELECT public.action(
    $1,
    ARRAY[
        trigger.create_notification_data_fn_sql($1, $2),
        format(
            'ALTER FUNCTION trigger_rule.%I(trigger_rule.%I) OWNER TO minerva_admin',
            trigger.notification_data_fn_name($1),
            trigger.details_type_name($1)
        )
    ]
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_dummy_notification_data_fn"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT trigger.create_notification_data_fn($1, format('''"{}"''::json', $1.name));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."define_notification_data"(name, "expression" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.create_notification_data_fn(trigger.get_rule($1), $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."rule_fn_sql"(trigger.rule, "where_clause" text)
    RETURNS text
AS $$
SELECT format(
    'SELECT * FROM trigger_rule.%I($1) WHERE %s;',
    trigger.with_threshold_fn_name($1), $2
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_rule_fn_sql"(trigger.rule, "rule_view_sql" text)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format(
        'CREATE OR REPLACE FUNCTION trigger_rule.%I(timestamp with time zone) RETURNS SETOF trigger_rule.%I AS $fn$ %s $fn$ LANGUAGE sql STABLE',
        trigger.rule_fn_name($1),
        trigger.details_type_name($1),
        $2
    ),
    format(
        'ALTER FUNCTION trigger_rule.%I(timestamp with time zone) OWNER TO minerva_admin',
        trigger.rule_fn_name($1)
    )
];
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_rule_fn"(trigger.rule, "rule_view_sql" text)
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.create_rule_fn_sql($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."drop_rule_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION trigger_rule.%I(timestamp with time zone)',
    trigger.rule_fn_name($1)
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."set_condition"(trigger.rule, "sql" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.create_rule_fn($1, trigger.rule_fn_sql($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."notification_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'CREATE OR REPLACE FUNCTION trigger_rule.%I(timestamp with time zone)
    RETURNS SETOF trigger.notification
AS $fn$
SELECT
    n.entity_id,
    n.timestamp,
    COALESCE(exc.weight, trigger_rule.%I(n)) AS weight,
    trigger_rule.%I(n) AS details,
    trigger_rule.%I(n) AS data
FROM trigger_rule.%I($1) AS n
LEFT JOIN trigger_rule.%I AS exc ON
    exc.entity_id = n.entity_id AND
    exc.start <= n.timestamp AND
    exc.expires > n.timestamp $fn$ LANGUAGE sql STABLE',
    trigger.notification_fn_name($1),
    trigger.weight_fn_name($1),
    trigger.notification_message_fn_name($1),
    trigger.notification_data_fn_name($1),
    $1.name,
    trigger.exception_weight_table_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_notification_fn_sql"(trigger.rule)
    RETURNS text[]
AS $$
SELECT ARRAY[
    trigger.notification_fn_sql($1),
    format('ALTER FUNCTION trigger_rule.%I(timestamp with time zone) OWNER TO minerva_admin', trigger.notification_fn_name($1))
];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_notification_fn"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.create_notification_fn_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."get_notification_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = trigger.notification_fn_name($1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."drop_notification_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION trigger_rule.%I(timestamp with time zone)', trigger.notification_fn_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_fingerprint_fn_sql"(trigger.rule, "fn_sql" text)
    RETURNS text
AS $$
SELECT format(
    $fn$CREATE OR REPLACE FUNCTION trigger_rule.%I(timestamp with time zone)
      RETURNS text
    AS $function$
      %s
    $function$ LANGUAGE sql STABLE$fn$,
    trigger.fingerprint_fn_name($1),
    $2
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_fingerprint_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT trigger.create_fingerprint_fn_sql(
    $1,
    $fn_body$SELECT now()::text;$fn_body$
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_fingerprint_fn"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.create_fingerprint_fn_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."drop_fingerprint_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION IF EXISTS trigger_rule.%I(timestamp with time zone)', trigger.fingerprint_fn_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_fingerprint_fn"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.drop_fingerprint_fn_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_runnable_fn_sql"(trigger.rule, "fn_body" text)
    RETURNS text
AS $$
SELECT format(
    $fn$CREATE OR REPLACE FUNCTION trigger_rule.%I(timestamp with time zone)
      RETURNS boolean
    AS $function$
    %s
    $function$ LANGUAGE sql STABLE$fn$,
    trigger.runnable_fn_name($1),
    $2
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_runnable_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT trigger.create_runnable_fn_sql($1, 'SELECT TRUE;');
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."create_runnable_fn"(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.create_runnable_fn_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."drop_runnable_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION trigger_rule.%I(timestamp with time zone)', trigger.runnable_fn_name($1));
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."set_runnable"(trigger.rule, "fn_sql" text)
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.create_runnable_fn_sql($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."setup_rule"(trigger.rule, trigger.threshold_def[])
    RETURNS trigger.rule
AS $$
SELECT trigger.define_thresholds($1, $2);
SELECT trigger.create_exception_weight_table($1);
SELECT trigger.create_dummy_default_weight($1);
SELECT trigger.create_dummy_notification_message_fn($1);
SELECT trigger.create_dummy_notification_data_fn($1);
SELECT trigger.set_condition($1, 'true');
SELECT trigger.create_notification_fn($1);
SELECT trigger.create_fingerprint_fn($1);
SELECT trigger.create_runnable_fn($1);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."create_rule"(text, trigger.threshold_def[])
    RETURNS trigger.rule
AS $$
SELECT trigger.setup_rule(trigger.define($1::name), $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "trigger"."cleanup_rule"(trigger.rule)
    RETURNS trigger.rule
AS $$
BEGIN
    EXECUTE trigger.drop_set_thresholds_fn_sql($1);
    EXECUTE trigger.drop_rule_fn_sql($1);
    EXECUTE trigger.drop_kpi_function_sql($1);
    EXECUTE trigger.drop_notification_fn_sql($1);
    EXECUTE trigger.drop_runnable_fn_sql($1);
    EXECUTE trigger.drop_fingerprint_fn_sql($1);
    EXECUTE trigger.drop_with_threshold_fn_sql($1);
    EXECUTE trigger.drop_weight_fn_sql($1);
    EXECUTE trigger.drop_notification_message_fn_sql($1);
    EXECUTE trigger.drop_exception_weight_table_sql($1);
    EXECUTE trigger.drop_thresholds_view_sql($1);
    EXECUTE trigger.drop_exception_threshold_table_sql($1);
    EXECUTE trigger.drop_notification_type_sql($1);
    EXECUTE trigger.drop_details_type_sql($1);
    EXECUTE trigger.drop_kpi_type_sql($1);

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "trigger"."delete_rule"(name)
    RETURNS bigint
AS $$
SELECT trigger.cleanup_rule(rule) FROM trigger.rule WHERE name = $1;
WITH deleted AS ( DELETE FROM trigger.rule WHERE name = $1 RETURNING * ) SELECT count(*) FROM deleted;
$$ LANGUAGE sql VOLATILE;


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


SELECT directory.create_entity_type('entity_set');


SELECT directory.create_data_source('minerva');


CALL attribute_directory.create_attribute_store(
  'minerva',
  'entity_set',
  ARRAY[
    ('name', 'text', ''),
    ('fullname', 'text', ''),
    ('group', 'text', ''),
    ('source_entity_type', 'text', ''),
    ('owner', 'text', ''),
    ('description', 'text', ''),
    ('last_update', 'text', '')
  ]::attribute_directory.attribute_descr[]
);


CREATE FUNCTION "relation_directory"."entity_set_exists"("owner" text, "name" text)
    RETURNS boolean
AS $$
DECLARE
  row_count integer;
BEGIN
  SELECT action_count(format(
    'SELECT * FROM attribute.minerva_entity_set '
    'WHERE owner = ''%s'' AND name = ''%s'';',
    $1,
    $2
  )) INTO row_count;
  RETURN CASE row_count
    WHEN 0 THEN false
    ELSE true
  END;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "relation_directory"."create_entity_set"("name" text, "group" text, "entity_type_name" text, "owner" text, "description" text)
    RETURNS attribute.minerva_entity_set
AS $$
DECLARE
  entity_id integer;
BEGIN
  EXECUTE FORMAT(
    'CREATE TABLE IF NOT EXISTS relation."%s->entity_set"('
    'source_id integer, '
    'target_id integer, '
    'PRIMARY KEY (source_id, target_id));',
    entity_type_name
  );
  PERFORM relation_directory.name_to_type(entity_type_name || '->entity_set');
  SELECT id FROM entity.to_entity_set(name || '_' || "group" || '_' || owner) INTO entity_id;
  INSERT INTO attribute_staging.minerva_entity_set(
      entity_id, timestamp, name, fullname, "group", source_entity_type, owner, description, last_update
    ) VALUES (
      entity_id,
      now(),
      name,
      name || '_' || "group" || '_' || owner,
      "group",
      entity_type_name,
      owner,
      description,
      CURRENT_DATE::text
    );
  PERFORM attribute_directory.transfer_staged(attribute_directory.get_attribute_store('minerva', 'entity_set'));
  PERFORM attribute_directory.materialize_curr_ptr(attribute_directory.get_attribute_store('minerva', 'entity_set'));
  RETURN es FROM attribute.minerva_entity_set es WHERE es.name = $1 AND es.owner = $4;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "relation_directory"."update_entity_set_attributes"("minerva_entity_set_id" integer)
    RETURNS void
AS $$
BEGIN
  INSERT INTO attribute_staging.minerva_entity_set(
    entity_id, timestamp, name, fullname, "group", source_entity_type, owner, description, last_update
  ) SELECT
    t.entity_id,
    now(),
    t.name,
    t.fullname,
    t."group",
    t.source_entity_type,
    t.owner,
    t.description,
    CURRENT_DATE::text
  FROM attribute.minerva_entity_set t
  WHERE t.id = $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "relation_directory"."get_entity_set_data"("name" text, "owner" text)
    RETURNS attribute.minerva_entity_set
AS $$
SELECT * FROM attribute.minerva_entity_set WHERE name = $1 AND owner = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "relation_directory"."add_entity_to_set"("minerva_entity_set_id" integer, "entity" text)
    RETURNS attribute.minerva_entity_set
AS $$
DECLARE
  set attribute.minerva_entity_set;
BEGIN
  SELECT * FROM attribute.minerva_entity_set WHERE id = $1 INTO set;
  PERFORM relation_directory.update_entity_set_attributes($1);
  PERFORM action(FORMAT(
    'INSERT INTO relation."%s->entity_set" (source_id, target_id) '
    'SELECT source.id AS source_id, %s AS target '
    'FROM entity.%I source '
    'WHERE source.name = ''%s'''
    'ON CONFLICT DO NOTHING;',
    set.source_entity_type,
    set.entity_id,
    set.source_entity_type,
    $2
  ));
  RETURN set;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "relation_directory"."remove_entity_from_set"("minerva_entity_set_id" integer, "entity" text)
    RETURNS void
AS $$
DECLARE
  set attribute.minerva_entity_set;
BEGIN
  SELECT * FROM attribute.minerva_entity_set WHERE id = $1 INTO set;
  PERFORM relation_directory.update_entity_set_attributes($1);
  PERFORM action(FORMAT(
    'DELETE es FROM relation."%s->entity_set" es '
    'JOIN entity.%I source ON es.source_id = source.id '
    'WHERE source.name = ''%s'' AND target_id = %s;',
    set.source_entity_type,
    set.source_entity_type,
    $2,
    set.entity_id
  ));
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "relation_directory"."add_entities_to_set"("minerva_entity_set_id" integer, "entities" text[])
    RETURNS void
AS $$
SELECT relation_directory.add_entity_to_set($1, e) FROM unnest($2) e;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "relation_directory"."change_set_entities"("minerva_entity_set_id" integer, "entities" text[])
    RETURNS void
AS $$
DECLARE
  set attribute.minerva_entity_set;
BEGIN
  SELECT * FROM attribute.minerva_entity_set WHERE id = $1 INTO set;
  PERFORM action(FORMAT(
    'DELETE FROM relation."%s->entity_set" '
    'WHERE target_id = %s;',
    set.source_entity_type,
    set.entity_id
  ));
  PERFORM relation_directory.add_entities_to_set($1, $2);
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "relation_directory"."change_set_entities"("minerva_entity_set_id" integer, "entities" text[]) IS 'Set the entities in the set to exactly the specified entities';


CREATE FUNCTION "relation_directory"."change_set_entities_guarded"("minerva_entity_set_id" integer, "entities" text[])
    RETURNS text[]
AS $$
DECLARE
  set attribute.minerva_entity_set;
  entity text;
  real_entity text;
  result text[];
  newresult text[];
BEGIN
  SELECT * FROM attribute.minerva_entity_set WHERE id = $1 INTO set;
  SELECT $2 INTO result;
  FOREACH entity IN ARRAY $2 LOOP
    EXECUTE FORMAT(
      'SELECT name FROM entity.%I WHERE name = ''%s'';',
      set.source_entity_type,
      entity
    ) INTO real_entity;
    SELECT array_remove(result, real_entity) INTO result;
  END LOOP;
  IF ARRAY_LENGTH(result, 1) IS NULL THEN
    PERFORM relation_directory.change_set_entities($1, $2);
  END IF;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "relation_directory"."change_set_entities_guarded"("minerva_entity_set_id" integer, "entities" text[]) IS 'Only sets the entities if all specified entities are actually valid.
Returns those entities that were invalid.';


CREATE FUNCTION "relation_directory"."get_entity_set_members"("minerva_entity_set_id" integer)
    RETURNS text[]
AS $$
DECLARE
  set attribute.minerva_entity_set;
  result text[];
BEGIN
  SELECT * FROM attribute.minerva_entity_set WHERE id = $1 INTO set;
  EXECUTE FORMAT(
    'SELECT array_agg(e.name) '
    'FROM relation."%s->entity_set" es JOIN entity.%I e ON es.source_id = e.id '
    'WHERE es.target_id = %s',
    set.source_entity_type,
    set.source_entity_type,
    set.entity_id
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "relation_directory"."create_entity_set_guarded"("name" text, "group" text, "entity_type_name" text, "owner" text, "description" text, "entities" text[])
    RETURNS text[]
AS $$
DECLARE
  entity text;
  real_entity text;
  result text[];
  newresult text[];
  entityset integer;
BEGIN
  SELECT $6 INTO result;
  FOREACH entity IN ARRAY $6 LOOP
    EXECUTE FORMAT(
      'SELECT name FROM entity.%I WHERE name = ''%s'';',
      $3,
      entity
    ) INTO real_entity;
    SELECT array_remove(result, real_entity) INTO result;
  END LOOP;
  IF ARRAY_LENGTH(result, 1) IS NULL THEN
    SELECT id FROM relation_directory.create_entity_set($1, $2, $3, $4, $5) INTO entityset;
    PERFORM relation_directory.change_set_entities(entityset, $6);
  END IF;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "relation_directory"."get_entity_set_members"("name" text, "owner" text)
    RETURNS text[]
AS $$
SELECT relation_directory.get_entity_set_members(es.id)
  FROM attribute.minerva_entity_set es
  WHERE owner = $2 AND name = $1;
$$ LANGUAGE sql STABLE;


CREATE TYPE "trend"."trend_data" AS (
  "timestamp" timestamptz,
  "entity_id" integer,
  "counters" numeric[]
);



CREATE FUNCTION "trend_directory"."get_table_name_for_trend"("trend" text, "entity" text, "granularity" interval)
    RETURNS name
AS $$
SELECT tsp.name FROM trend_directory.table_trend t
  JOIN trend_directory.trend_store_part tsp ON tsp.id = t.trend_store_part_id
  JOIN trend_directory.trend_store ts ON ts.id = tsp.trend_store_id
  JOIN directory.entity_type et ON et.id = ts.entity_type_id
  WHERE t.name = $1
    AND ts.granularity = $3
    AND et.name = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend"."create_dynamic_source_description"("trend" text, "counter" integer, "entity" text, "granularity" interval)
    RETURNS text
AS $$
SELECT FORMAT( 'trend.%I t%s %s ', trend_directory.get_table_name_for_trend($1, $3, $4), $2, CASE $2 WHEN 1 THEN '' ELSE FORMAT('ON t%s.entity_id = t1.entity_id AND t%s.timestamp = t1.timestamp', $2, $2) END );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend"."get_dynamic_trend_data_sql"("timestamp" timestamptz, "entity_type_name" text, "granularity" interval, "counter_names" text[])
    RETURNS text
AS $$
WITH ref as (
  SELECT
    FORMAT('t%s.%I::numeric', i, c) as column_description,
    trend.create_dynamic_source_description(c, i::integer, $2, $3) as join_data             
  FROM unnest($4) WITH ORDINALITY as counters(c,i)
)
SELECT FORMAT(
    'SELECT ''%s''::timestamp, t1.entity_id, ARRAY[%s] '
    'FROM %s'
    'JOIN entity.%I ent ON ent.id = t1.entity_id '
    'WHERE t1.timestamp = ''%s'';',
  $1,
  string_agg(column_description, ', '),
  string_agg(join_data, ' JOIN '),
  $2,
  $1
  ) FROM ref;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend"."get_dynamic_trend_data"("timestamp" timestamp with time zone, "entity_type_name" text, "granularity" interval, "counter_names" text[])
    RETURNS setof trend.trend_data
AS $$
DECLARE r trend.trend_data%rowtype; BEGIN IF $4 = ARRAY[]::text[] THEN FOR r IN EXECUTE FORMAT('SELECT ''%s''::timestamptz, e.id, ARRAY[]::numeric[] from entity.%I e', $1, $2) LOOP RETURN NEXT r; END LOOP; ELSE FOR r IN EXECUTE trend.get_dynamic_trend_data_sql($1, $2, $3, $4) LOOP RETURN NEXT r; END LOOP; END IF; RETURN; END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "trend"."mapping_id"(timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
SELECT $1;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend"."mapping_15m->1d"(timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
SELECT date_trunc('day', $1 - interval '15m') + interval '1d';
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend"."mapping_15m->1h"(timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
SELECT date_trunc('hour', $1 - interval '15m') + interval '1h';
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend"."mapping_30m->1d"(timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
SELECT date_trunc('day', $1 - interval '30m') + interval '1d';
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend"."mapping_30m->1h"(timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
SELECT date_trunc('hour', $1 - interval '30m') + interval '1h';
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend"."mapping_1d->1w"(timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
SELECT date_trunc('week', $1 - interval '1d') + interval '1w';
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trend"."mapping_1d->1month"(timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
SELECT date_trunc('month', $1 - interval '1d') + interval '1month';
$$ LANGUAGE sql IMMUTABLE;


ALTER TABLE "attribute_directory"."attribute_store"
  ADD CONSTRAINT "attribute_attribute_store_entity_type_id_fkey"
  FOREIGN KEY (entity_type_id)
  REFERENCES "directory"."entity_type" (id) ON DELETE CASCADE;

ALTER TABLE "attribute_directory"."attribute_store"
  ADD CONSTRAINT "attribute_attribute_store_data_source_id_fkey"
  FOREIGN KEY (data_source_id)
  REFERENCES "directory"."data_source" (id);

ALTER TABLE "attribute_directory"."sampled_view_materialization"
  ADD CONSTRAINT "sampled_view_materialization_attribute_store_id_fkey"
  FOREIGN KEY (attribute_store_id)
  REFERENCES "attribute_directory"."attribute_store" (id) ON DELETE CASCADE;

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

ALTER TABLE "directory"."tag"
  ADD CONSTRAINT "tag_tag_group_id_fkey"
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

ALTER TABLE "trend_directory"."trend_store"
  ADD CONSTRAINT "trend_store_entity_type_id_fkey"
  FOREIGN KEY (entity_type_id)
  REFERENCES "directory"."entity_type" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."trend_store"
  ADD CONSTRAINT "trend_store_data_source_id_fkey"
  FOREIGN KEY (data_source_id)
  REFERENCES "directory"."data_source" (id);

ALTER TABLE "trend_directory"."trend_store_part"
  ADD CONSTRAINT "trend_store_part_trend_store_id_fkey"
  FOREIGN KEY (trend_store_id)
  REFERENCES "trend_directory"."trend_store" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."partition"
  ADD CONSTRAINT "partition_trend_store_part_id_fkey"
  FOREIGN KEY (trend_store_part_id)
  REFERENCES "trend_directory"."trend_store_part" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."trend_view"
  ADD CONSTRAINT "trend_view_entity_type_id_fkey"
  FOREIGN KEY (entity_type_id)
  REFERENCES "directory"."entity_type" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."trend_view"
  ADD CONSTRAINT "trend_view_data_source_id_fkey"
  FOREIGN KEY (data_source_id)
  REFERENCES "directory"."data_source" (id);

ALTER TABLE "trend_directory"."trend_view_part"
  ADD CONSTRAINT "trend_view_part_trend_view_id_fkey"
  FOREIGN KEY (trend_view_id)
  REFERENCES "trend_directory"."trend_view" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."view_trend"
  ADD CONSTRAINT "table_trend_trend_view_part_id_fkey"
  FOREIGN KEY (trend_view_part_id)
  REFERENCES "trend_directory"."trend_view_part" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."table_trend"
  ADD CONSTRAINT "table_trend_trend_store_part_id_fkey"
  FOREIGN KEY (trend_store_part_id)
  REFERENCES "trend_directory"."trend_store_part" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."generated_table_trend"
  ADD CONSTRAINT "table_trend_trend_store_part_id_fkey"
  FOREIGN KEY (trend_store_part_id)
  REFERENCES "trend_directory"."trend_store_part" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."table_trend_tag_link"
  ADD CONSTRAINT "table_trend_tag_link_table_trend_id_fkey"
  FOREIGN KEY (table_trend_id)
  REFERENCES "trend_directory"."table_trend" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."table_trend_tag_link"
  ADD CONSTRAINT "table_trend_tag_link_tag_id_fkey"
  FOREIGN KEY (tag_id)
  REFERENCES "directory"."tag" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."modified_log"
  ADD CONSTRAINT "modified_trend_store_part_id_fkey"
  FOREIGN KEY (trend_store_part_id)
  REFERENCES "trend_directory"."trend_store_part" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."modified"
  ADD CONSTRAINT "modified_trend_store_part_id_fkey"
  FOREIGN KEY (trend_store_part_id)
  REFERENCES "trend_directory"."trend_store_part" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."trend_store_part_stats"
  ADD CONSTRAINT "trend_store_part_stats_trend_store_part_id_fkey"
  FOREIGN KEY (trend_store_part_id)
  REFERENCES "trend_directory"."trend_store_part" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."materialization"
  ADD CONSTRAINT "materialization_dst_trend_store_id_fkey"
  FOREIGN KEY (dst_trend_store_part_id)
  REFERENCES "trend_directory"."trend_store_part" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."materialization_metrics"
  ADD CONSTRAINT "materialization_metrics_materialization_id_fkey"
  FOREIGN KEY (materialization_id)
  REFERENCES "trend_directory"."materialization" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."view_materialization"
  ADD CONSTRAINT "view_materialization_materialization_id_fkey"
  FOREIGN KEY (materialization_id)
  REFERENCES "trend_directory"."materialization" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."function_materialization"
  ADD CONSTRAINT "function_materialization_materialization_id_fkey"
  FOREIGN KEY (materialization_id)
  REFERENCES "trend_directory"."materialization" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."materialization_state"
  ADD CONSTRAINT "materialization_state_materialization_id_fkey"
  FOREIGN KEY (materialization_id)
  REFERENCES "trend_directory"."materialization" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."function_materialization_state"
  ADD CONSTRAINT "materialization_state_materialization_id_fkey"
  FOREIGN KEY (materialization_id)
  REFERENCES "trend_directory"."function_materialization" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."materialization_tag_link"
  ADD CONSTRAINT "materialization_tag_link_tag_id_fkey"
  FOREIGN KEY (tag_id)
  REFERENCES "directory"."tag" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."materialization_tag_link"
  ADD CONSTRAINT "materialization_tag_link_materialization_id_fkey"
  FOREIGN KEY (materialization_id)
  REFERENCES "trend_directory"."materialization" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."materialization_trend_store_link"
  ADD CONSTRAINT "materialization_trend_store_link_materialization_id_fkey"
  FOREIGN KEY (materialization_id)
  REFERENCES "trend_directory"."materialization" (id) ON DELETE CASCADE;

ALTER TABLE "trend_directory"."materialization_trend_store_link"
  ADD CONSTRAINT "materialization_trend_store_link_trend_store_id_fkey"
  FOREIGN KEY (trend_store_part_id)
  REFERENCES "trend_directory"."trend_store_part" (id) ON DELETE CASCADE;

ALTER TABLE "trigger"."rule"
  ADD CONSTRAINT "rule_notification_store_id_fkey"
  FOREIGN KEY (notification_store_id)
  REFERENCES "notification_directory"."notification_store" (id);

ALTER TABLE "trigger"."rule_trend_store_link"
  ADD CONSTRAINT "rule_trend_store_link_rule_id_fkey"
  FOREIGN KEY (rule_id)
  REFERENCES "trigger"."rule" (id) ON DELETE CASCADE;

ALTER TABLE "trigger"."rule_trend_store_link"
  ADD CONSTRAINT "rule_trend_store_link_trend_store_part_id_fkey"
  FOREIGN KEY (trend_store_part_id)
  REFERENCES "trend_directory"."trend_store_part" (id) ON DELETE CASCADE;

ALTER TABLE "trigger"."rule_tag_link"
  ADD CONSTRAINT "rule_tag_link_rule_id_fkey"
  FOREIGN KEY (rule_id)
  REFERENCES "trigger"."rule" (id) ON DELETE CASCADE;

ALTER TABLE "trigger"."rule_tag_link"
  ADD CONSTRAINT "rule_tag_link_tag_id_fkey"
  FOREIGN KEY (tag_id)
  REFERENCES "directory"."tag" (id) ON DELETE CASCADE;
