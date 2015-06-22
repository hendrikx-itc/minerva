CREATE OR REPLACE FUNCTION trigger.action(anyelement, sql text)
    RETURNS anyelement
AS $$
BEGIN
    EXECUTE sql;

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.action(anyelement, sql text[])
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


CREATE OR REPLACE FUNCTION trigger.with_threshold_view_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_with_threshold')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.weight_fn_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_weight')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.exception_weight_table_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_exception_weight')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.exception_threshold_table_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_exception_threshold')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.get_rule(name)
    RETURNS trigger.rule
AS $$
    SELECT rule FROM "trigger".rule WHERE name = $1;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trigger.add_rule(name)
    RETURNS trigger.rule
AS $$
    INSERT INTO "trigger".rule (name)
    VALUES ($1) RETURNING rule;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.define(name)
    RETURNS trigger.rule
AS $$
    SELECT COALESCE(trigger.get_rule($1), trigger.add_rule($1));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.threshold_view_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_threshold')::name;
$$ LANGUAGE SQL IMMUTABLE;


--- View <rule>

CREATE OR REPLACE FUNCTION trigger.rule_view_name(trigger.rule)
    RETURNS name
AS $$
    SELECT $1.name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.get_rule_view_sql(trigger.rule)
    RETURNS text
AS $$
SELECT
	pg_get_viewdef(oid, true)
FROM pg_class
WHERE relname = trigger.rule_view_name($1);
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trigger.rule_view_sql(trigger.rule, where_clause text)
    RETURNS text
AS $$
SELECT format(
    'SELECT * FROM trigger_rule.%I WHERE %s;',
    trigger.with_threshold_view_name($1), $2
);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.drop_rule_view_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP VIEW trigger_rule.%I CASCADE', $1.name);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_rule_view_sql(trigger.rule, rule_view_sql text)
    RETURNS text[]
AS $$
SELECT ARRAY[
    format('CREATE OR REPLACE VIEW trigger_rule.%I AS %s', trigger.rule_view_name($1), $2),
    format('ALTER VIEW trigger_rule.%I OWNER TO minerva_admin', trigger.rule_view_name($1)),
    format('GRANT SELECT ON trigger_rule.%I TO minerva', trigger.rule_view_name($1))
];
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.create_rule_view(trigger.rule, rule_view_sql text)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, trigger.create_rule_view_sql($1, $2));
$$ LANGUAGE SQL VOLATILE;


--- View <rule>_kpi

CREATE OR REPLACE FUNCTION trigger.kpi_view_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_kpi')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.get_kpi_view_sql(trigger.rule)
    RETURNS text
AS $$
SELECT
	pg_get_viewdef(oid, true)
FROM pg_class
WHERE relname = trigger.kpi_view_name($1);
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trigger.kpi_view_sql(trigger.rule, sql text)
    RETURNS text
AS $$
SELECT format(
    'CREATE OR REPLACE VIEW trigger_rule.%I AS %s',
    "trigger".kpi_view_name($1), $2
);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.drop_kpi_view_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP VIEW trigger_rule.%I CASCADE', "trigger".kpi_view_name($1));
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_kpi_view_sql(trigger.rule, sql text)
    RETURNS text[]
