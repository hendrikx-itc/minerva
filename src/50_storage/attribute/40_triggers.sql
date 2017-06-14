CREATE TRIGGER delete_attributestores_on_datasource_delete
    BEFORE DELETE ON directory.datasource
    FOR EACH ROW
    EXECUTE PROCEDURE attribute_directory.cleanup_on_datasource_delete();


CREATE TRIGGER cleanup_attributestore_on_delete
    BEFORE DELETE ON attribute_directory.attributestore
    FOR EACH ROW
    EXECUTE PROCEDURE attribute_directory.cleanup_attributestore_on_delete();


CREATE TRIGGER update_attribute_type
    AFTER UPDATE ON attribute_directory.attribute
    FOR EACH ROW
    EXECUTE PROCEDURE attribute_directory.update_datatype_on_change();


CREATE TRIGGER after_delete_attribute
    AFTER DELETE ON attribute_directory.attribute
    FOR EACH ROW
    EXECUTE PROCEDURE attribute_directory.cleanup_attribute_after_delete();
