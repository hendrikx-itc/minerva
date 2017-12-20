-- Table 'directory.existence_staging'

CREATE UNLOGGED TABLE directory.existence_staging
(
    dn character varying NOT NULL
);

ALTER TABLE directory.existence_staging OWNER TO minerva_admin;

GRANT SELECT ON TABLE directory.existence_staging TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.existence_staging TO minerva_writer;


CREATE VIEW directory.existence_staging_entitytype_ids AS
    SELECT entity.entitytype_id
        FROM directory.existence_staging
        JOIN directory.entity ON entity.dn = existence_staging.dn
        GROUP BY entitytype_id;

ALTER VIEW directory.existence_staging_entitytype_ids OWNER TO minerva_admin;

GRANT SELECT ON TABLE directory.existence_staging_entitytype_ids TO minerva;
GRANT INSERT,DELETE,UPDATE ON TABLE directory.existence_staging_entitytype_ids TO minerva_writer;


