CREATE FUNCTION directory.get_entity_by_dn(character varying)
    RETURNS directory.entity
AS $$
    SELECT * FROM directory.entity WHERE dn = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION directory.get_entity_by_id(integer)
    RETURNS directory.entity
AS $$
    SELECT * FROM directory.entity WHERE id = $1;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION directory.get_entity_type(character varying)
    RETURNS directory.entity_type
AS $$
    SELECT entity_type FROM directory.entity_type WHERE lower(name) = lower($1);
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION directory.get_data_source(character varying)
    RETURNS directory.data_source
AS $$
    SELECT * FROM directory.data_source WHERE name = $1;
$$ LANGUAGE sql STABLE STRICT;


CREATE FUNCTION directory.create_data_source(character varying)
    RETURNS directory.data_source
AS $$
    INSERT INTO directory.data_source (name, description)
    VALUES ($1, 'default')
    RETURNING data_source;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE TYPE directory.dn_part AS (type_name character varying, name character varying);


CREATE FUNCTION directory.dn_part_to_string(directory.dn_part)
    RETURNS character varying
AS $$
    SELECT $1.type_name || '=' || $1.name;
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE CAST (directory.dn_part AS character varying)
    WITH FUNCTION directory.dn_part_to_string (directory.dn_part);


CREATE FUNCTION directory.array_to_dn_part(character varying[])
    RETURNS directory.dn_part
AS $$
    SELECT CAST(ROW($1[1], $1[2]) AS directory.dn_part);
$$ LANGUAGE sql IMMUTABLE;


CREATE CAST (character varying[] AS directory.dn_part)
    WITH FUNCTION directory.array_to_dn_part (character varying[]);


CREATE FUNCTION directory.split_raw_part(character varying)
    RETURNS directory.dn_part
AS $$
    SELECT directory.array_to_dn_part(string_to_array($1, '='));
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION directory.explode_dn(character varying)
    RETURNS directory.dn_part[]
AS $$
    SELECT array_agg(directory.split_raw_part(raw_part)) FROM unnest(string_to_array($1, ',')) AS raw_part;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION directory.glue_dn(directory.dn_part[])
    RETURNS character varying
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


CREATE FUNCTION directory.create_entity_type(character varying)
    RETURNS directory.entity_type
AS $$
    INSERT INTO directory.entity_type(name, description) VALUES ($1, '') RETURNING entity_type;
$$ LANGUAGE sql VOLATILE STRICT;


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


CREATE FUNCTION directory.parent_dn(character varying)
    RETURNS character varying
AS $$
    SELECT directory.glue_dn(directory.parent_dn_parts(directory.explode_dn($1)));
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION directory.name_to_entity_type(character varying)
    RETURNS directory.entity_type
AS $$
    SELECT COALESCE(directory.get_entity_type($1), directory.create_entity_type($1));
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


-- Stub
CREATE FUNCTION directory.dn_to_entity(character varying)
    RETURNS directory.entity
AS $$
    SELECT null::directory.entity;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.last_dn_part(directory.dn_part[])
    RETURNS directory.dn_part
AS $$
    SELECT $1[array_length($1, 1)];
$$ LANGUAGE sql IMMUTABLE STRICT;


CREATE FUNCTION directory.create_entity(character varying)
    RETURNS directory.entity
AS $$
    INSERT INTO directory.entity(created, name, entity_type_id, dn, parent_id)
        VALUES (
            now(),
            (directory.last_dn_part(directory.explode_dn($1))).name,
            directory.entity_type_id(directory.name_to_entity_type((directory.last_dn_part(directory.explode_dn($1))).type_name)),
            $1,
            directory.entity_id(directory.dn_to_entity(directory.glue_dn(directory.parent_dn_parts(directory.explode_dn($1)))))
        )
        RETURNING entity;
$$ LANGUAGE sql VOLATILE STRICT;


-- Use 'CREATE OR REPLACE' to replace the dn_to_entity stub
CREATE OR REPLACE FUNCTION directory.dn_to_entity(character varying)
    RETURNS directory.entity
AS $$
    SELECT COALESCE(directory.get_entity_by_dn($1), directory.create_entity($1));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.get_alias(entity_id integer, alias_type_name character varying)
    RETURNS character varying
AS $$
    SELECT a.name
      FROM directory.alias a
      JOIN directory.alias_type at on at.id = a.type_id
     WHERE a.entity_id = $1 and at.name = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION directory.name_to_data_source(character varying)
    RETURNS directory.data_source
