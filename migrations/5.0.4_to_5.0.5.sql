

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,0,5)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


DROP FUNCTION "trigger"."drop_notification_fn_timestamp_sql"(trigger.rule);

CREATE OR REPLACE FUNCTION "trigger"."drop_notification_fn_sql"(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION trigger_rule.%I(timestamp with time zone)', trigger.notification_fn_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION "trigger"."cleanup_rule"(trigger.rule)
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
