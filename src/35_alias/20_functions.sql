


-- Table 'directory.alias'

-- CREATE TABLE directory.alias
-- (
--     entity_id integer REFERENCES directory.entity(id),
--     "name" character varying NOT NULL,
--     type_id integer REFERENCES directory.alias_type(id),
--     PRIMARY KEY(type_id, entity_id)
-- );
--
-- CREATE INDEX ON directory.alias USING btree (name);
--
-- CREATE INDEX ON directory.alias (lower(name));
--
-- GRANT SELECT ON TABLE directory.alias TO minerva;
-- GRANT INSERT,DELETE,UPDATE ON TABLE directory.alias TO minerva_writer;
--

CREATE FUNCTION alias_directory.alias_schema()
    RETURNS name
AS $$
    SELECT 'alias'::name;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION alias_directory.initialize_alias_type_sql(alias_directory.alias_type)
    RETURNS text[]
AS $$
    SELECT ARRAY[
        format(
            'CREATE TABLE %I.%I ('
            '  id serial PRIMARY KEY,'
            '  %I text UNIQUE NOT NULL,'
            '  entity_id integer REFERENCES directory.entity(id)'
            ');',
            alias_directory.alias_schema(),
            $1.name, $1.name
        )
    ];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION alias_directory.initialize_alias_type(alias_directory.alias_type)
    RETURNS alias_directory.alias_type
AS $$
    SELECT public.action($1, alias_directory.initialize_alias_type_sql($1));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION alias_directory.get_alias(entity_id integer, alias_type_name text)
    RETURNS text
AS $$
DECLARE
    result text;
BEGIN
    EXECUTE format(
        'SELECT %I INTO result FROM alias.%I WHERE entity_id = %s',
        $2, $2, $1
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION alias_directory.create_alias(entity_id integer, alias_type_name text, alias text)
    RETURNS text
AS $$
BEGIN
    EXECUTE format(
        'INSERT INTO alias.%I(entity_id, %I) VALUES ($1, $2)',
        $2, $2
    ) USING $1, $3;

    RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION alias_directory.define_alias_type(name name)
    RETURNS alias_directory.alias_type
AS $$
    INSERT INTO alias_directory.alias_type(name) VALUES ($1) RETURNING *;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION alias_directory.create_alias_type(name name)
    RETURNS alias_directory.alias_type
AS $$
    SELECT alias_directory.initialize_alias_type(
        alias_directory.define_alias_type($1)
    );
$$ LANGUAGE sql VOLATILE;
