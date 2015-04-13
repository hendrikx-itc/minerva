CREATE OR REPLACE FUNCTION directory.getentitybydn(character varying)
    RETURNS TABLE(
        id integer,
        entitytype_id integer,
        name character varying,
        parent_id integer)
AS $$
    SELECT id, entitytype_id, name, parent_id FROM directory.entity WHERE dn=$1;
$$ LANGUAGE sql STABLE COST 100 ROWS 1;

CREATE OR REPLACE FUNCTION directory.getentitybyid(integer)
    RETURNS TABLE(
        dn character varying,
        entitytype_id integer,
        name character varying,
        parent_id integer)
AS $$
    SELECT dn, entitytype_id, name, parent_id FROM directory.entity WHERE id=$1;
$$ LANGUAGE sql STABLE COST 100 ROWS 1;

CREATE OR REPLACE FUNCTION directory.addentity(timestamp with time zone, character varying(100), integer, character varying, integer)
    RETURNS integer
AS $$
    INSERT INTO directory.entity (id, first_appearance, name, entitytype_id, dn, parent_id)
    VALUES (DEFAULT, $1, $2, $3, $4, $5) RETURNING id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION directory.get_entitytype_id(character varying)
  RETURNS integer
AS $$
    SELECT id FROM directory.entitytype WHERE lower(name)=lower($1);
$$ LANGUAGE sql STABLE COST 100;


CREATE OR REPLACE FUNCTION directory.get_entity(character varying)
    RETURNS directory.entity
AS $$
    SELECT entity FROM directory.entity WHERE dn = $1;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION directory.entities_by_type(character varying)
    RETURNS SETOF directory.entity
AS $$
    SELECT e.*
    FROM directory.entity e
    JOIN directory.entitytype et ON et.id = e.entitytype_id
    WHERE et.name = $1;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION directory.entities_by_type(integer)
    RETURNS SETOF directory.entity
AS $$
    SELECT *
    FROM directory.entity
    WHERE entitytype_id = $1;
$$ LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION directory.get_entitytype(character varying)
    RETURNS directory.entitytype
AS $$
    SELECT entitytype FROM directory.entitytype WHERE lower(name) = lower($1);
$$ LANGUAGE SQL STABLE STRICT;


CREATE OR REPLACE FUNCTION directory.get_datasource(character varying)
    RETURNS directory.datasource
AS $$
    SELECT datasource FROM directory.datasource WHERE name = $1;
$$ LANGUAGE SQL STABLE STRICT;


CREATE OR REPLACE FUNCTION directory.create_datasource(character varying)
    RETURNS directory.datasource
AS $$
    INSERT INTO directory.datasource
        (name, description, timezone)
    VALUES ($1, 'default', COALESCE(system.get_setting_value('default_timezone'), 'UTC'))
    RETURNING datasource;
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE TYPE directory.dn_part AS (type_name character varying, name character varying);


CREATE OR REPLACE FUNCTION directory.dn_part_to_string(directory.dn_part)
    RETURNS character varying
AS $$
    SELECT $1.type_name || '=' || $1.name;
$$ LANGUAGE SQL IMMUTABLE STRICT;


CREATE CAST (directory.dn_part AS character varying)
    WITH FUNCTION directory.dn_part_to_string (directory.dn_part);


CREATE OR REPLACE FUNCTION directory.array_to_dn_part(character varying[])
    RETURNS directory.dn_part
AS $$
    SELECT CAST(ROW($1[1], $1[2]) AS directory.dn_part);
$$ LANGUAGE SQL IMMUTABLE;


CREATE CAST (character varying[] AS directory.dn_part)
    WITH FUNCTION directory.array_to_dn_part (character varying[]);


CREATE OR REPLACE FUNCTION directory.split_raw_part(character varying)
    RETURNS directory.dn_part
AS $$
    SELECT directory.array_to_dn_part(string_to_array($1, '='));
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION directory.explode_dn(character varying)
    RETURNS directory.dn_part[]
