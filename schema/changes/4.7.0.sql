CREATE TABLE trend.modified_new (
    trend_store_id integer not null REFERENCES trend.trend_store(id) ON UPDATE CASCADE ON DELETE CASCADE,
    timestamp timestamp with time zone not null,
    start timestamp with time zone not null,
    "end" timestamp with time zone not null,
    PRIMARY KEY (trend_store_id, "timestamp")
);

INSERT INTO trend.modified_new(
    trend_store_id,
    timestamp,
    start,
    "end"
) SELECT
    partition.trend_store_id,
    modified.timestamp,
    modified.start,
    modified."end"
FROM trend.modified
JOIN trend.partition ON partition.table_name = modified.table_name;

DROP FUNCTION trend.update_modified(name, timestamp with time zone, timestamp with time zone);
DROP FUNCTION trend.store_modified(name, timestamp with time zone, timestamp with time zone);
DROP FUNCTION trend.mark_modified(name, timestamp with time zone, timestamp with time zone);
DROP FUNCTION trend.mark_modified(name, timestamp with time zone);
DROP FUNCTION trend.populate_modified(trend.partition);
DROP FUNCTION trend.populate_modified(trend.trend_store);
DROP FUNCTION trend.populate_modified(character varying);

DROP TABLE trend.modified;

ALTER TABLE trend.modified_new RENAME TO modified;

CREATE FUNCTION trend.update_modified(trend_store_id integer, "timestamp" timestamp with time zone, modified timestamp with time zone)
    RETURNS trend.modified
AS $$
    UPDATE trend.modified SET "end" = greatest("end", $3) WHERE "timestamp" = $2 AND trend_store_id = $1 RETURNING modified;
$$ LANGUAGE SQL VOLATILE;


CREATE FUNCTION trend.store_modified(trend_store_id integer, "timestamp" timestamp with time zone, modified timestamp with time zone)
    RETURNS trend.modified
AS $$
    INSERT INTO trend.modified (trend_store_id, "timestamp", start, "end") VALUES ($1, $2, $3, $3) RETURNING modified;
$$ LANGUAGE SQL VOLATILE;


CREATE FUNCTION trend.mark_modified(trend_store_id integer, "timestamp" timestamp with time zone, modified timestamp with time zone)
    RETURNS trend.modified
AS $$
    SELECT COALESCE(trend.update_modified($1, $2, $3), trend.store_modified($1, $2, $3));
$$ LANGUAGE SQL VOLATILE;


CREATE FUNCTION trend.mark_modified(trend_store_id integer, "timestamp" timestamp with time zone)
    RETURNS trend.modified
AS $$
    SELECT COALESCE(trend.update_modified($1, $2, now()), trend.store_modified($1, $2, now()));
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.populate_modified(partition trend.partition)
    RETURNS SETOF trend.modified
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT (trend.mark_modified(%L, "timestamp", max(modified))).*
FROM trend.%I GROUP BY timestamp',
        partition.trend_store_id, partition.table_name);
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION trend.populate_modified(trend.trend_store)
    RETURNS SETOF trend.modified
AS $$
    SELECT trend.populate_modified(partition) FROM trend.partition WHERE trend_store_id = $1.id;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION trend.populate_modified(character varying)
    RETURNS SETOF trend.modified
AS $$
    SELECT trend.populate_modified(partition) FROM trend.partition WHERE table_name = $1;
$$ LANGUAGE SQL VOLATILE;


SELECT system.set_version(4, 7, 0);
