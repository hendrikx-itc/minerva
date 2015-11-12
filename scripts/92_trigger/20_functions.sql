-- Type names

CREATE OR REPLACE FUNCTION trigger.with_threshold_fn_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_with_threshold')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.weight_fn_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_weight')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.rule_fn_name(trigger.rule)
    RETURNS name
AS $$
    SELECT $1.name;
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


CREATE OR REPLACE FUNCTION trigger.notification_message_fn_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_notification_message')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.notification_fn_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_notification')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.fingerprint_fn_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_fingerprint')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.runnable_fn_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_runnable')::name;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.kpi_type_name(trigger.rule)
    RETURNS name
AS $$
    SELECT typname FROM pg_type WHERE oid = public.prorettype(
        format(
            'trigger_rule.%I(timestamp with time zone)',
            trigger.kpi_fn_name($1)
        )::regprocedure::oid
    );
$$ LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.details_type_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_details')::name;
$$ LANGUAGE sql IMMUTABLE;


-- Convenience functions


CREATE OR REPLACE FUNCTION trigger.get_rule(name)
    RETURNS trigger.rule
AS $$
    SELECT rule FROM "trigger".rule WHERE name = $1;
$$ LANGUAGE SQL STABLE;


COMMENT ON FUNCTION trigger.get_rule(name) IS
'Return rule with specified name.';


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


--- Function <rule>


CREATE OR REPLACE FUNCTION trigger.rule_fn_sql(trigger.rule, where_clause text)
    RETURNS text
AS $$
SELECT format(
    'SELECT * FROM trigger_rule.%I($1) WHERE %s;',
    trigger.with_threshold_fn_name($1), $2
);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.drop_rule_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION IF EXISTS trigger_rule.%I(timestamp with time zone)', trigger.rule_fn_name($1));
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_rule_fn_sql(trigger.rule, rule_view_sql text)
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
    ),
    format(
        'GRANT EXECUTE ON FUNCTION trigger_rule.%I(timestamp with time zone) TO minerva',
        trigger.rule_fn_name($1)
    )
];
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.create_rule_fn(trigger.rule, rule_view_sql text)
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.create_rule_fn_sql($1, $2));
$$ LANGUAGE SQL VOLATILE;


--- Function <rule>_kpi

CREATE OR REPLACE FUNCTION trigger.kpi_fn_name(trigger.rule)
    RETURNS name
AS $$
    SELECT ($1.name || '_kpi')::name;
$$ LANGUAGE SQL IMMUTABLE;


--- Function <rule>_fingerprint

CREATE OR REPLACE FUNCTION trigger.create_fingerprint_fn_sql(trigger.rule, fn_sql text)
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


CREATE OR REPLACE FUNCTION trigger.create_fingerprint_fn_sql(trigger.rule)
    RETURNS text
AS $$
    SELECT trigger.create_fingerprint_fn_sql(
        $1,
        $fn_body$SELECT now()::text;$fn_body$
    );
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.create_fingerprint_fn(trigger.rule)
    RETURNS trigger.rule
