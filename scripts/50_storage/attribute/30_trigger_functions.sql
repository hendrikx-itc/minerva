CREATE OR REPLACE FUNCTION attribute_directory.cleanup_on_datasource_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    DELETE FROM attribute_directory.attributestore WHERE datasource_id = OLD.id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION attribute_directory.cleanup_attributestore_on_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    PERFORM attribute_directory.drop_dependees(OLD);

    EXECUTE format('DROP TABLE IF EXISTS attribute_base.%I CASCADE', attribute_directory.to_table_name(OLD));

    EXECUTE format('DROP FUNCTION attribute_history.mark_modified_%s()', OLD.id);

    EXECUTE format('DROP TABLE IF EXISTS attribute_history.%I', attribute_directory.to_table_name(OLD) || '_curr_ptr');

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION attribute_directory.cleanup_attribute_after_delete()
    RETURNS TRIGGER
AS $$
DECLARE
    table_name name;
BEGIN
    SELECT attribute_directory.to_table_name(attributestore) INTO table_name
    FROM attribute_directory.attributestore
    WHERE id = OLD.attributestore_id;

    -- When the delete of the attribute is cascaded from the attributestore, the
    -- table name can no longer be constructed.
    IF table_name IS NOT NULL THEN
        PERFORM attribute_directory.drop_dependees(attributestore) FROM attribute_directory.attributestore WHERE id = OLD.attributestore_id;

        EXECUTE format('ALTER TABLE attribute_base.%I DROP COLUMN %I', table_name, OLD.name);

        PERFORM attribute_directory.create_dependees(attributestore) FROM attribute_directory.attributestore WHERE id = OLD.attributestore_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION attribute_directory.update_datatype_on_change()
    RETURNS TRIGGER
AS $$
BEGIN
    IF OLD.datatype <> NEW.datatype THEN
        PERFORM attribute_directory.modify_datatype(NEW);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION attribute_directory.set_hash()
    RETURNS TRIGGER
AS $$
BEGIN
    NEW.hash = attribute_history.values_hash(NEW);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
