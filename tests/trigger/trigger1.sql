BEGIN;

SELECT plan(2);

SELECT directory.create_et('Cell');


CREATE OR REPLACE VIEW trend."vtransform-retainability-cell_qtr" AS 
SELECT * FROM (
	VALUES
	((entity."to_Cell"('4321')).id, '2014-03-06 14:00+01'::timestamp with time zone, 34, 0.99),
	((entity."to_Cell"('4322')).id, '2014-03-06 14:00+01'::timestamp with time zone, 44, 0.94)
) dummy_values(entity_id, timesxsxtamp, "Drops", "CCRSpeech");

ALTER VIEW trend."vtransform-retainability-cell_qtr" OWNER TO minerva_admin;
GRANT SELECT ON TABLE trend."vtransform-retainability-cell_qtr" TO minerva;


SELECT trigger.create_rule(
	'3G/quarterly/badCcrSpeech',
$$
	SELECT entity_id, timestamp, "Drops", "CCRSpeech"
	FROM trend."vtransform-retainability-cell_qtr" 
$$,
ARRAY['Drops', 'CCRSpeech'],
$$
	"Drops" > "threshold_Drops" AND
	"CCRSpeech" < "threshold_CCRSpeech"
$$);


SELECT trigger.set_thresholds(
	'3G/quarterly/badCcrSpeech',
$$
	15 AS "Drops",
	0.98 AS "CCRSpeech"
$$);


SELECT trigger.set_weight(
	'3G/quarterly/badCcrSpeech',
$$
	1000
$$);


SELECT trigger.define_notification(
	'3G/quarterly/badCcrSpeech',
$$
	format('CCR Speech: %s', trim(to_char($1."CCRSpeech" * 100, '999D99')))
$$);

SELECT has_view(
    'trigger_rule'::name,
    '3G/quarterly/badCcrSpeech'::name,
    'Should have trigger view'
);

SELECT has_view(
    'trigger_rule'::name,
    '3G/quarterly/badCcrSpeech_with_threshold'::name,
    'Should have trigger view with threnshold'
);

SELECT * FROM finish();
ROLLBACK;