AS $$
SELECT ARRAY[
    trigger.kpi_view_sql($1, $2),
    format('ALTER VIEW trigger_rule.%I OWNER TO minerva_admin', trigger.kpi_view_name($1)),
    format('GRANT SELECT ON trigger_rule.%I TO minerva', trigger.kpi_view_name($1))
];
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.create_kpi_view(trigger.rule, sql text)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, trigger.create_kpi_view_sql($1, $2));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.update_kpi_view(trigger.rule, sql text)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, trigger.kpi_view_sql($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.update_kpi_view(name, sql text)
    RETURNS trigger.rule
AS $$
SELECT trigger.update_kpi_view(rule, $2) FROM trigger.rule WHERE name = $1;
$$ LANGUAGE sql VOLATILE;


--- Function <rule>_create_notification

CREATE OR REPLACE FUNCTION trigger.notification_fn_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_create_notification')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.get_notification_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT
	pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = trigger.notification_fn_name($1);
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trigger.create_notification_fn_sql(trigger.rule, expression text)
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
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.drop_notification_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION trigger_rule.%I(trigger_rule.%I)', trigger.notification_fn_name($1), $1.name);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_notification_fn(trigger.rule, expression text)
    RETURNS trigger.rule
AS $$
    SELECT trigger.action($1, trigger.create_notification_fn_sql($1, $2));
    SELECT trigger.action($1, format('ALTER FUNCTION trigger_rule.%I(trigger_rule.%I) OWNER TO minerva_admin', trigger.notification_fn_name($1), $1.name));
    SELECT trigger.action($1, format('GRANT EXECUTE ON FUNCTION trigger_rule.%I(trigger_rule.%I) TO minerva', trigger.notification_fn_name($1), $1.name));
$$ LANGUAGE SQL VOLATILE;


--- View <rule>_notification

CREATE OR REPLACE FUNCTION trigger.notification_view_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_notification')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.notification_view_sql(trigger.rule)
    RETURNS text
AS $function$
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
$function$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.drop_notification_view_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP VIEW trigger_rule.%I', trigger.notification_view_name($1));
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_notification_view_sql(trigger.rule)
    RETURNS text[]
AS $$
SELECT ARRAY[
    trigger.notification_view_sql($1),
    format('ALTER VIEW trigger_rule.%I OWNER TO minerva_admin', trigger.notification_view_name($1)),
    format('GRANT SELECT ON trigger_rule.%I TO minerva', trigger.notification_view_name($1))
];
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notification_view(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, trigger.create_notification_view_sql($1));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.notification_threshold_test_fn_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_notification_test_threshold')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.notification_test_threshold_fn_sql(trigger.rule)
    RETURNS text
AS $function$
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
$function$ LANGUAGE SQL IMMUTABLE;


--- View <rule>_with_threshold


CREATE OR REPLACE FUNCTION trigger.get_with_threshold_view_sql(trigger.rule)
    RETURNS text
AS $$
SELECT
	pg_get_viewdef(oid, true)
FROM pg_class
WHERE relname = trigger.with_threshold_view_name($1);
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trigger.get_threshold_defs(trigger.rule)
    RETURNS SETOF trigger.kpi_def AS
$$
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
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trigger.with_threshold_view_sql(trigger.rule)
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
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trigger.create_with_threshold_view(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT trigger.action($1, format('CREATE OR REPLACE VIEW trigger_rule.%I AS %s', trigger.with_threshold_view_name($1), trigger.with_threshold_view_sql($1)));
SELECT trigger.action($1, format('ALTER VIEW trigger_rule.%I OWNER TO minerva_admin', trigger.with_threshold_view_name($1)));
SELECT trigger.action($1, format('GRANT SELECT ON trigger_rule.%I TO minerva', trigger.with_threshold_view_name($1)));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.drop_with_threshold_view_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP VIEW trigger_rule.%I', trigger.with_threshold_view_name($1));
$$ LANGUAGE SQL IMMUTABLE;


--- Function <rule>_weight


CREATE OR REPLACE FUNCTION trigger.get_weight_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT
	pg_get_functiondef(oid)
FROM pg_proc
WHERE proname = trigger.weight_fn_name($1);
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trigger.weight_fn_sql(trigger.rule, expression text)
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
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.drop_weight_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION trigger_rule.%I(trigger_rule.%I)', trigger.weight_fn_name($1), $1.name);
$$ LANGUAGE SQL IMMUTABLE;


--- Table <rule>_exception_weight


CREATE OR REPLACE FUNCTION trigger.exception_weight_table_sql(trigger.rule)
    RETURNS text AS
$function$
SELECT format(
    $$CREATE TABLE trigger_rule.%I
    (
        id serial,
        entity_id integer not null,
        created timestamp with time zone not null default now(),
        start timestamp with time zone not null default now(),
        expires timestamp with time zone not null default now() + interval '3 months',
        weight integer not null
    );$$,
    trigger.exception_weight_table_name($1)
);
$function$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_exception_weight_table(trigger.rule)
    RETURNS trigger.rule AS
$$
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
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.drop_exception_weight_table_sql(trigger.rule)
    RETURNS text AS
$$
SELECT format('DROP TABLE IF EXISTS trigger_rule.%I', trigger.exception_weight_table_name($1));
$$ LANGUAGE SQL IMMUTABLE;


--- Type <rule>_notification_details

CREATE OR REPLACE FUNCTION trigger.notification_type_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_notification_details')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_notification_type_sql(trigger.rule)
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
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.drop_notification_type_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP TYPE IF EXISTS trigger_rule.%I', trigger.notification_type_name($1));
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_notification_type(trigger.rule)
    RETURNS trigger.rule
AS $$
    SELECT trigger.action(
        $1,
        trigger.create_notification_type_sql($1)
    );
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.define_notification(name, expression text)
    RETURNS trigger.rule
AS $$
    SELECT trigger.create_notification_fn(trigger.get_rule($1), $2);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_dummy_notification_fn(trigger.rule)
    RETURNS trigger.rule
AS $$
    SELECT trigger.create_notification_fn($1, quote_literal($1.name));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.get_kpi_def(trigger.rule, name)
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


--- Table <rule>_exception_threshold

CREATE OR REPLACE FUNCTION trigger.create_exception_threshold_table_sql(trigger.rule, name[])
    RETURNS text AS
$$
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
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trigger.drop_exception_threshold_table_sql(trigger.rule)
    RETURNS text AS
$$
SELECT format('DROP TABLE IF EXISTS trigger_rule.%I', trigger.exception_threshold_table_name($1))
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_exception_threshold_table(trigger.rule, name[])
    RETURNS trigger.rule AS
$$
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
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.get_kpi_defs(trigger.rule)
    RETURNS SETOF trigger.kpi_def AS
$$
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
$$ LANGUAGE SQL STABLE;


-- Function <rule>_set_thresholds

CREATE OR REPLACE FUNCTION trigger.set_thresholds_fn_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_set_thresholds')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.set_thresholds(trigger.rule, exprs text)
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


CREATE OR REPLACE FUNCTION trigger.create_set_thresholds_fn_sql(trigger.rule)
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
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_set_thresholds_fn(trigger.rule)
    RETURNS trigger.rule
AS $$
    SELECT trigger.action($1, trigger.create_set_thresholds_fn_sql($1));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.drop_set_thresholds_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION trigger_rule.%I(%s)',
    trigger.set_thresholds_fn_name($1),
    array_to_string(array_agg(format('%s', t.data_type)), ', ')
)
FROM trigger.get_threshold_defs($1) t;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.drop_thresholds_view_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP VIEW trigger_rule.%I', trigger.threshold_view_name($1))
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.set_thresholds(name, exprs text)
    RETURNS trigger.rule
AS $$
    SELECT trigger.set_thresholds(trigger.get_rule($1), $2);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_dummy_thresholds(trigger.rule, name[])
    RETURNS trigger.rule
AS $$
    SELECT trigger.set_thresholds(
        $1,
        array_to_string(array_agg(format('NULL::%I %I', kpi.data_type, kpi.name)), ', ')
    ) FROM (
        SELECT (trigger.get_kpi_def($1, kpi_name)).* FROM unnest($2) kpi_name
    ) kpi;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.set_weight(trigger.rule, expression text)
    RETURNS trigger.rule
AS $$
    SELECT trigger.action($1, trigger.weight_fn_sql($1, $2));
    SELECT trigger.action($1, format('ALTER FUNCTION trigger_rule.%I(trigger_rule.%I) OWNER TO minerva_admin', trigger.weight_fn_name($1), $1.name));
    SELECT trigger.action($1, format('GRANT EXECUTE ON FUNCTION trigger_rule.%I(trigger_rule.%I) TO minerva', trigger.weight_fn_name($1), $1.name));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.set_weight(name, expression text)
    RETURNS trigger.rule
AS $$
    SELECT trigger.set_weight(trigger.get_rule($1), $2);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_dummy_default_weight(trigger.rule)
    RETURNS trigger.rule
AS
$$SELECT trigger.set_weight($1, 'SELECT 1');$$
LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_trigger_notificationstore(name)
    RETURNS notification.notificationstore
AS
$$
SELECT notification.create_notificationstore($1, ARRAY[
    ('created', 'timestamp with time zone'),
    ('rule_id', 'integer'),
    ('weight', 'integer'),
    ('details', 'text')
]::notification.attr_def[]);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.transfer_notifications_from_staging(notification.notificationstore)
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
        notification.table_name($1), notification.staging_table_name($1), notification.table_name($1));

    GET DIAGNOSTICS num_rows = ROW_COUNT;

    EXECUTE format('DELETE FROM notification.%I', notification.staging_table_name($1));

    RETURN num_rows;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notifications(trigger.rule, notification.notificationstore, timestamp with time zone)
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
        notification.staging_table_name($2), trigger.notification_view_name($1)
    )
    USING $1.id, $3;

    SELECT trigger.transfer_notifications_from_staging($2) INTO num_rows;

    RETURN num_rows;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notifications(trigger.rule, timestamp with time zone)
    RETURNS integer
