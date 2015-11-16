-- View 'trend_ext'

CREATE OR REPLACE VIEW materialization.trend_ext AS
SELECT
	t.id,
	t.name,
	ds.name AS datasource_name,
	et.name AS entitytype_name,
	ts.granularity,
	CASE
		WHEN m.src_trendstore_id IS NULL THEN false
		ELSE true
	END AS materialized
	FROM trend.trend t
	JOIN trend.trendstore_trend_link ttl ON ttl.trend_id = t.id
	JOIN trend.trendstore ts ON ts.id = ttl.trendstore_id
	JOIN directory.datasource ds ON ds.id = ts.datasource_id
	JOIN directory.entitytype et ON et.id = ts.entitytype_id
	LEFT JOIN materialization.type m ON m.src_trendstore_id = ts.id;

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
    state.fingerprint <> staged.fingerprint;

ALTER VIEW materialization.modified_state_fingerprint OWNER TO minerva_admin;

GRANT ALL ON materialization.modified_state_fingerprint TO minerva_admin;

GRANT ALL ON materialization.modified_state_fingerprint TO minerva_admin;
GRANT SELECT ON materialization.modified_state_fingerprint TO minerva;

