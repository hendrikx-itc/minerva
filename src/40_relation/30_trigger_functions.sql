CREATE FUNCTION relation_directory.create_relation_table_on_insert()
    RETURNS TRIGGER
AS $$
BEGIN
    PERFORM relation_directory.create_relation_table(NEW);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION relation_directory.drop_table_on_type_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    EXECUTE format('DROP TABLE IF EXISTS %I.%I', relation_directory.table_schema(), OLD.name);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
