CREATE OR REPLACE FUNCTION directory."create alias for new entity (func)"()
    RETURNS trigger
AS $$
BEGIN
    INSERT INTO directory.alias (entity_id, name, type_id)
        SELECT NEW.id, NEW.name, id FROM directory.aliastype WHERE name = 'name';

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;

ALTER FUNCTION directory."create alias for new entity (func)"() OWNER TO postgres;


CREATE OR REPLACE FUNCTION directory."create tag for new entitytypes (func)"()
    RETURNS trigger
AS $$
BEGIN
    BEGIN
        INSERT INTO directory.tag (name, taggroup_id) SELECT NEW.name, id FROM directory.taggroup WHERE directory.taggroup.name = 'entitytype';
    EXCEPTION WHEN unique_violation THEN
        UPDATE directory.tag SET taggroup_id = (SELECT id FROM directory.taggroup WHERE directory.taggroup.name = 'entitytype') WHERE tag.name = NEW.name;
    END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;

ALTER FUNCTION directory."create tag for new entitytypes (func)"() OWNER TO postgres;


CREATE OR REPLACE FUNCTION directory."create entitytaglink for new entity (func)"()
    RETURNS trigger
AS $$
BEGIN
    INSERT INTO directory.entitytaglink (entity_id, tag_id) VALUES (NEW.id, (
    SELECT tag.id FROM directory.tag
    INNER JOIN directory.entitytype ON tag.name = entitytype.name
    WHERE entitytype.id = NEW.entitytype_id
    ));

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;

ALTER FUNCTION directory."create entitytaglink for new entity (func)"() OWNER TO postgres;


CREATE OR REPLACE FUNCTION directory.update_entity_link_denorm_for_insert()
    RETURNS trigger
AS $$
BEGIN
    PERFORM directory.update_denormalized_entity_tags(NEW.entity_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION directory.update_entity_link_denorm_for_delete()
    RETURNS trigger
AS $$
BEGIN
    PERFORM directory.update_denormalized_entity_tags(OLD.entity_id);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;
