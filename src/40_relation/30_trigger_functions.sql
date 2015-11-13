CREATE OR REPLACE FUNCTION relation.create_relation_table_on_insert()
    RETURNS TRIGGER
AS $$
BEGIN
    PERFORM relation.create_relation_table(NEW.name);

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