AS $$
    SELECT public.action($1, trigger.create_fingerprint_fn_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.drop_fingerprint_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION IF EXISTS trigger_rule.%I(timestamp with time zone)', trigger.fingerprint_fn_name($1));
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.drop_fingerprint_fn(trigger.rule)
    RETURNS trigger.rule
AS $$
    SELECT public.action($1, trigger.drop_fingerprint_fn_sql($1));
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.set_fingerprint(trigger.rule, fn_sql text)
    RETURNS trigger.rule
AS $$
    SELECT public.action($1, trigger.create_fingerprint_fn_sql($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.set_fingerprint(name, fn_sql text)
    RETURNS name
AS $$
    SELECT
        public.action($1, trigger.create_fingerprint_fn_sql(rule, $2))
    FROM trigger.rule
    WHERE name = $1;
$$ LANGUAGE sql VOLATILE;


--- Function <rule>_runnable

CREATE OR REPLACE FUNCTION trigger.create_runnable_fn_sql(trigger.rule, fn_body text)
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


CREATE OR REPLACE FUNCTION trigger.create_runnable_fn_sql(trigger.rule)
    RETURNS text
AS $$
    SELECT trigger.create_runnable_fn_sql($1, 'SELECT TRUE;');
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.create_runnable_fn(trigger.rule)
    RETURNS trigger.rule
AS $$
    SELECT public.action($1, trigger.create_runnable_fn_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.drop_runnable_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION trigger_rule.%I(timestamp with time zone)', trigger.runnable_fn_name($1));
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.set_runnable(trigger.rule, fn_sql text)
    RETURNS trigger.rule
AS $$
    SELECT public.action($1, trigger.create_runnable_fn_sql($1, $2));
$$ LANGUAGE sql VOLATILE;


--- Function <rule>_notification_message


CREATE OR REPLACE FUNCTION trigger.get_function_def(schema_name name, fn_name name)
    RETURNS text
AS $$
SELECT
	pg_get_functiondef(pg_proc.oid)
FROM pg_proc
JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
WHERE pg_namespace.nspname = $1 AND proname = $2;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.get_notification_message_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT trigger.get_function_def('trigger_rule', trigger.notification_message_fn_name($1));
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.notification_message_fn_sql(trigger.rule, expression text)
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
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.drop_notification_message_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION trigger_rule.%I(trigger_rule.%I)',
    trigger.notification_message_fn_name($1),
    trigger.details_type_name($1)
);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_notification_message_fn(trigger.rule, expression text)
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
            ),
            format(
                'GRANT EXECUTE ON FUNCTION trigger_rule.%I(trigger_rule.%I) TO minerva',
                trigger.notification_message_fn_name($1),
                trigger.details_type_name($1)
            )
        ]
    );
$$ LANGUAGE SQL VOLATILE;


--- Function <rule>_notification



CREATE OR REPLACE FUNCTION trigger.notification_fn_sql(trigger.rule)
    RETURNS text
AS $function$
SELECT format(
    'CREATE OR REPLACE FUNCTION trigger_rule.%I(timestamp with time zone)
    RETURNS SETOF trigger.notification
AS $fn$
SELECT
    n.entity_id,
    n.timestamp,
    COALESCE(exc.weight, trigger_rule.%I(n)) AS weight,
    trigger_rule.%I(n) AS details
FROM trigger_rule.%I($1) AS n
LEFT JOIN trigger_rule.%I AS exc ON
    exc.entity_id = n.entity_id AND
    exc.start <= n.timestamp AND
    exc.expires > n.timestamp $fn$ LANGUAGE sql STABLE',
    trigger.notification_fn_name($1),
    trigger.weight_fn_name($1),
    trigger.notification_message_fn_name($1),
    $1.name,
    trigger.exception_weight_table_name($1)
);
$function$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.drop_notification_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION trigger_rule.%I(timestamp with time zone)', trigger.notification_fn_name($1));
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_notification_fn_sql(trigger.rule)
    RETURNS text[]
AS $$
SELECT ARRAY[
    trigger.notification_fn_sql($1),
    format('ALTER FUNCTION trigger_rule.%I(timestamp with time zone) OWNER TO minerva_admin', trigger.notification_fn_name($1)),
    format('GRANT EXECUTE ON FUNCTION trigger_rule.%I(timestamp with time zone) TO minerva', trigger.notification_fn_name($1))
];
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notification_fn(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.create_notification_fn_sql($1));
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


--- Function <rule>_with_threshold


CREATE OR REPLACE FUNCTION trigger.get_threshold_defs(trigger.rule)
    RETURNS SETOF trigger.threshold_def AS
$$
    SELECT (attname, typname)::trigger.threshold_def
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


CREATE OR REPLACE FUNCTION trigger.has_thresholds(trigger.rule)
    RETURNS boolean
AS $$
    SELECT EXISTS(
        SELECT 1
        FROM pg_class
        WHERE relname = trigger.threshold_view_name($1) AND relkind = 'v'
    );
$$ LANGUAGE sql STABLE;

COMMENT ON FUNCTION trigger.has_thresholds(trigger.rule) IS
'Return true if there is a view with thresholds for the specified rule';


