CREATE TRIGGER propagate_changes_on_update_to_trend
    AFTER UPDATE on directory.data_source
    FOR EACH ROW
    EXECUTE PROCEDURE trend_directory.changes_on_data_source_update();


CREATE TRIGGER propagate_changes_on_trend_update
    AFTER UPDATE ON trend_directory.trend
    FOR EACH ROW
    EXECUTE PROCEDURE trend_directory.changes_on_trend_update();


CREATE TRIGGER drop_table_on_delete
    AFTER DELETE ON trend_directory.partition
    FOR EACH ROW
    EXECUTE PROCEDURE trend_directory.drop_partition_table_on_delete();


CREATE TRIGGER delete_trend_stores_on_data_source_delete
    BEFORE DELETE ON directory.data_source
    FOR EACH ROW
    EXECUTE PROCEDURE trend_directory.cleanup_on_data_source_delete();


CREATE TRIGGER cleanup_table_trend_store_on_delete
    BEFORE DELETE ON trend_directory.table_trend_store
    FOR EACH ROW
    EXECUTE PROCEDURE trend_directory.cleanup_table_trend_store_on_delete();


CREATE TRIGGER drop_view_on_delete
    BEFORE DELETE ON trend_directory.view_trend_store
    FOR EACH ROW
    EXECUTE PROCEDURE trend_directory.drop_view_on_delete();