AS $$
    SELECT
        trigger.create_notifications($1, notificationstore, $2)
    FROM notification.notificationstore
    WHERE id = $1.notificationstore_id;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notifications(trigger.rule, notification.notificationstore, interval)
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
        notification.staging_table_name($2), trigger.notification_view_name($1)
    )
    USING $1.id, $3;

    SELECT trigger.transfer_notifications_from_staging($2) INTO num_rows;

    RETURN num_rows;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notifications(trigger.rule, interval)
    RETURNS integer
AS $$
    SELECT trigger.create_notifications($1, notificationstore, $2)
    FROM notification.notificationstore
    WHERE id = $1.notificationstore_id;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notifications(trigger.rule)
    RETURNS integer
AS $$
    SELECT trigger.create_notifications($1, notificationstore, $1.default_interval)
    FROM notification.notificationstore
    WHERE id = $1.notificationstore_id;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notifications(rule_name name, notificationstore_name name, timestamp with time zone)
    RETURNS integer
AS $$
    SELECT trigger.create_notifications(trigger.get_rule($1), notification.get_notificationstore($2), $3);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notifications(rule_name name, timestamp with time zone)
    RETURNS integer
AS $$
    SELECT trigger.create_notifications(rule, notificationstore, $2)
    FROM trigger.rule
    JOIN notification.notificationstore ON notificationstore.id = rule.notificationstore_id
    WHERE rule.name = $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notifications(rule_name name, notificationstore_name name, interval)
    RETURNS integer