CREATE OR REPLACE FUNCTION trigger.with_threshold_fn_sql_normal(trigger.rule)
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

CREATE OR REPLACE FUNCTION trigger.with_threshold_fn_sql_no_thresholds(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'SELECT * FROM trigger_rule.%I($1)',
    trigger.kpi_fn_name($1)
);
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.with_threshold_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT CASE WHEN trigger.has_thresholds($1) THEN
    trigger.with_threshold_fn_sql_normal($1)
ELSE
    trigger.with_threshold_fn_sql_no_thresholds($1)
END;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trigger.create_with_threshold_fn(trigger.rule)
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
        ),
        format(
            'GRANT EXECUTE ON FUNCTION trigger_rule.%I(timestamp with time zone) TO minerva',
            trigger.with_threshold_fn_name($1)
        )
    ]
);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.drop_with_threshold_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP FUNCTION trigger_rule.%I', trigger.with_threshold_view_name($1));
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


COMMENT ON FUNCTION trigger.get_weight_fn_sql(trigger.rule) IS
'Return current implementation of the weight function for specified rule.';


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
        trigger.details_type_name($1),
        $2
    );
$$ LANGUAGE SQL IMMUTABLE;


COMMENT ON FUNCTION trigger.weight_fn_sql(trigger.rule, expression text) IS
'Return code to create weight function based on the provided expression.';


CREATE OR REPLACE FUNCTION trigger.drop_weight_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION trigger_rule.%I(trigger_rule.%I)',
    trigger.weight_fn_name($1),
    trigger.kpi_type_name($1)
);
$$ LANGUAGE SQL IMMUTABLE;


COMMENT ON FUNCTION trigger.drop_weight_fn_sql(trigger.rule) IS
'Return code to drop weight function for specified rule.';

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


COMMENT ON FUNCTION trigger.exception_weight_table_sql(trigger.rule) IS
'Return code to create the exception weight table for specified rule.';


CREATE OR REPLACE FUNCTION trigger.create_exception_weight_table(trigger.rule)
    RETURNS trigger.rule AS
$$
SELECT public.action($1, trigger.exception_weight_table_sql($1));
SELECT public.action($1, format('ALTER TABLE trigger_rule.%I OWNER TO minerva_admin', trigger.exception_weight_table_name($1)));
SELECT public.action($1, format('GRANT SELECT ON trigger_rule.%I TO minerva', trigger.exception_weight_table_name($1)));
SELECT public.action($1, format('GRANT INSERT, UPDATE, DELETE ON trigger_rule.%I TO minerva_writer', trigger.exception_weight_table_name($1)));
SELECT public.action($1, format(
    'GRANT USAGE, SELECT ON SEQUENCE %s TO minerva_writer',
    pg_get_serial_sequence(format('trigger_rule.%I', trigger.exception_weight_table_name($1)), 'id')
));
$$ LANGUAGE SQL VOLATILE;


COMMENT ON FUNCTION trigger.create_exception_weight_table(trigger.rule) IS
'Create the exception weight table for specified rule.';


CREATE OR REPLACE FUNCTION trigger.drop_exception_weight_table_sql(trigger.rule)
    RETURNS text AS
$$
SELECT format('DROP TABLE IF EXISTS trigger_rule.%I', trigger.exception_weight_table_name($1));
$$ LANGUAGE SQL IMMUTABLE;


COMMENT ON FUNCTION trigger.drop_exception_weight_table_sql(trigger.rule) IS
'Return code to drop the exception weight table for specified rule.';


--- Notification fn setting


CREATE OR REPLACE FUNCTION trigger.define_notification(name, expression text)
    RETURNS trigger.rule
AS $$
    SELECT trigger.create_notification_message_fn(trigger.get_rule($1), $2);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_dummy_notification_message_fn(trigger.rule)
    RETURNS trigger.rule
AS $$
    SELECT trigger.create_notification_message_fn($1, quote_literal($1.name));
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

CREATE OR REPLACE FUNCTION trigger.create_exception_threshold_table_sql(trigger.rule, trigger.threshold_def[])
    RETURNS text AS
$$
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

$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION trigger.drop_exception_threshold_table_sql(trigger.rule)
    RETURNS text AS
