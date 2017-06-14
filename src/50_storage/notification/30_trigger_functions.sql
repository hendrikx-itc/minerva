CREATE OR REPLACE FUNCTION notification.create_table_on_insert()
    RETURNS TRIGGER
AS $$
BEGIN
    IF NOT notification.table_exists(notification.table_name(NEW)) THEN
        PERFORM notification.create_table(NEW);
    END IF;

    IF NOT notification.table_exists(notification.staging_table_name(NEW)) THEN
        PERFORM notification.create_staging_table(NEW);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION notification.drop_table_on_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    EXECUTE format('DROP TABLE IF EXISTS notification.%I CASCADE', notification.staging_table_name(OLD));
    EXECUTE format('DROP TABLE IF EXISTS notification.%I CASCADE', notification.table_name(OLD));

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION notification.drop_notificationsetstore_table_on_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    EXECUTE format('DROP TABLE IF EXISTS notification.%I', OLD.name || '_link');
    EXECUTE format('DROP TABLE IF EXISTS notification.%I', OLD.name);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION notification.create_attribute_column_on_insert()
    RETURNS TRIGGER
AS $$
BEGIN
    PERFORM notification.create_attribute_column(NEW);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION notification.cleanup_on_datasource_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    DELETE FROM notification.notificationstore WHERE datasource_id = OLD.id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;
