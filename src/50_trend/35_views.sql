-- View 'tagged_runnable_materializations'

CREATE VIEW trend_directory.tagged_runnable_materializations AS
    SELECT mstate.materialization_id, timestamp, t.name as tag
        FROM trend_directory.state mstate
        JOIN trend_directory.materialization_tag_link mtl ON mtl.materialization_id = mstate.materialization_id
        JOIN directory.tag t ON t.id = mtl.tag_id
        JOIN trend_directory.materialization mt ON mt.id = mstate.materialization_id
        JOIN trend_directory.table_trend_store ts ON ts.id = mt.dst_trend_store_id
        LEFT JOIN system.job j ON j.id = mstate.job_id
        WHERE
            trend_directory.requires_update(mstate)
            AND (j.id IS NULL OR NOT j.state IN ('queued', 'running'))
            AND trend_directory.runnable(mt, timestamp, max_modified)
        ORDER BY ts.granularity ASC, timestamp DESC;

GRANT SELECT ON trend_directory.tagged_runnable_materializations TO minerva;

