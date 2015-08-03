CREATE VIEW trend.attribute_to_trend_todo AS
SELECT foo.processed_modified IS NOT NULL AND foo.processed_modified >= foo.modified AS done, *
FROM (
        SELECT
            s.id attribute_to_trend_id,
            granularity,
            trend.get_most_recent_timestamp(s.granularity, now()) AS timestamp,
            processed_modified,
            modified
        FROM trend.attribute_to_trend s
        LEFT JOIN trend.attribute_to_trend_state att ON att.attribute_to_trend_id = s.id AND att.timestamp = trend.get_most_recent_timestamp(s.granularity, now())
        LEFT JOIN attribute_directory.attributestore_modified m ON m.attributestore_id = s.attributestore_id
) foo;

GRANT SELECT ON trend.attribute_to_trend_todo TO minerva;
