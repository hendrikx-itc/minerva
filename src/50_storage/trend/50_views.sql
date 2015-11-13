CREATE VIEW trend.attribute_to_trend_todo AS
SELECT foo.processed_modified IS NOT NULL AND foo.processed_modified >= foo.compacted AS done, *
FROM (
        SELECT
            s.id attribute_to_trend_id,
            granularity,
            trend.get_most_recent_timestamp(s.granularity, now()) AS timestamp,
            processed_modified,
            attributestore_compacted.compacted
        FROM trend.attribute_to_trend s
        LEFT JOIN trend.attribute_to_trend_state att ON att.attribute_to_trend_id = s.id AND att.timestamp = trend.get_most_recent_timestamp(s.granularity, now())
        LEFT JOIN attribute_directory.attributestore_compacted ON attributestore_compacted.attributestore_id = s.attributestore_id
        WHERE s.enabled
) foo;

GRANT SELECT ON trend.attribute_to_trend_todo TO minerva;