AS $$
    SELECT array_agg(directory.split_raw_part(raw_part)) FROM unnest(string_to_array($1, ',')) AS raw_part;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION directory.glue_dn(directory.dn_part[])
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
$$ LANGUAGE SQL IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION directory.create_entitytype(character varying)
    RETURNS directory.entitytype
AS $$
    INSERT INTO directory.entitytype(name, description) VALUES ($1, '') RETURNING entitytype;
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE OR REPLACE FUNCTION directory.parent_dn_parts(directory.dn_part[])
    RETURNS directory.dn_part[]
AS $$
    SELECT
        CASE
            WHEN array_length($1, 1) > 1 THEN
                $1[1:array_length($1, 1) - 1]
            ELSE
                NULL
        END;
$$ LANGUAGE SQL IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION directory.parent_dn(character varying)
    RETURNS character varying
AS $$
    SELECT directory.glue_dn(directory.parent_dn_parts(directory.explode_dn($1)));
$$ LANGUAGE SQL IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION directory.name_to_entitytype(character varying)
    RETURNS directory.entitytype
AS $$
    SELECT COALESCE(directory.get_entitytype($1), directory.create_entitytype($1));
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE OR REPLACE FUNCTION directory.entitytype_id(directory.entitytype)
    RETURNS integer
AS $$
    SELECT $1.id;
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE OR REPLACE FUNCTION directory.entity_id(directory.entity)
    RETURNS integer
AS $$
    SELECT $1.id;
$$ LANGUAGE SQL VOLATILE STRICT;


-- Stub
CREATE OR REPLACE FUNCTION directory.dn_to_entity(character varying)
    RETURNS directory.entity
AS $$
    SELECT null::directory.entity;
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE OR REPLACE FUNCTION directory.last_dn_part(directory.dn_part[])
    RETURNS directory.dn_part
AS $$
    SELECT $1[array_length($1, 1)];
$$ LANGUAGE SQL IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION directory.create_entity(character varying)
    RETURNS directory.entity
AS $$
    INSERT INTO directory.entity(first_appearance, name, entitytype_id, dn, parent_id)
        VALUES (
            now(),
            (directory.last_dn_part(directory.explode_dn($1))).name,
            directory.entitytype_id(directory.name_to_entitytype((directory.last_dn_part(directory.explode_dn($1))).type_name)),
            $1,
            directory.entity_id(directory.dn_to_entity(directory.glue_dn(directory.parent_dn_parts(directory.explode_dn($1)))))
        )
        RETURNING entity;
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE OR REPLACE FUNCTION directory.dn_to_entity(character varying)
    RETURNS directory.entity
AS $$
    SELECT COALESCE(directory.get_entity($1), directory.create_entity($1));
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE OR REPLACE FUNCTION directory.get_alias(entity_id integer, aliastype_name character varying)
    RETURNS character varying
AS $$
    SELECT a.name 
      FROM directory.alias a 
      JOIN directory.aliastype at on at.id = a.type_id
     WHERE a.entity_id = $1 and at.name = $2;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION directory.name_to_datasource(character varying)
    RETURNS directory.datasource
AS $$
    SELECT COALESCE(directory.get_datasource($1), directory.create_datasource($1));
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE OR REPLACE FUNCTION directory.dns_to_entity_ids(character varying[])
    RETURNS SETOF integer
AS $$
    SELECT (directory.dn_to_entity(dn)).id FROM unnest($1) dn;
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE TYPE directory.query_part AS (c text[], s text);

CREATE TYPE directory.query_row AS (id integer, dn text, entitytype_id integer);

------------------------------------------
-- Example usage of run_minerva_query:
--
-- SELECT run_minerva_query(ARRAY[(ARRAY['Cell']::text[], '15000')]::query_part[]);
--
-- SELECT run_minerva_query(ARRAY[(ARRAY['Site']::text[], '4343'), (ARRAY['Cell', '3G']::text[], NULL)]::query_part[]);
------------------------------------------

