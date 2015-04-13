CREATE SCHEMA metric;
ALTER SCHEMA metric OWNER TO minerva_admin;

GRANT ALL ON SCHEMA metric TO minerva_admin;
GRANT USAGE ON SCHEMA metric TO minerva;
