CREATE TRIGGER create_table_on_insert
    AFTER INSERT ON relation."type"
    FOR EACH ROW
    EXECUTE PROCEDURE relation.create_relation_table_on_insert();


CREATE TRIGGER delete_relation_table_on_type_delete
    AFTER DELETE ON relation."type"
    FOR EACH ROW
    EXECUTE PROCEDURE relation.drop_table_on_type_delete();