CREATE OR REPLACE FUNCTION directory.run_minerva_query(query directory.query_part[])
    RETURNS TABLE(id integer, dn varchar, entitytype_id integer)
AS $$
BEGIN
    RETURN QUERY EXECUTE compile_minerva_query(query);
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION directory.sumproduct(query directory.query_part[], value_trend text, weight_trend text)
    RETURNS TABLE("timestamp" timestamp with time zone, wavg float)
AS $$
DECLARE
    sql text;
BEGIN
    sql = compile_minerva_query(query);

    sql = format('SELECT t1.timestamp, CAST(SUM(t1."CCR" * t2."Traffic_Full") AS double precision) FROM (' || sql || ') e
JOIN trend."tnpmw-ccr_cell_day_20120521" t1 ON t1.entity_id = e.id
JOIN trend."tnpmw-traffic_cell_day_20120521" t2 ON t2.entity_id = e.id AND t2.timestamp = t1.timestamp
WHERE t1.timestamp = %L
GROUP BY t1.timestamp;', '2012-06-02');

    RETURN QUERY EXECUTE sql;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION directory.wavg(query directory.query_part[], value_trend_id integer, weight_trend_id integer)
    RETURNS TABLE("timestamp" timestamp with time zone, wavg float)
AS $$
DECLARE
    sql text;
BEGIN
    sql = directory.compile_minerva_query(query);

    sql = format('SELECT t1.timestamp, CAST(SUM(t1."CCR" * t2."Traffic_Full") / SUM(t2."Traffic_Full") AS double precision) FROM (' || sql || ') e
JOIN trend."tnpmw-ccr_cell_day_20120521" t1 ON t1.entity_id = e.id
JOIN trend."tnpmw-traffic_cell_day_20120521" t2 ON t2.entity_id = e.id AND t2.timestamp = t1.timestamp
WHERE t1.timestamp = %L
GROUP BY t1.timestamp;', '2012-06-02');

    RETURN QUERY EXECUTE sql;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION directory.compile_minerva_query(query text)
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

CREATE OR REPLACE FUNCTION directory.compile_minerva_query(query directory.query_part[])
    RETURNS text
AS $$
DECLARE
    sql text;
    entity_id_table text;
    entity_id_column text;
    q_part directory.query_part;
    tag text;
BEGIN
    sql = 'SELECT entity.id, entity.dn, entity.entitytype_id FROM directory.entitytaglink tl_1_1';

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


CREATE OR REPLACE FUNCTION directory.make_c_join(index integer, entity_id_table text, entity_id_column text, tag_index integer, tag text)
    RETURNS text
AS $$
DECLARE
    entitytaglink_alias text;
    entitytag_alias text;
BEGIN
    entitytaglink_alias = 'tl_' || index || '_' || tag_index;
    entitytag_alias = 't_' || index || '_' || tag_index;

    IF NOT entity_id_table = entitytaglink_alias THEN
        RETURN format(' JOIN directory.entitytaglink %I ON %I.%I = %I.entity_id', entitytaglink_alias, entity_id_table, entity_id_column, entitytaglink_alias) ||
            format(' JOIN directory.entitytag %I ON %I.id = %I.entitytag_id AND lower(%I.name) = lower(%L)', entitytag_alias, entitytag_alias, entitytaglink_alias, entitytag_alias, tag);
    ELSE
        RETURN format(' JOIN directory.entitytag %I ON %I.id = %I.entitytag_id AND lower(%I.name) = lower(%L)', entitytag_alias, entitytag_alias, entitytaglink_alias, entitytag_alias, tag);
    END IF;
END;
$$ LANGUAGE plpgsql STABLE STRICT;


CREATE OR REPLACE FUNCTION directory.make_s_join(index integer, entity_id_table text, entity_id_column text, alias text)
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


CREATE OR REPLACE FUNCTION directory.tag_entity(entity_id integer, tag character varying)
    RETURNS integer 
AS $$
    INSERT INTO directory.entitytaglink(tag_id, entity_id) SELECT id, $1 FROM directory.tag WHERE name = $2 RETURNING $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION directory.tag_entity(dn character varying, tag character varying)
    RETURNS character varying 
AS $$
    INSERT INTO directory.entitytaglink(tag_id, entity_id)
    SELECT tag.id, entity.id
    FROM directory.tag, directory.entity
    WHERE tag.name = $2 AND entity.dn = $1 RETURNING $1;
$$ LANGUAGE SQL VOLATILE;


CREATE OR REPLACE FUNCTION directory.update_denormalized_entity_tags(entity_id integer)
    RETURNS directory.entity_link_denorm
AS $$
DELETE FROM directory.entity_link_denorm WHERE entity_id = $1;
INSERT INTO directory.entity_link_denorm
SELECT
    entity.id,
    array_agg(lower(tag.name)),
    lower(entity.name)
FROM directory.entity
JOIN directory.entitytaglink etl ON etl.entity_id = entity.id
JOIN directory.tag ON tag.id = etl.tag_id
WHERE entity.id = $1
GROUP BY entity.id
RETURNING *;
$$ LANGUAGE sql VOLATILE;



CREATE OR REPLACE FUNCTION directory.get_existence(timestamp with time zone, integer)
  RETURNS boolean AS
$BODY$

 SELECT public.first(existence."exists" ORDER BY existence."timestamp" DESC) AS "exists"
   FROM directory.existence
   WHERE existence."timestamp" <= $1 AND existence.entity_id = $2
  GROUP BY existence.entity_id

$BODY$
  LANGUAGE sql STABLE STRICT
  COST 100;


CREATE OR REPLACE FUNCTION directory.existing_staging(timestamp with time zone)
    RETURNS SETOF directory.existence
AS $$
    SELECT
        $1, True, entity.id, entity.entitytype_id
    FROM directory.existence_staging
    JOIN directory.entity ON entity.dn = existence_staging.dn;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION directory.non_existing_staging(timestamp with time zone)
    RETURNS SETOF directory.existence
AS $$
    SELECT $1, False, entity.id, entity.entitytype_id
    FROM directory.existence_staging_entitytype_ids
    JOIN directory.entity ON entity.entitytype_id = existence_staging_entitytype_ids.entitytype_id
    LEFT JOIN directory.existence_staging ON existence_staging.dn = entity.dn
    WHERE existence_staging.dn IS NULL;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION directory.existence_staging_state(timestamp with time zone)
    RETURNS SETOF directory.existence
AS $$
    SELECT * FROM directory.existing_staging($1)
    UNION
    SELECT * FROM directory.non_existing_staging($1)
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION directory.existence_at(timestamp with time zone)
    RETURNS SETOF directory.existence
AS $$
    SELECT
        existence.timestamp,
        existence.exists,
        existence.entity_id,
        existence.entitytype_id
    FROM directory.existence JOIN (
        SELECT entity_id, max(timestamp) AS timestamp
        FROM directory.existence
        WHERE timestamp <= $1
        GROUP BY entity_id
    ) last_at ON last_at.entity_id = existence.entity_id AND last_at.timestamp = existence.timestamp
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION directory.new_existence_state(timestamp with time zone)
    RETURNS SETOF directory.existence
AS $$
SELECT
    staging_state.timestamp,
    staging_state.exists,
    staging_state.entity_id,
    staging_state.entitytype_id
FROM directory.existence_staging_state($1) staging_state
LEFT JOIN directory.existence_at($1) existence_at ON existence_at.entity_id = staging_state.entity_id
WHERE existence_at.entity_id IS NULL OR (existence_at.exists <> staging_state.exists AND existence_at.timestamp < staging_state.timestamp);
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION directory.transfer_existence(timestamp with time zone)
    RETURNS timestamp with time zone
AS $$
INSERT INTO directory.existence(timestamp, exists, entity_id, entitytype_id)
(
    SELECT * FROM directory.new_existence_state($1)
);

TRUNCATE directory.existence_staging;

SELECT $1;
$$ LANGUAGE sql VOLATILE;