AS $$
    SELECT COALESCE(directory.get_data_source($1), directory.create_data_source($1));
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION directory.dns_to_entity_ids(character varying[])
    RETURNS SETOF integer
AS $$
    SELECT (directory.dn_to_entity(dn)).id FROM unnest($1) dn;
$$ LANGUAGE sql VOLATILE STRICT;


CREATE TYPE directory.query_part AS (c text[], s text);

CREATE TYPE directory.query_row AS (id integer, dn text, entity_type_id integer);

------------------------------------------
-- Example usage of run_minerva_query:
--
-- SELECT run_minerva_query(ARRAY[(ARRAY['Cell']::text[], '15000')]::query_part[]);
--
-- SELECT run_minerva_query(ARRAY[(ARRAY['Site']::text[], '4343'), (ARRAY['Cell', '3G']::text[], NULL)]::query_part[]);
------------------------------------------

CREATE FUNCTION directory.run_minerva_query(query directory.query_part[])
    RETURNS TABLE(id integer, dn varchar, entity_type_id integer)
AS $$
BEGIN
    RETURN QUERY EXECUTE compile_minerva_query(query);
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION directory.compile_minerva_query(query text)
    RETURNS text
AS $$
DECLARE
    parts text[];
    c_str text;
    cs text[];
    s_str text;
    minerva_query directory.query_part[];
BEGIN
    parts = regexp_split_to_array(query, E'(\\w)[ ]+(?=\\w)');

    for i in 1..2 LOOP
        c_str = parts[i];
        cs = regexp_split_to_array(c_str, E'[+ ]+');
        s_str = parts[i + 1];

        minerva_query = minerva_query || (cs, s_str)::directory.query_part;
    end loop;

    return directory.compile_minerva_query(minerva_query);
END;
$$ LANGUAGE plpgsql STABLE STRICT;

------------------------------------------
-- Example usage of compile_minerva_query:
--
-- SELECT compile_minerva_query(ARRAY[(ARRAY['Cell']::text[], '15000')]::directory.query_part[]);
------------------------------------------

CREATE FUNCTION directory.compile_minerva_query(query directory.query_part[])
    RETURNS text
AS $$
DECLARE
    sql text;
    entity_id_table text;
    entity_id_column text;
    q_part directory.query_part;
    tag text;
BEGIN
    sql = 'SELECT entity.id, entity.dn, entity.entity_type_id FROM directory.entity_tag_link tl_1_1';

    entity_id_table = 'tl_1_1';
    entity_id_column = 'entity_id';

    FOR index IN array_lower(query, 1)..array_upper(query, 1) LOOP
        q_part = query[index];

        IF index > 1 THEN
            sql = sql || format(' JOIN directory.relation r_%s ON r_%s.source_id = %I.%I', index, index, entity_id_table, entity_id_column);

            entity_id_table = format('r_%s', index);
            entity_id_column = 'target_id';
        END IF;

        FOR i IN array_lower(q_part.c, 1)..array_upper(q_part.c, 1) LOOP
            tag = q_part.c[i];

            sql = sql || directory.make_c_join(index, entity_id_table, entity_id_column, i, tag);
        END LOOP;

        IF NOT q_part.s IS NULL THEN
            sql = sql || directory.make_s_join(index, entity_id_table, entity_id_column, q_part.s);
        END IF;

    END LOOP;

    RETURN sql || format(' JOIN directory.entity entity ON entity.id = %I.%I', entity_id_table, entity_id_column);
END;
$$ LANGUAGE plpgsql STABLE STRICT;


CREATE FUNCTION directory.make_c_join(index integer, entity_id_table text, entity_id_column text, tag_index integer, tag text)
    RETURNS text
AS $$
DECLARE
    entity_tag_link_alias text;
    entitytag_alias text;
BEGIN
    entity_tag_link_alias = 'tl_' || index || '_' || tag_index;
    entitytag_alias = 't_' || index || '_' || tag_index;

    IF NOT entity_id_table = entity_tag_link_alias THEN
        RETURN format(' JOIN directory.entity_tag_link %I ON %I.%I = %I.entity_id', entity_tag_link_alias, entity_id_table, entity_id_column, entity_tag_link_alias) ||
            format(' JOIN directory.entitytag %I ON %I.id = %I.entitytag_id AND lower(%I.name) = lower(%L)', entitytag_alias, entitytag_alias, entity_tag_link_alias, entitytag_alias, tag);
    ELSE
        RETURN format(' JOIN directory.entitytag %I ON %I.id = %I.entitytag_id AND lower(%I.name) = lower(%L)', entitytag_alias, entitytag_alias, entity_tag_link_alias, entitytag_alias, tag);
    END IF;
