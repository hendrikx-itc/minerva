CREATE TRIGGER create_self_relation_on_entity_insert
    AFTER INSERT ON directory.entity
    FOR EACH ROW
    EXECUTE PROCEDURE relation_directory.create_self_relation();
