CREATE VIEW metric.replication_lag AS
SELECT
    pg_stat_replication.client_addr,
    pg_current_xlog_location() - pg_stat_replication.replay_location AS bytes_lag
FROM pg_stat_replication;
