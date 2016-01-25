CREATE FUNCTION notification_directory.drop_table_on_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    EXECUTE format(
        'DROP TABLE IF EXISTS %I.%I CASCADE',
        notification_directory.notification_store_schema(),
        notification_directory.staging_table_name(OLD)
    );

    EXECUTE format(
        'DROP TABLE IF EXISTS %I.%I CASCADE',
        notification_directory.notification_store_schema(),
        notification_directory.table_name(OLD)
    );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION notification_directory.drop_notification_set_store_table_on_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    EXECUTE format(
        'DROP TABLE IF EXISTS %I.%I',
        notification_directory.notification_store_schema(),
        OLD.name || '_link'
    );

    EXECUTE format(
        'DROP TABLE IF EXISTS %I.%I',
        notification_directory.notification_store_schema(),
        OLD.name
    );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION notification_directory.cleanup_on_data_source_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    DELETE FROM notification_directory.notification_store WHERE data_source_id = OLD.id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;
