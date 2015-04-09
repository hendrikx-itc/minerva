CREATE OR REPLACE VIEW trend."vtransform-accessibility-cell_qtr" AS 
SELECT * FROM (
	VALUES
	((directory.dn_to_entity('Cell=4321')).id, '2014-03-06 14:00+01'::timestamp with time zone, 34, 0.99),
	((directory.dn_to_entity('Cell=4322')).id, '2014-03-06 14:00+01'::timestamp with time zone, 44, 0.94)
) dummy_values(entity_id, timestamp, "Drops", "CSSRSpeech");

ALTER VIEW trend."vtransform-accessibility-cell_qtr" OWNER TO minerva_admin;
GRANT SELECT ON TABLE trend."vtransform-accessibility-cell_qtr" TO minerva;
