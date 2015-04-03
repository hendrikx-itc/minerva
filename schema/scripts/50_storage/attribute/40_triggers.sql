CREATE TRIGGER delete_attribute_stores_on_data_source_delete
    BEFORE DELETE ON directory.data_source
    FOR EACH ROW
    EXECUTE PROCEDURE attribute_directory.cleanup_on_data_source_delete();


CREATE TRIGGER delete_attribute_stores_on_entity_type_delete
    BEFORE DELETE ON directory.entity_type
    FOR EACH ROW
    EXECUTE PROCEDURE attribute_directory.cleanup_on_entity_type_delete();


CREATE TRIGGER cleanup_attribute_store_on_delete
    BEFORE DELETE ON attribute_directory.attribute_store
    FOR EACH ROW
    EXECUTE PROCEDURE attribute_directory.cleanup_attribute_store_on_delete();


CREATE TRIGGER update_attribute_type
    AFTER UPDATE ON attribute_directory.attribute
    FOR EACH ROW
    EXECUTE PROCEDURE attribute_directory.update_data_type_on_change();


CREATE TRIGGER after_delete_attribute
    AFTER DELETE ON attribute_directory.attribute
    FOR EACH ROW
    EXECUTE PROCEDURE attribute_directory.cleanup_attribute_after_delete();
