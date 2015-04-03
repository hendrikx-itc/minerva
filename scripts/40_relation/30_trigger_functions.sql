CREATE FUNCTION relation_directory.create_relation_table_on_insert()
    RETURNS TRIGGER
AS $$
BEGIN
    PERFORM relation_directory.create_relation_table(NEW.name, NEW.id);

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


CREATE FUNCTION relation_directory.create_self_relation()
    RETURNS TRIGGER
AS $$
BEGIN
    INSERT INTO relation.self (source_id, target_id, type_id)
    SELECT NEW.id, NEW.id, "type".id FROM relation_directory."type" WHERE name = 'self';

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
