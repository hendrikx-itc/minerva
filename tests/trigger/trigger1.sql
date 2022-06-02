BEGIN;

SELECT plan(2);

SELECT directory.create_entity_type('Cell');


CREATE OR REPLACE VIEW trend."vtransform-retainability-cell_qtr" AS 
SELECT * FROM (
	VALUES
	((entity."to_Cell"('4321')).id, '2014-03-06 14:00+01'::timestamp with time zone, 34, 0.99),
	((entity."to_Cell"('4322')).id, '2014-03-06 14:00+01'::timestamp with time zone, 44, 0.94)
) dummy_values(entity_id, timestamp, "Drops", "CCRSpeech");

ALTER VIEW trend."vtransform-retainability-cell_qtr" OWNER TO minerva_admin;
GRANT SELECT ON TABLE trend."vtransform-retainability-cell_qtr" TO minerva;

CREATE TYPE trigger_rule."3G/quarterly/badCcrSpeech_kpi" AS (
   entity_id integer,
   timestamp timestamp with time zone,
   "Drops" numeric,
   "CCRSpeech" numeric
);

CREATE FUNCTION trigger_rule."3G/quarterly/badCcrSpeech_kpi"(timestamp with time zone)
  RETURNS SETOF trigger_rule."3G/quarterly/badCcrSpeech_kpi"
  AS $$
	SELECT entity_id, timestamp, "Drops"::numeric, "CCRSpeech"::numeric
	  FROM trend."vtransform-retainability-cell_qtr";
     $$ LANGUAGE sql STABLE;

SELECT trigger.create_rule(
  '3G/quarterly/badCcrSpeech',
  ARRAY[('threshold_Drops', 'numeric'), ('threshold_CCRSpeech', 'numeric')]::trigger.threshold_def[]
);

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


SELECT trigger.define_notification_message(
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
