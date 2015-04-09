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
