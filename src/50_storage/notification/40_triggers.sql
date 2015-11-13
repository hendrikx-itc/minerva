CREATE TRIGGER create_table_on_insert
    BEFORE INSERT ON notification.notificationstore
    FOR EACH ROW
    EXECUTE PROCEDURE notification.create_table_on_insert();


CREATE TRIGGER drop_table_on_delete
    BEFORE DELETE ON notification.notificationstore
    FOR EACH ROW
    EXECUTE PROCEDURE notification.drop_table_on_delete();


CREATE TRIGGER drop_notificationsetstore_table_on_delete
    BEFORE DELETE ON notification.notificationsetstore
    FOR EACH ROW
    EXECUTE PROCEDURE notification.drop_notificationsetstore_table_on_delete();


CREATE TRIGGER create_column_on_insert
    BEFORE INSERT ON notification.attribute
    FOR EACH ROW
    EXECUTE PROCEDURE notification.create_attribute_column_on_insert();


CREATE TRIGGER delete_notificationstores_on_datasource_delete
    BEFORE DELETE ON directory.datasource
    FOR EACH ROW
    EXECUTE PROCEDURE notification.cleanup_on_datasource_delete();
