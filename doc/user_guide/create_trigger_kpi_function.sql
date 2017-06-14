CREATE FUNCTION trigger_rule.high_traffic_kpi(timestamp with time zone)
    RETURNS SETOF trigger_rule.high_traffic_kpi
AS $$
BEGIN
    RETURNS QUERY EXECUTE $query$
    SELECT entity_id, timestamp, traffic
    FROM trend."network-measurements_Port_qtr"
    WHERE timestamp = $1
    $query$ USING $1;
END;
$$ LANGUAGE plpgsql STABLE;

