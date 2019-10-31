

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,0,3)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;

DROP TRIGGER cleanup_on_rule_delete ON "trigger"."rule";

DROP FUNCTION "trigger"."cleanup_on_rule_delete"();

CREATE FUNCTION "trigger"."kpi_function_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_kpi')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_kpi_function_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION trigger_rule.%I(timestamp with time zone) CASCADE', "trigger".kpi_function_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."kpi_type_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_kpi')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_notification_fn_timestamp_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION trigger_rule.%I(timestamp with time zone)', trigger.notification_fn_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_kpi_type_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP TYPE IF EXISTS trigger_rule.%I CASCADE;',
    trigger.kpi_type_name($1)
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."drop_with_threshold_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION trigger_rule.%I(timestamp with time zone)',
    trigger.with_threshold_fn_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."drop_notification_message_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION trigger_rule.%I',
    trigger.notification_message_fn_name($1),
    trigger.details_type_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trigger"."drop_rule_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION trigger_rule.%I(timestamp with time zone)',
    trigger.rule_fn_name($1)
);
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."delete_rule"(name)
    RETURNS bigint
AS $$
SELECT trigger.cleanup_rule(rule) FROM trigger.rule WHERE name = $1;
WITH deleted AS ( DELETE FROM trigger.rule WHERE name = $1 RETURNING * ) SELECT count(*) FROM deleted;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION "trigger"."drop_weight_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION trigger_rule.%I(trigger_rule.%I)',
    trigger.weight_fn_name($1),
    trigger.details_type_name($1)
);
$$ LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION "trigger"."drop_details_type_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP TYPE IF EXISTS trigger_rule.%I CASCADE;',
    trigger.details_type_name($1)
);
$$ LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION "trigger"."cleanup_rule"(trigger.rule)
    RETURNS trigger.rule
AS $$
BEGIN
    EXECUTE trigger.drop_set_thresholds_fn_sql($1);
    EXECUTE trigger.drop_rule_fn_sql($1);
    EXECUTE trigger.drop_kpi_function_sql($1);
    EXECUTE trigger.drop_notification_fn_sql($1);
    EXECUTE trigger.drop_notification_fn_timestamp_sql($1);
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
