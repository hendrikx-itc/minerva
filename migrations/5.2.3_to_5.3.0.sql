

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,3,0)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."notification_data_fn_name"(trigger.rule)
    RETURNS name
AS $$
SELECT ($1.name || '_notification_data')::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION "trigger"."create_notification_data_fn_sql"(trigger.rule, "expression" text)
    RETURNS text
AS $$
SELECT format(
'CREATE OR REPLACE FUNCTION trigger_rule.%I(trigger_rule.%I)
    RETURNS json
AS $function$
SELECT (%s)
$function$ LANGUAGE SQL IMMUTABLE',
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
        ),
        format(
            'GRANT EXECUTE ON FUNCTION trigger_rule.%I(trigger_rule.%I) TO minerva',
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


CREATE OR REPLACE FUNCTION "trigger"."transfer_notifications_from_staging"(notification_directory.notification_store)
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


CREATE OR REPLACE FUNCTION "trigger"."create_notifications"(trigger.rule, notification_directory.notification_store, timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    num_rows integer;
BEGIN
    EXECUTE format(
$query$
INSERT INTO notification.%I(entity_id, timestamp, created, rule_id, weight, details, data)
(SELECT entity_id, timestamp, now(), $1, weight, details, data FROM trigger_rule.%I($2))
$query$,
        notification_directory.staging_table_name($2), trigger.notification_fn_name($1)
    )
    USING $1.id, $3;

    SELECT trigger.transfer_notifications_from_staging($2) INTO num_rows;

    RETURN num_rows;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION "trigger"."notification_fn_sql"(trigger.rule)
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


CREATE OR REPLACE FUNCTION "trigger"."setup_rule"(trigger.rule, trigger.threshold_def[])
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
