CREATE TYPE trigger_rule.high_traffic_kpi AS (
    entity_id integer,
    timestamp timestamp with time zone,
    traffic bigint
);
