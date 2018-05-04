CREATE FUNCTION directory.create_entity_type_tag()
    RETURNS trigger
AS $$
BEGIN
    BEGIN
        INSERT INTO directory.tag (name, tag_group_id) SELECT NEW.name, id FROM directory.tag_group WHERE directory.tag_group.name = 'entity_type';
    EXCEPTION WHEN unique_violation THEN
        UPDATE directory.tag SET tag_group_id = (SELECT id FROM directory.tag_group WHERE directory.tag_group.name = 'entity_type') WHERE tag.name = NEW.name;
    END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;

ALTER FUNCTION directory.create_entity_type_tag() OWNER TO postgres;


CREATE FUNCTION directory.create_entity_tag_link()
    RETURNS trigger
AS $$
BEGIN
    INSERT INTO directory.entity_tag_link (entity_id, tag_id) VALUES (NEW.id, (
    SELECT tag.id FROM directory.tag
    INNER JOIN directory.entity_type ON tag.name = entity_type.name
    WHERE entity_type.id = NEW.entity_type_id
    ));

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;

ALTER FUNCTION directory.create_entity_tag_link() OWNER TO postgres;


CREATE FUNCTION directory.update_entity_tag_link_denorm_for_insert()
    RETURNS trigger
AS $$
BEGIN
    PERFORM directory.update_denormalized_entity_tags(NEW.entity_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION directory.update_entity_tag_link_denorm_for_delete()
    RETURNS trigger
AS $$
BEGIN
    PERFORM directory.update_denormalized_entity_tags(OLD.entity_id);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;
