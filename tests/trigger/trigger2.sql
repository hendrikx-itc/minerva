BEGIN;

SELECT plan(2);

CREATE OR REPLACE VIEW trend."vtransform-accessibility-cell_qtr" AS 
SELECT * FROM (
	VALUES
	((directory.dn_to_entity('Cell=4321')).id, '2014-03-06 14:00+01'::timestamp with time zone, 34, 0.99),
	((directory.dn_to_entity('Cell=4322')).id, '2014-03-06 14:00+01'::timestamp with time zone, 44, 0.94)
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


SELECT trigger.set_thresholds(
	'3G/quarterly/badCssrSpeech',
$$
	15 AS "Drops",
	0.98 AS "CSSRSpeech"
$$);


SELECT trigger.set_weight(
	'3G/quarterly/badCssrSpeech',
$$
	1000
$$);


SELECT trigger.define_notification(
	'3G/quarterly/badCssrSpeech',
$$
	format('CSSR Speech: %s', trim(to_char($1."CSSRSpeech" * 100, '999D99')))
$$);

SELECT has_view(
    'trigger_rule'::name,
    '3G/quarterly/badCssrSpeech'::name,
    'Should have trigger view'
);

SELECT has_view(
    'trigger_rule'::name,
    '3G/quarterly/badCssrSpeech_with_threshold'::name,
    'Should have trigger view with thresholds'
);

SELECT * FROM finish();
ROLLBACK;
