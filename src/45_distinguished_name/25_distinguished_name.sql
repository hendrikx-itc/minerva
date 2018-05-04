SELECT alias_directory.create_alias_type('dn'::name);
SELECT relation_directory.create_type('parent');

CREATE FUNCTION directory.get_entity_by_dn(text)
    RETURNS directory.entity
AS $$
    SELECT entity
    FROM directory.entity
    JOIN alias.dn ON dn.entity_id = entity.id
    WHERE dn.dn = $1;
$$ LANGUAGE sql STABLE;

CREATE TYPE directory.dn_part AS (type_name text, name text);


CREATE FUNCTION directory.dn_part_to_string(directory.dn_part)
    RETURNS text
AS $$
    SELECT $1.type_name || '=' || $1.name;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE CAST (directory.dn_part AS text)
    WITH FUNCTION directory.dn_part_to_string (directory.dn_part);


CREATE FUNCTION directory.array_to_dn_part(text[])
    RETURNS directory.dn_part
AS $$
    SELECT CAST(ROW($1[1], $1[2]) AS directory.dn_part);
$$ LANGUAGE sql IMMUTABLE;


CREATE CAST (text[] AS directory.dn_part)
    WITH FUNCTION directory.array_to_dn_part (text[]);


CREATE FUNCTION directory.split_raw_part(text)
    RETURNS directory.dn_part
AS $$
    SELECT directory.array_to_dn_part(string_to_array($1, '='));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION directory.explode_dn(text)
    RETURNS directory.dn_part[]
AS $$
    SELECT array_agg(directory.split_raw_part(raw_part)) FROM unnest(string_to_array($1, ',')) AS raw_part;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION directory.glue_dn(directory.dn_part[])
    RETURNS text
AS $$
    SELECT
        array_to_string(b.part_arr, ',')
    FROM (
        SELECT array_agg(parts.p) part_arr
        FROM (
            SELECT directory.dn_part_to_string(part) p FROM unnest($1) part
        ) parts
    ) b;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION directory.parent_dn_parts(directory.dn_part[])
    RETURNS directory.dn_part[]
AS $$
    SELECT
        CASE
            WHEN array_length($1, 1) > 1 THEN
                $1[1:array_length($1, 1) - 1]
            ELSE
                NULL
        END;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION directory.parent_dn(text)
    RETURNS text
AS $$
    SELECT directory.glue_dn(directory.parent_dn_parts(directory.explode_dn($1)));
$$ LANGUAGE sql IMMUTABLE STRICT;

-- Stub
CREATE FUNCTION directory.dn_to_entity(text)
    RETURNS directory.entity
AS $$
    SELECT null::directory.entity;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.last_dn_part(directory.dn_part[])
    RETURNS directory.dn_part
AS $$
    SELECT $1[array_length($1, 1)];
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION directory.create_entity(text)
    RETURNS directory.entity
AS $$
    INSERT INTO directory.entity(created, name, entity_type_id)
        VALUES (
            now(),
            (directory.last_dn_part(directory.explode_dn($1))).name,
            directory.entity_type_id(directory.name_to_entity_type((directory.last_dn_part(directory.explode_dn($1))).type_name))
        )
        RETURNING entity;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.create_dn_alias(directory.entity, dn text)
    RETURNS directory.entity
AS $$
    SELECT alias_directory.create_alias($1.id, 'dn', $2);

    SELECT $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION directory.create_entity_with_alias(text)
    RETURNS directory.entity
AS $$
    SELECT directory.create_dn_alias(new_entity, $1)
    FROM directory.create_entity($1) new_entity;
$$ LANGUAGE sql VOLATILE;


-- Use 'CREATE OR REPLACE' to replace the dn_to_entity stub
CREATE OR REPLACE FUNCTION directory.dn_to_entity(text)
    RETURNS directory.entity
AS $$
    SELECT COALESCE(directory.get_entity_by_dn($1), directory.create_entity($1));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.dns_to_entity_ids(text[])
    RETURNS SETOF integer
AS $$
    SELECT (directory.dn_to_entity(dn)).id FROM unnest($1) dn;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.tag_entity(dn text, tag text)
    RETURNS text
AS $$
    INSERT INTO directory.entity_tag_link(tag_id, entity_id)
    SELECT
        f.tag_id,
        f.entity_id
    FROM (
        SELECT
            tag.id AS tag_id,
            dn.entity_id
        FROM directory.tag, alias.dn
        WHERE tag.name = $2 AND dn.dn = $1
    ) f
    LEFT JOIN directory.entity_tag_link ON entity_tag_link.tag_id = f.tag_id AND entity_tag_link.entity_id = f.entity_id
    WHERE entity_tag_link.entity_id IS NULL;

    SELECT $1;
$$ LANGUAGE sql VOLATILE;

