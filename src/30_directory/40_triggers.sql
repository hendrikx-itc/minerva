CREATE TRIGGER create_entity_tag_link_for_new_entity
    AFTER INSERT
    ON directory.entity
    FOR EACH ROW
    EXECUTE PROCEDURE directory.create_entity_tag_link();

CREATE TRIGGER create_tag_for_new_entity_types
    AFTER INSERT
    ON directory.entity_type
    FOR EACH ROW
    EXECUTE PROCEDURE directory.create_entity_type_tag();

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
