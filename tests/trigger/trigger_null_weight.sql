BEGIN;

SELECT plan(3);

SELECT directory.create_entity_type('Cell');

SELECT directory.create_data_source('default_ds');

SELECT notification_directory.create_notification_store('default_ds');

CREATE OR REPLACE VIEW trend."vtransform-accessibility-cell_qtr" AS
SELECT * FROM (
	VALUES
	((entity."to_Cell"('4321')).id, '2014-03-06 14:00+01'::timestamp with time zone, 34, 0.99),
	((entity."to_Cell"('4322')).id, '2014-03-06 14:00+01'::timestamp with time zone, 44, 0.94)
) dummy_values(entity_id, timestamp, "Drops", "CSSRSpeech");

ALTER VIEW trend."vtransform-accessibility-cell_qtr" OWNER TO minerva_admin;
GRANT SELECT ON TABLE trend."vtransform-accessibility-cell_qtr" TO minerva;

CREATE TYPE trigger_rule."3G/quarterly/badCssrSpeech_kpi" AS (
   entity_id integer,
   timestamp timestamp with time zone,
   "Drops" numeric,
   "CSSRSpeech" numeric
);

CREATE FUNCTION trigger_rule."3G/quarterly/badCssrSpeech_kpi"(timestamp with time zone)
  RETURNS SETOF trigger_rule."3G/quarterly/badCssrSpeech_kpi"
  AS $$
	SELECT entity_id, timestamp, "Drops"::numeric, "CSSRSpeech"::numeric
	  FROM trend."vtransform-accessibility-cell_qtr";
     $$ LANGUAGE sql STABLE;

SELECT trigger.create_rule(
  '3G/quarterly/badCssrSpeech',
  ARRAY[('threshold_Drops', 'numeric'), ('threshold_CSSRSpeech', 'numeric')]::trigger.threshold_def[]
);

-- SELECT trigger.create_rule(
--	'3G/quarterly/badCssrSpeech',
-- $$
--	SELECT entity_id, timestamp, "Drops", "CSSRSpeech"
--	FROM trend."vtransform-accessibility-cell_qtr"
-- $$,
-- ARRAY['Drops', 'CSSRSpeech'],
-- $$
--	"Drops" > "threshold_Drops" AND
--	"CSSRSpeech" < "threshold_CSSRSpeech"
-- $$);


UPDATE trigger.rule
  SET notification_store_id = (trigger.create_trigger_notification_store('test')).id,
    granularity = '15 minutes'
  WHERE name = '3G/quarterly/badCssrSpeech';

SELECT has_table('notification'::name, 'test'::name);


SELECT trigger.set_thresholds(
	'3G/quarterly/badCssrSpeech',
$$
	15::numeric AS "threshold_Drops",
	0.98::numeric AS "threshold_CSSRSpeech"
$$);


SELECT trigger.set_condition(rule,
$$
    "Drops" > "threshold_Drops" AND
    "CSSRSpeech" < "threshold_CSSRSpeech"
$$
) FROM trigger.rule WHERE name = '3G/quarterly/badCssrSpeech';


SELECT trigger.set_weight(
	'3G/quarterly/badCssrSpeech',
$$
    SELECT CASE
    WHEN $1."Drops" <= 35 THEN
    	1000
    ELSE
        2000
    END
$$);


SELECT trigger.define_notification_message(
	'3G/quarterly/badCssrSpeech',
$$
	format('CSSR Speech: %s', trim(to_char($1."CSSRSpeech" * 100, '999D99')))
$$);

SELECT isnt(
    NULL,
    trigger.create_notifications('3G/quarterly/badCssrSpeech'::name, '2014-03-06 14:00+01'::timestamptz)
);

SELECT is(
    count(*),
    1::bigint,
    'One row should have been inserted of the two'
)
FROM notification."test";

SELECT * FROM finish();
ROLLBACK;