AS $$
    SELECT trigger.create_notifications(trigger.get_rule($1), notification.get_notificationstore($2), $3);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notifications(rule_name name, interval)
    RETURNS integer
AS $$
    SELECT trigger.create_notifications(trigger.get_rule($1), $2);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notifications(rule_name name)
    RETURNS integer
AS $$
    SELECT trigger.create_notifications(trigger.get_rule($1));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.setup_rule(trigger.rule, kpi_sql text, name[], sql text)
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
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_rule(name, kpi_sql text, name[], sql text)
    RETURNS trigger.rule
AS $$
    SELECT trigger.setup_rule(trigger.define($1), $2, $3, $4);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.cleanup_rule(trigger.rule)
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
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION trigger.tag(tag_name character varying, rule_id integer)
        RETURNS trigger.rule_tag_link
AS $$
        INSERT INTO trigger.rule_tag_link (rule_id, tag_id)
        SELECT $2, tag.id FROM directory.tag WHERE name = $1
        RETURNING *;
$$ LANGUAGE SQL VOLATILE;

COMMENT ON FUNCTION trigger.tag(character varying, rule_id integer)
IS 'Add tag with name tag_name to rule with id rule_id.
The tag must already exist.';


CREATE OR REPLACE FUNCTION trigger.truncate(timestamp with time zone, interval)
    RETURNS timestamp with time zone
AS $$
    SELECT CASE
        WHEN $2 = '1 day' THEN
            date_trunc('day', $1)
        ELSE
            to_timestamp((
                extract(epoch FROM $1)::integer / extract(epoch FROM $2)::integer
            )::integer * extract(epoch FROM $2))
        END;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.timestamps(trigger.rule)
    RETURNS SETOF timestamp with time zone
AS $$
    SELECT generate_series(
        trigger.truncate(now(), $1.granularity),
        trigger.truncate(now(), $1.granularity) - $1.default_interval,
        - $1.granularity
    );
$$ LANGUAGE sql STABLE;
