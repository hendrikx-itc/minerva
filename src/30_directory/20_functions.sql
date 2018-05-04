CREATE FUNCTION directory.get_entity_by_id(integer)
    RETURNS directory.entity
AS $$
    SELECT * FROM directory.entity WHERE id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION directory.get_entity_type(text)
    RETURNS directory.entity_type
AS $$
    SELECT entity_type FROM directory.entity_type WHERE lower(name) = lower($1);
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION directory.get_data_source(text)
    RETURNS directory.data_source
AS $$
    SELECT * FROM directory.data_source WHERE name = $1;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION directory.create_data_source(text)
    RETURNS directory.data_source
AS $$
    INSERT INTO directory.data_source (name, description)
    VALUES ($1, 'default')
    RETURNING data_source;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.create_entity_type(text)
    RETURNS directory.entity_type
AS $$
    INSERT INTO directory.entity_type(name, description) VALUES ($1, '') RETURNING entity_type;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.create_or_replace_entity_type(text)
    RETURNS directory.entity_type
AS $$
    INSERT INTO directory.entity_type(name, description) VALUES ($1, '')
    ON CONFLICT DO NOTHING
    RETURNING entity_type;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.name_to_entity_type(text)
    RETURNS directory.entity_type
AS $$
    SELECT COALESCE(directory.get_entity_type($1), directory.create_or_replace_entity_type($1));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.entity_type_id(directory.entity_type)
    RETURNS integer
AS $$
    SELECT $1.id;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.entity_id(directory.entity)
    RETURNS integer
AS $$
    SELECT $1.id;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.name_to_data_source(text)
    RETURNS directory.data_source
AS $$
    SELECT COALESCE(directory.get_data_source($1), directory.create_data_source($1));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.tag_entity(entity_id integer, tag text)
    RETURNS integer
AS $$
    INSERT INTO directory.entity_tag_link(tag_id, entity_id)
    SELECT id, $1
    FROM directory.tag
    LEFT JOIN directory.entity_tag_link ON entity_tag_link.tag_id = tag.id AND entity_tag_link.entity_id = $1
    WHERE name = $2 AND entity_tag_link.entity_id IS NULL;

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION directory.update_denormalized_entity_tags(entity_id integer)
    RETURNS directory.entity_tag_link_denorm
AS $$
DELETE FROM directory.entity_tag_link_denorm WHERE entity_id = $1;
INSERT INTO directory.entity_tag_link_denorm
SELECT
    entity.id,
    array_agg(lower(tag.name)),
    lower(entity.name)
FROM directory.entity
JOIN directory.entity_tag_link etl ON etl.entity_id = entity.id
JOIN directory.tag ON tag.id = etl.tag_id
WHERE entity.id = $1
GROUP BY entity.id
RETURNING *;
$$ LANGUAGE sql VOLATILE;

