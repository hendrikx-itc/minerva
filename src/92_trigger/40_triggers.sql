CREATE TRIGGER cleanup_on_rule_delete
    BEFORE DELETE ON trigger.rule
    FOR EACH ROW
    EXECUTE PROCEDURE trigger.cleanup_on_rule_delete();
