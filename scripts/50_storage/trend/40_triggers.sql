CREATE TRIGGER propagate_changes_on_update_to_trend
    AFTER UPDATE on directory.datasource
    FOR EACH ROW
    EXECUTE PROCEDURE trend.changes_on_datasource_update();


CREATE TRIGGER propagate_changes_on_update
    AFTER UPDATE ON trend.partition
    FOR EACH ROW
    EXECUTE PROCEDURE trend.changes_on_partition_update();


CREATE TRIGGER propagate_changes_on_trend_update
    AFTER UPDATE ON trend.trend
    FOR EACH ROW
    EXECUTE PROCEDURE trend.changes_on_trend_update();


CREATE TRIGGER create_table_on_insert
    BEFORE INSERT ON trend.partition
    FOR EACH ROW
    EXECUTE PROCEDURE trend.create_partition_table_on_insert();


CREATE TRIGGER drop_table_on_delete
    AFTER DELETE ON trend.partition
    FOR EACH ROW
    EXECUTE PROCEDURE trend.drop_partition_table_on_delete();


CREATE TRIGGER delete_trendstores_on_datasource_delete
    BEFORE DELETE ON directory.datasource
    FOR EACH ROW
    EXECUTE PROCEDURE trend.cleanup_on_datasource_delete();


CREATE TRIGGER cleanup_trendstore_on_delete
    BEFORE DELETE ON trend.trendstore
    FOR EACH ROW
    EXECUTE PROCEDURE trend.cleanup_trendstore_on_delete();


CREATE TRIGGER create_trendstore_base_on_insert
    BEFORE INSERT ON trend.trendstore
    FOR EACH ROW
    EXECUTE PROCEDURE trend.create_base_table_on_insert();


CREATE TRIGGER set_trendstore_defaults
    BEFORE INSERT ON trend.trendstore
    FOR EACH ROW
    EXECUTE PROCEDURE trend.set_trendstore_defaults();

CREATE TRIGGER drop_view_on_delete
    BEFORE DELETE ON trend.view
    FOR EACH ROW
    EXECUTE PROCEDURE trend.drop_view_on_delete();
