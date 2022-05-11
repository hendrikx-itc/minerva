BEGIN;

SELECT plan(3);

SELECT directory.create_entity_type('Cell');

CREATE OR REPLACE VIEW trend."vtransform-accessibility-cell_qtr" AS
SELECT * FROM (
	VALUES
	((entity."to_Cell"('4321')).id, '2014-03-06 14:00+01'::timestamp with time zone, 34, 0.99),
	((entity."to_Cell"('4322')).id, '2014-03-06 14:00+01'::timestamp with time zone, 44, 0.94)
) dummy_values(entity_id, timestamp, "Drops", "CSSRSpeech");

ALTER VIEW trend."vtransform-accessibility-cell_qtr" OWNER TO minerva_admin;
GRANT SELECT ON TABLE trend."vtransform-accessibility-cell_qtr" TO minerva;

SELECT trigger.create_rule(
	'3G/quarterly/badCssrSpeech',
$$
	SELECT entity_id, timestamp, "Drops", "CSSRSpeech"
	FROM trend."vtransform-accessibility-cell_qtr"
$$,
ARRAY['Drops', 'CSSRSpeech'],
$$
	"Drops" > "threshold_Drops" AND
	"CSSRSpeech" < "threshold_CSSRSpeech"
$$);


UPDATE trigger.rule
SET notification_store_id = (trigger.create_trigger_notification_store('test')).id
WHERE name = '3G/quarterly/badCssrSpeech';

SELECT has_table('notification'::name, 'test'::name);


SELECT trigger.set_thresholds(
	'3G/quarterly/badCssrSpeech',
$$
	15 AS "Drops",
	0.98 AS "CSSRSpeech"
$$);


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


SELECT trigger.define_notification(
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
