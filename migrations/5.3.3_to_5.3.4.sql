

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,3,4)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


DROP FUNCTION "trigger"."create_exception_threshold_table_sql"(trigger.rule, name[]);

DROP FUNCTION "trigger"."create_exception_threshold_table"(trigger.rule, name[]);

DROP FUNCTION "trigger"."create_rule"(name, trigger.threshold_def[]);

CREATE FUNCTION "trigger"."get_exception_threshold_fn_name"(trigger.rule)
    RETURNS text
AS $$
SELECT ($1.name || '_get_exception_threshold')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_exception_threshold_fn_name"(trigger.rule)
    RETURNS text
AS $$
SELECT ($1.name || '_create_exception_threshold')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."get_or_create_exception_threshold_fn_name"(trigger.rule)
    RETURNS text
AS $$
SELECT ($1.name || '_get_or_create_exception_threshold')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."change_exception_threshold_fn_name"(trigger.rule)
    RETURNS text
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


CREATE FUNCTION "trigger"."create_rule"(text, trigger.threshold_def[])
    RETURNS trigger.rule
AS $$
SELECT trigger.setup_rule(trigger.define($1::name), $2);
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION "trigger"."create_exception_threshold_table"(trigger.rule, trigger.threshold_def[])
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.create_exception_threshold_table_sql($1, $2));
SELECT public.action($1, trigger.get_exception_threshold_fn_sql($1));
SELECT public.action($1, trigger.create_exception_threshold_fn_sql($1));
SELECT public.action($1, trigger.get_or_create_exception_threshold_fn_sql($1));
SELECT public.action($1, trigger.create_change_exception_threshold_fn_sql($1, $2));
SELECT public.action($1, format('ALTER TABLE trigger_rule.%I OWNER TO minerva_admin', trigger.exception_threshold_table_name($1)));
SELECT public.action($1, format('GRANT SELECT ON trigger_rule.%I TO minerva', trigger.exception_threshold_table_name($1)));
SELECT public.action($1, format('GRANT INSERT, UPDATE, DELETE ON trigger_rule.%I TO minerva_writer', trigger.exception_threshold_table_name($1)));
SELECT public.action($1, format(
    'GRANT USAGE, SELECT ON SEQUENCE %s TO minerva_writer',
    pg_get_serial_sequence(format('trigger_rule.%I', trigger.exception_threshold_table_name($1)), 'id')
));
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION "trigger"."define_thresholds"(trigger.rule, trigger.threshold_def[])
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
