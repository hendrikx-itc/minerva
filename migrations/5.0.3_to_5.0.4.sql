

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,0,4)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


DROP FUNCTION "trigger"."create_notification_fn_sql"(trigger.rule, text);

DROP FUNCTION "trigger"."create_notification_fn"(trigger.rule, text);

DROP FUNCTION "trigger"."define_notification"(name, text);

DROP FUNCTION "trigger"."create_dummy_notification_fn"(trigger.rule);

CREATE TABLE "trigger"."rule_trend_store_link"
(
  "rule_id" integer NOT NULL,
  "trend_store_part_id" integer NOT NULL,
  "timestamp_mapping_func" regprocedure NOT NULL,
  PRIMARY KEY (rule_id, trend_store_part_id)
);

COMMENT ON TABLE "trigger"."rule_trend_store_link" IS 'Stores the dependencies between a trigger rule and its source table trend store parts. Multiple levels of views and functions may exist between a materialization and its source table trend stores. These intermediate views and functions are not registered here, but only the table trend stores containing the actual source data used in the trigger rule.
The timestamp_mapping_func column stores the function to map a timestamp of the source (trend_store_part) to a timestamp of the target notification.
';

COMMENT ON COLUMN "trigger"."rule_trend_store_link"."rule_id" IS 'Reference to a trigger rule.';

COMMENT ON COLUMN "trigger"."rule_trend_store_link"."trend_store_part_id" IS 'Reference to a trend_store_part that is a source of the materialization referenced by materialization_id.
';

COMMENT ON COLUMN "trigger"."rule_trend_store_link"."timestamp_mapping_func" IS 'The function that maps timestamps in the source table to timestamps in the materialized data. For example, for a view for an hour aggregation from 15 minute granularity data will need to map 4 timestamps in the source to 1 timestamp in the resulting data.
';



CREATE FUNCTION "trigger"."define_notification_message"(name, "expression" text)
    RETURNS trigger.rule
AS $$
SELECT trigger.create_notification_message_fn(trigger.get_rule($1), $2);
$$ LANGUAGE sql VOLATILE;
