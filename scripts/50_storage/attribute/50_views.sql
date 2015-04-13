CREATE VIEW attribute_directory.dependencies AS
    SELECT dependent.relname AS src, pg_attribute.attname column_name, dependee.relname AS dst
    FROM pg_depend
    JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
    JOIN pg_class as dependee ON pg_rewrite.ev_class = dependee.oid
    JOIN pg_class as dependent ON pg_depend.refobjid = dependent.oid
    JOIN pg_namespace as n ON dependent.relnamespace = n.oid
    JOIN pg_attribute ON
            pg_depend.refobjid = pg_attribute.attrelid
            AND
            pg_depend.refobjsubid = pg_attribute.attnum
    WHERE n.nspname = 'attribute_directory' AND pg_attribute.attnum > 0;

ALTER VIEW attribute_directory.dependencies OWNER TO minerva_admin;

GRANT SELECT ON TABLE attribute_directory.dependencies TO minerva;