$$
SELECT format('DROP TABLE IF EXISTS trigger_rule.%I', trigger.exception_threshold_table_name($1))
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_exception_threshold_table(trigger.rule, trigger.threshold_def[])
    RETURNS trigger.rule AS
$$
SELECT public.action($1, trigger.create_exception_threshold_table_sql($1, $2));
SELECT public.action($1, format('ALTER TABLE trigger_rule.%I OWNER TO minerva_admin', trigger.exception_threshold_table_name($1)));
SELECT public.action($1, format('GRANT SELECT ON trigger_rule.%I TO minerva', trigger.exception_threshold_table_name($1)));
SELECT public.action($1, format('GRANT INSERT, UPDATE, DELETE ON trigger_rule.%I TO minerva_writer', trigger.exception_threshold_table_name($1)));
SELECT public.action($1, format(
    'GRANT USAGE, SELECT ON SEQUENCE %s TO minerva_writer',
    pg_get_serial_sequence(format('trigger_rule.%I', trigger.exception_threshold_table_name($1)), 'id')
));
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
    relname = "trigger".kpi_type_name($1) AND
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
    SELECT public.action($1, trigger.create_set_thresholds_fn_sql($1));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.drop_set_thresholds_fn_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format(
    'DROP FUNCTION IF EXISTS trigger_rule.%I(%s)',
    trigger.set_thresholds_fn_name($1),
    array_to_string(array_agg(format('%s', t.data_type)), ', ')
)
FROM trigger.get_threshold_defs($1) t;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.drop_thresholds_view_sql(trigger.rule)
    RETURNS text
AS $$
SELECT format('DROP VIEW IF EXISTS trigger_rule.%I', trigger.threshold_view_name($1))
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.set_thresholds(trigger.rule, exprs text)
    RETURNS trigger.rule
AS $$
    SELECT public.action(
        $1,
        ARRAY[
            format(
                'CREATE OR REPLACE VIEW trigger_rule.%I AS '
                'SELECT %s',
                trigger.threshold_view_name($1),
                $2
            ),
            format(
                'ALTER VIEW trigger_rule.%I OWNER TO minerva_admin',
                trigger.threshold_view_name($1)
            ),
            format(
                'GRANT SELECT ON trigger_rule.%I TO minerva',
                trigger.threshold_view_name($1)
            )
        ]
    );
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE OR REPLACE FUNCTION trigger.set_thresholds(name, exprs text)
    RETURNS trigger.rule
AS $$
    SELECT trigger.set_thresholds(trigger.get_rule($1), $2);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_dummy_thresholds(trigger.rule, trigger.threshold_def[])
    RETURNS trigger.rule
AS $$
    SELECT trigger.set_thresholds(
        $1,
        array_to_string(array_agg(format('NULL::%s %I', threshold.data_type, threshold.name)), ', ')
    ) FROM unnest($2) threshold;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.set_weight(trigger.rule, expression text)
    RETURNS trigger.rule
AS $$
    SELECT public.action(
        $1,
        ARRAY[
            trigger.weight_fn_sql($1, $2),
            format(
                'ALTER FUNCTION trigger_rule.%I(trigger_rule.%I) OWNER TO minerva_admin',
                trigger.weight_fn_name($1),
                trigger.details_type_name($1)
            ),
            format(
                'GRANT EXECUTE ON FUNCTION trigger_rule.%I(trigger_rule.%I) TO minerva',
                trigger.weight_fn_name($1),
                trigger.details_type_name($1)
            )
        ]
    );
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


CREATE OR REPLACE FUNCTION trigger.insert_state(integer, timestamp with time zone, text)
    RETURNS trigger.rule_state
AS $$
    INSERT INTO trigger.rule_state (rule_id, timestamp, fingerprint)
    VALUES ($1, $2, $3)
    RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.update_state(integer, timestamp with time zone, text)
    RETURNS trigger.rule_state
AS $$
    UPDATE trigger.rule_state SET fingerprint = $3
    WHERE rule_id = $1 AND timestamp = $2
    RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.set_state(integer, timestamp with time zone, text)
    RETURNS trigger.rule_state
