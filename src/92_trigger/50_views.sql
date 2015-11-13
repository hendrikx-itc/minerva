CREATE OR REPLACE VIEW trigger.todo AS
SELECT * FROM
(
    SELECT
        rule,
        timestamp,
        stored_fingerprint IS NULL OR current_fingerprint <> stored_fingerprint AS modified
    FROM (
        SELECT rule, t.timestamp, trigger.fingerprint(rule, t.timestamp) current_fingerprint, rule_state.fingerprint AS stored_fingerprint
        FROM (
            SELECT
                rule,
                trigger.timestamps(rule) AS timestamp
            FROM trigger.rule
        ) t
        LEFT JOIN trigger.rule_state ON rule_state.rule_id = (t.rule).id AND rule_state.timestamp = t.timestamp
    ) tt
    WHERE current_fingerprint IS NOT null
) ttt
WHERE modified;

GRANT SELECT ON trigger.todo TO minerva;
