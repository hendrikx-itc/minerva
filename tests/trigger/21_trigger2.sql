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
