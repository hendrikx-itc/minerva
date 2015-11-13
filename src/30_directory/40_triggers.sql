CREATE TRIGGER "create alias for new entity"
    AFTER INSERT
    ON directory.entity
    FOR EACH ROW
    EXECUTE PROCEDURE directory."create alias for new entity (func)"();

CREATE TRIGGER "create entitytaglink for new entity"
    AFTER INSERT
    ON directory.entity
    FOR EACH ROW
    EXECUTE PROCEDURE directory."create entitytaglink for new entity (func)"();

CREATE TRIGGER "create tag for new entitytypes"
    AFTER INSERT
    ON directory.entitytype
    FOR EACH ROW
    EXECUTE PROCEDURE directory."create tag for new entitytypes (func)"();

CREATE TRIGGER update_denormalized_tags_on_link_insert
    AFTER INSERT
    ON directory.entitytaglink
    FOR EACH ROW
    EXECUTE PROCEDURE directory.update_entity_link_denorm_for_insert();

CREATE TRIGGER update_denormalized_tags_on_link_delete
    AFTER DELETE 
    ON directory.entitytaglink
    FOR EACH ROW
    EXECUTE PROCEDURE directory.update_entity_link_denorm_for_delete();
