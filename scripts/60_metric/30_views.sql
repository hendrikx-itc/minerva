CREATE OR REPLACE VIEW metric.replication_lag AS
SELECT
    pg_stat_replication.client_addr,
    public.wal_location_to_int(pg_current_xlog_location()) - public.wal_location_to_int(pg_stat_replication.replay_location) AS bytes_lag
FROM pg_stat_replication;
