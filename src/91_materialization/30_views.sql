-- View 'trend_ext'

CREATE OR REPLACE VIEW materialization.trend_ext AS
SELECT
	t.id,
	t.name,
	ds.name AS datasource_name,
	et.name AS entitytype_name,
	ts.granularity,
	m.dst_trendstore_id IS MOT NULL AS materialized
	FROM trend.trend t
	JOIN trend.trendstore_trend_link ttl ON ttl.trend_id = t.id
	JOIN trend.trendstore ts ON ts.id = ttl.trendstore_id
	JOIN directory.datasource ds ON ds.id = ts.datasource_id
	JOIN directory.entitytype et ON et.id = ts.entitytype_id
	LEFT JOIN materialization.type m ON m.dst_trendstore_id = ts.id;

COMMENT ON VIEW materialization.trend_ext IS
'Convenience view for easy lookup of trends';


ALTER VIEW materialization.trend_ext OWNER TO minerva_admin;

GRANT SELECT ON TABLE materialization.trend_ext TO minerva;


-- View 'new_state_fingerprint'

CREATE OR REPLACE VIEW materialization.new_state_fingerprint AS
SELECT
    staged.type_id,
    staged.timestamp,
    staged.fingerprint,
    staged.modified
FROM materialization.state_fingerprint_staging staged
LEFT JOIN materialization.state_fingerprint state ON
    state.type_id = staged.type_id AND
    state.timestamp = staged.timestamp
WHERE state.type_id IS NULL;

ALTER VIEW materialization.new_state_fingerprint OWNER TO minerva_admin;

GRANT ALL ON materialization.new_state_fingerprint TO minerva_admin;

GRANT ALL ON materialization.new_state_fingerprint TO minerva_admin;
GRANT SELECT ON materialization.new_state_fingerprint TO minerva;


-- View 'modified_state_fingerprint'

CREATE OR REPLACE VIEW materialization.modified_state_fingerprint AS
SELECT
    staged.type_id,
    staged.timestamp,
    staged.fingerprint,
    staged.modified
FROM materialization.state_fingerprint_staging staged
JOIN materialization.state_fingerprint state ON
    state.type_id = staged.type_id AND
    state.timestamp = staged.timestamp AND
    (state.fingerprint <> staged.fingerprint OR state.fingerprint IS NULL);

ALTER VIEW materialization.modified_state_fingerprint OWNER TO minerva_admin;

GRANT ALL ON materialization.modified_state_fingerprint TO minerva_admin;

GRANT ALL ON materialization.modified_state_fingerprint TO minerva_admin;
GRANT SELECT ON materialization.modified_state_fingerprint TO minerva;



CREATE OR REPLACE VIEW system.materialization_job_stats AS
WITH raw_stats AS (
    SELECT
        ((description::json)->>'type_id')::integer as type_id,
        created,
        ((description::json)->>'timestamp')::timestamptz as timestamp,
        finished - started as duration
    FROM system.job_finished
    WHERE type = 'materialize'
    UNION ALL
    SELECT
        ((description::json)->>'type_id')::integer as type_id,
        created,
        ((description::json)->>'timestamp')::timestamptz as timestamp,
        NULL as duration
    FROM system.job
    WHERE type = 'materialize'
)
SELECT
    type::text AS type,
    created,
    timestamp,
    duration,
    created - timestamp AS creation_delay
FROM raw_stats
JOIN materialization.type ON type.id = raw_stats.type_id;