END;
$$ LANGUAGE plpgsql STABLE STRICT;


CREATE FUNCTION directory.make_s_join(index integer, entity_id_table text, entity_id_column text, alias text)
    RETURNS text
AS $$
DECLARE
    alias_alias text;
    aliastype_alias text;
BEGIN
    alias_alias = 'a_' || index;
    aliastype_alias = 'at_' || index;

    RETURN format(' JOIN directory.alias %I ON %I.entity_id = %I.%I', alias_alias, alias_alias, entity_id_table, entity_id_column) ||
        format(' JOIN directory.aliastype %I ON %I.id = %I.type_id and %I.name = %L AND lower(%I.name) = lower(%L)', aliastype_alias, aliastype_alias, alias_alias, aliastype_alias, 'name', alias_alias, alias);
END;
$$ LANGUAGE plpgsql STABLE STRICT;


CREATE FUNCTION directory.tag_entity(entity_id integer, tag character varying)
    RETURNS integer
AS $$
    INSERT INTO directory.entity_tag_link(tag_id, entity_id) SELECT id, $1 FROM directory.tag WHERE name = $2 RETURNING $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION directory.tag_entity(dn character varying, tag character varying)
    RETURNS character varying
AS $$
    INSERT INTO directory.entity_tag_link(tag_id, entity_id)
    SELECT tag.id, entity.id
    FROM directory.tag, directory.entity
    WHERE tag.name = $2 AND entity.dn = $1 RETURNING $1;
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



CREATE FUNCTION directory.get_existence(timestamp with time zone, integer)
  RETURNS boolean AS
$BODY$

 SELECT public.first(existence."exists" ORDER BY existence."timestamp" DESC) AS "exists"
   FROM directory.existence
   WHERE existence."timestamp" <= $1 AND existence.entity_id = $2
  GROUP BY existence.entity_id

$BODY$
  LANGUAGE sql STABLE STRICT;


CREATE FUNCTION directory.existing_staging(timestamp with time zone)
    RETURNS SETOF directory.existence
AS $$
    SELECT
        $1, True, entity.id, entity.entity_type_id
    FROM directory.existence_staging
    JOIN directory.entity ON entity.dn = existence_staging.dn;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION directory.non_existing_staging(timestamp with time zone)
    RETURNS SETOF directory.existence
AS $$
    SELECT $1, False, entity.id, entity.entity_type_id
    FROM directory.existence_staging_entity_type_ids
    JOIN directory.entity ON entity.entity_type_id = existence_staging_entity_type_ids.entity_type_id
    LEFT JOIN directory.existence_staging ON existence_staging.dn = entity.dn
    WHERE existence_staging.dn IS NULL;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION directory.existence_staging_state(timestamp with time zone)
    RETURNS SETOF directory.existence
AS $$
    SELECT * FROM directory.existing_staging($1)
    UNION
    SELECT * FROM directory.non_existing_staging($1)
$$ LANGUAGE sql STABLE;


CREATE FUNCTION directory.existence_at(timestamp with time zone)
    RETURNS SETOF directory.existence
AS $$
    SELECT
        existence.timestamp,
        existence.exists,
        existence.entity_id,
        existence.entity_type_id
    FROM directory.existence JOIN (
        SELECT entity_id, max(timestamp) AS timestamp
        FROM directory.existence
        WHERE timestamp <= $1
        GROUP BY entity_id
    ) last_at ON last_at.entity_id = existence.entity_id AND last_at.timestamp = existence.timestamp
$$ LANGUAGE sql STABLE;


CREATE FUNCTION directory.new_existence_state(timestamp with time zone)
    RETURNS SETOF directory.existence
AS $$
SELECT
    staging_state.timestamp,
    staging_state.exists,
    staging_state.entity_id,
    staging_state.entity_type_id
FROM directory.existence_staging_state($1) staging_state
LEFT JOIN directory.existence_at($1) existence_at ON existence_at.entity_id = staging_state.entity_id
WHERE existence_at.entity_id IS NULL OR (existence_at.exists <> staging_state.exists AND existence_at.timestamp < staging_state.timestamp);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION directory.transfer_existence(timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
INSERT INTO directory.existence(timestamp, exists, entity_id, entity_type_id)
(
    SELECT * FROM directory.new_existence_state($1)
);

TRUNCATE directory.existence_staging;

SELECT $1;
$$ LANGUAGE sql VOLATILE;
