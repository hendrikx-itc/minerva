CREATE OR REPLACE FUNCTION trigger.cleanup_on_rule_delete()
    RETURNS TRIGGER
AS $$
BEGIN
	PERFORM trigger.cleanup_rule(OLD);

	RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;
