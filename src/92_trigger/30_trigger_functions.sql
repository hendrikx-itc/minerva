SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = "trigger", pg_catalog;

CREATE OR REPLACE FUNCTION cleanup_on_rule_delete()
    RETURNS TRIGGER
AS $$
BEGIN
	PERFORM trigger.cleanup_rule(OLD);

	RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;
