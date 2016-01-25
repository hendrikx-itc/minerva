CREATE FUNCTION attribute_directory.cleanup_on_data_source_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    DELETE FROM attribute_directory.attribute_store WHERE data_source_id = OLD.id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.cleanup_on_entity_type_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    DELETE FROM attribute_directory.attribute_store WHERE entity_type_id = OLD.id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION attribute_directory.cleanup_attribute_store_on_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    PERFORM attribute_directory.drop_dependees(OLD);

    EXECUTE format('DROP TABLE IF EXISTS attribute_base.%I CASCADE', attribute_directory.to_table_name(OLD));

    EXECUTE format('DROP FUNCTION attribute_history.mark_modified_%s()', OLD.id);

    EXECUTE format('DROP FUNCTION attribute_history.%I(integer, timestamp with time zone)', attribute_directory.at_ptr_function_name(OLD));
    EXECUTE format('DROP FUNCTION attribute_history.%I(timestamp with time zone)', attribute_directory.at_ptr_function_name(OLD));

    EXECUTE format('DROP TABLE IF EXISTS attribute_history.%I', attribute_directory.to_table_name(OLD) || '_curr_ptr');

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION attribute_directory.cleanup_attribute_after_delete()
    RETURNS TRIGGER
AS $$
DECLARE
    table_name name;
BEGIN
    SELECT attribute_directory.to_table_name(attribute_store) INTO table_name
    FROM attribute_directory.attribute_store
    WHERE id = OLD.attribute_store_id;

    -- When the delete of the attribute is cascaded from the attribute_store, the
    -- table name can no longer be constructed.
    IF table_name IS NOT NULL THEN
        PERFORM attribute_directory.drop_dependees(attribute_store) FROM attribute_directory.attribute_store WHERE id = OLD.attribute_store_id;

        EXECUTE format('ALTER TABLE attribute_base.%I DROP COLUMN %I', table_name, OLD.name);

        PERFORM attribute_directory.create_dependees(attribute_store) FROM attribute_directory.attribute_store WHERE id = OLD.attribute_store_id;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION attribute_directory.update_data_type_on_change()
    RETURNS TRIGGER
AS $$
BEGIN
    IF OLD.data_type <> NEW.data_type THEN
        PERFORM attribute_directory.modify_data_type(NEW);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION attribute_directory.set_hash()
    RETURNS TRIGGER
AS $$
BEGIN
    NEW.hash = attribute_history.values_hash(NEW);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
