CREATE TRIGGER create_alias_for_new_entity
    AFTER INSERT
    ON directory.entity
    FOR EACH ROW
    EXECUTE PROCEDURE directory."create alias for new entity (func)"();

CREATE TRIGGER create_entity_tag_link_for_new_entity
    AFTER INSERT
    ON directory.entity
    FOR EACH ROW
    EXECUTE PROCEDURE directory."create entity_tag_link for new entity (func)"();

CREATE TRIGGER create_tag_for_new_entity_types
    AFTER INSERT
    ON directory.entity_type
    FOR EACH ROW
    EXECUTE PROCEDURE directory."create tag for new entity_types (func)"();

CREATE TRIGGER update_denormalized_tags_on_link_insert
    AFTER INSERT
    ON directory.entity_tag_link
    FOR EACH ROW
    EXECUTE PROCEDURE directory.update_entity_tag_link_denorm_for_insert();

CREATE TRIGGER update_denormalized_tags_on_link_delete
    AFTER DELETE
    ON directory.entity_tag_link
    FOR EACH ROW
    EXECUTE PROCEDURE directory.update_entity_tag_link_denorm_for_delete();