AS $$
    SELECT coalesce(
        trigger.update_state($1, $2, $3),
        trigger.insert_state($1, $2, $3)
    );
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.set_state(trigger.rule, timestamp with time zone)
    RETURNS trigger.rule
AS $$
BEGIN
    EXECUTE format(
        'SELECT trigger.set_state($1, $2, trigger_rule.%I($2))',
        trigger.fingerprint_fn_name($1)
    ) USING $1.id, $2;

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION trigger.function_oid(
        obj_schema name, obj_name name, signature text[])
    RETURNS oid
AS $$
SELECT
    bar.oid
FROM (
    SELECT foo.oid, array_agg(dep_recurse.type_to_char(foo.t)) sig
    FROM (
        SELECT pg_proc.oid, unnest(pg_proc.proargtypes) t
        FROM pg_proc
        JOIN pg_namespace ON pg_namespace.oid = pg_proc.pronamespace
        WHERE nspname = $1 AND proname = $2
    ) foo
    JOIN pg_type ON foo.t = pg_type.oid
    GROUP BY foo.oid
) bar
WHERE bar.sig = $3;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.has_notification_function(trigger.rule)
    RETURNS boolean
AS $$
SELECT trigger.function_oid('trigger_rule', trigger.notification_fn_name($1), ARRAY['pg_catalog.timestamptz']::text[]) IS NOT NULL;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.create_notifications_classic(trigger.rule, notification.notificationstore, timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    num_rows integer;
BEGIN
    IF $2 IS NULL THEN
        RAISE EXCEPTION 'no notificationstore specified';
    END IF;

    PERFORM trigger.set_state($1, $3);

    EXECUTE format(
$query$
INSERT INTO notification.%I(entity_id, timestamp, created, rule_id, weight, details)
(SELECT entity_id, timestamp, now(), $1, weight, details FROM trigger_rule.%I WHERE timestamp = $2)
$query$,
        notification.staging_table_name($2), trigger.notification_fn_name($1)
    )
    USING $1.id, $3;

    SELECT trigger.transfer_notifications_from_staging($2) INTO num_rows;

    RETURN num_rows;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notifications_new(trigger.rule, notification.notificationstore, timestamp with time zone)
    RETURNS integer
AS $$
DECLARE
    num_rows integer;
BEGIN
    IF $2 IS NULL THEN
        RAISE EXCEPTION 'no notificationstore specified';
    END IF;

    PERFORM trigger.set_state($1, $3);

    EXECUTE format(
$query$
INSERT INTO notification.%I(entity_id, timestamp, created, rule_id, weight, details)
(SELECT entity_id, timestamp, now(), $1, weight, details FROM trigger_rule.%I($2))
$query$,
        notification.staging_table_name($2), trigger.notification_fn_name($1)
    )
    USING $1.id, $3;

    SELECT trigger.transfer_notifications_from_staging($2) INTO num_rows;

    RETURN num_rows;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_notifications(trigger.rule, notification.notificationstore, timestamp with time zone)
    RETURNS integer
AS $$
SELECT CASE WHEN trigger.has_notification_function($1) THEN
    trigger.create_notifications_new($1, $2, $3)
ELSE
    trigger.create_notifications_classic($1, $2, $3)
END;
$$ LANGUAGE sql VOLATILE;


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
WITH notifications AS (SELECT entity_id, timestamp, weight, details FROM trigger_rule.%I WHERE timestamp > now() - $2)
INSERT INTO notification.%I(entity_id, timestamp, created, rule_id, weight, details)
(SELECT entity_id, timestamp, clock_timestamp(), $1, weight, details FROM notifications)
$query$,
        trigger.notification_view_name($1), notification.staging_table_name($2)
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
    LEFT JOIN notification.notificationstore ON notificationstore.id = rule.notificationstore_id
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


-- Type <rule>_details

CREATE OR REPLACE FUNCTION trigger.create_details_type_sql(trigger.rule, trigger.threshold_def[])
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
$$ LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.drop_details_type_sql(trigger.rule)
    RETURNS text
AS $$
    SELECT format('DROP TYPE IF EXISTS trigger_rule.%I;', trigger.details_type_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.create_details_type(trigger.rule, trigger.threshold_def[])
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.create_details_type_sql($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.drop_details_type(trigger.rule)
    RETURNS trigger.rule
AS $$
SELECT public.action($1, trigger.drop_details_type_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.define_thresholds(trigger.rule, trigger.threshold_def[])
    RETURNS trigger.rule
AS $$
    SELECT trigger.create_details_type($1, $2);
    SELECT CASE WHEN array_length($2, 1) > 0 THEN
        trigger.create_dummy_thresholds($1, $2)
    END;
    SELECT CASE WHEN array_length($2, 1) > 0 THEN
        trigger.create_set_thresholds_fn($1)
    END;
    SELECT trigger.create_exception_threshold_table($1, $2);
    SELECT trigger.create_with_threshold_fn($1);
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trigger.set_condition(trigger.rule, sql text)
    RETURNS trigger.rule
AS $$
    SELECT trigger.create_rule_fn($1, trigger.rule_fn_sql($1, $2));
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.set_condition(name, sql text)
    RETURNS trigger.rule
AS $$
    SELECT trigger.set_condition(rule, $2)
    FROM trigger.rule WHERE name = $1;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.setup_rule(trigger.rule, trigger.threshold_def[])
    RETURNS trigger.rule
AS $$
    SELECT trigger.define_thresholds($1, $2);
    SELECT trigger.create_exception_weight_table($1);
    SELECT trigger.create_dummy_default_weight($1);
    SELECT trigger.create_dummy_notification_message_fn($1);
    SELECT trigger.set_condition($1, 'true');
    SELECT trigger.create_notification_fn($1);
    SELECT trigger.create_fingerprint_fn($1);
    SELECT trigger.create_runnable_fn($1);
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.create_rule(name, trigger.threshold_def[])
    RETURNS trigger.rule
AS $$
    SELECT trigger.setup_rule(trigger.define($1), $2);
$$ LANGUAGE SQL VOLATILE;


COMMENT ON FUNCTION trigger.create_rule(name, trigger.threshold_def[]) IS
'Define a new rule and create accompanyning functions and views.

.. IMPORTANT::
   A KPI function <trigger_name>_kpi(timestamp with time zone) must already
   exist.';


CREATE OR REPLACE FUNCTION trigger.drop_kpi_fn_sql(trigger.rule)
    RETURNS text
AS $$
    SELECT format('DROP FUNCTION IF EXISTS trigger_rule.%I(timestamp with time zone)', trigger.kpi_fn_name($1));
$$ LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION trigger.cleanup_rule(trigger.rule)
    RETURNS trigger.rule
AS $$
    SELECT public.action(
        $1,
        ARRAY[
            trigger.drop_runnable_fn_sql($1),
            trigger.drop_fingerprint_fn_sql($1),
            trigger.drop_set_thresholds_fn_sql($1),
            trigger.drop_rule_fn_sql($1),
            trigger.drop_kpi_fn_sql($1),
            trigger.drop_kpi_type_sql($1),
            -- trigger.drop_notification_fn_sql($1),
            -- trigger.drop_notification_view_sql($1),
            -- trigger.drop_with_threshold_view_sql($1),
            -- trigger.drop_weight_fn_sql($1),
            trigger.drop_exception_weight_table_sql($1),
            trigger.drop_thresholds_view_sql($1),
            trigger.drop_exception_threshold_table_sql($1),
            trigger.drop_notification_type_sql($1),
            trigger.drop_details_type_sql($1)
        ]
    );
$$ LANGUAGE sql VOLATILE;


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


CREATE OR REPLACE FUNCTION trigger.tag(tag_name character varying, rule_name name)
    RETURNS trigger.rule_tag_link
AS $$
    SELECT trigger.tag($1, rule.id)
    FROM trigger.rule
    WHERE name = $2;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.truncate(timestamp with time zone, interval)
    RETURNS timestamp with time zone
AS $$
    SELECT CASE
        WHEN $2 = '1 week' THEN
            date_trunc('week', $1)
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
    SELECT ts FROM generate_series(
        trigger.truncate(now(), $1.granularity),
        trigger.truncate(now(), $1.granularity) - $1.default_interval,
        - $1.granularity
    ) gs(ts)
    WHERE ts >= now() - $1.default_interval;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.contains_null(anyarray)
    RETURNS boolean
AS $$
SELECT EXISTS (
    SELECT 1
    FROM unnest($1) x
    WHERE x IS NULL
);
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.modified_to_fingerprint(timestamp with time zone[])
    RETURNS text
AS $$
SELECT CASE
WHEN trigger.contains_null($1) THEN
    NULL
WHEN array_length($1, 1) = 0 THEN
    NULL
ELSE
    (
        SELECT '[' || array_to_string(array_agg(format('"%s"', t)), ',') || ']' FROM unnest($1) t
    )
END;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.fingerprint(trigger.rule, timestamp with time zone)
    RETURNS text
AS $$
BEGIN
    RETURN QUERY EXECUTE format('SELECT trigger_rule.%I($1)', trigger.fingerprint_fn_name($1)) USING $2;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE OR REPLACE FUNCTION trigger.kpi_def_arr_from_type(namespace name, "type" name)
    RETURNS trigger.kpi_def[]
AS $$
    SELECT array_agg((col.name, col.data_type)::trigger.kpi_def)
    FROM public.type_columns($1, $2) col
    WHERE col.name NOT IN ('entity_id', 'timestamp');
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.kpi_def_arr_from_proc(oid)
    RETURNS trigger.kpi_def[]
AS $$
    SELECT array_agg((col.name, col.data_type)::trigger.kpi_def)
    FROM public.type_columns(public.prorettype($1)) col
    WHERE col.name NOT IN ('entity_id', 'timestamp');
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION trigger.backup_essentials(trigger.rule)
    RETURNS trigger.rule
AS $$
    INSERT INTO trigger.rule_backup(id, name, notificationstore_id, granularity, default_interval, enabled)
    VALUES($1.id, $1.name, $1.notificationstore_id, $1.granularity, $1.default_interval, $1.enabled);

    SELECT public.action(
        $1,
        format(
            'CREATE TABLE trigger_rule.%I AS SELECT * FROM trigger_rule.%I',
            trigger.exception_weight_table_name($1) || '_bak',
            trigger.exception_weight_table_name($1)
        )
    );

    SELECT public.action(
        $1,
        format(
            'CREATE TABLE trigger_rule.%I AS SELECT * FROM trigger_rule.%I',
            trigger.exception_threshold_table_name($1) || '_bak',
            trigger.exception_threshold_table_name($1)
        )
    );

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.remove_backup(trigger.rule)
    RETURNS trigger.rule
AS $$
    DELETE FROM trigger.rule_backup WHERE name = $1.name;

    SELECT public.action(
        $1,
        format(
            'DROP TABLE IF EXISTS trigger_rule.%I',
            trigger.exception_weight_table_name($1) || '_bak'
        )
    );

    SELECT public.action(
        $1,
        format(
            'DROP TABLE IF EXISTS trigger_rule.%I',
            trigger.exception_threshold_table_name($1) || '_bak'
        )
    );

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION trigger.restore_essentials(trigger.rule)
    RETURNS trigger.rule
AS $$
    UPDATE trigger.rule SET
        id = backup.id,
        notificationstore_id = backup.notificationstore_id,
        granularity = backup.granularity,
        default_interval = backup.default_interval,
        enabled = backup.enabled
    FROM trigger.rule_backup backup
    WHERE backup.name = $1.name AND rule.name = $1.name;

    SELECT public.action(
        $1,
        format(
            'INSERT INTO trigger_rule.%I SELECT * FROM trigger_rule.%I',
            trigger.exception_weight_table_name($1),
            trigger.exception_weight_table_name($1) || '_bak'
        )
    );

    SELECT public.action(
        $1,
        format(
            'INSERT INTO trigger_rule.%I SELECT * FROM trigger_rule.%I',
            trigger.exception_threshold_table_name($1),
            trigger.exception_threshold_table_name($1) || '_bak'
        )
    );

    SELECT $1;
$$ LANGUAGE sql VOLATILE;

