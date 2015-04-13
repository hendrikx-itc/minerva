CREATE OR REPLACE FUNCTION relation.create_relation_table_on_insert()
    RETURNS TRIGGER
AS $$
BEGIN
    PERFORM relation.create_relation_table(NEW.name, NEW.id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION relation.drop_table_on_type_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    EXECUTE format('DROP TABLE IF EXISTS %I.%I', 'relation', OLD.name);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION relation.create_self_relation()
    RETURNS TRIGGER
AS $$
BEGIN
    INSERT INTO relation.self (source_id, target_id, type_id) SELECT NEW.id, NEW.id, "type".id FROM relation."type" WHERE name = 'self';

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
