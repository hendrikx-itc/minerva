CREATE FUNCTION relation_directory.table_schema()
    RETURNS name
AS $$
    SELECT 'relation'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION relation_directory.view_schema()
    RETURNS name
AS $$
    SELECT 'relation_def'::name;
$$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION relation_directory.create_relation_table_sql(relation_directory.type)
    RETURNS text[]
AS $$
    SELECT ARRAY[
        format(
            'CREATE TABLE %I.%I ('
            'PRIMARY KEY(source_id, target_id)'
            ') INHERITS (%I.base);',
            relation_directory.table_schema(),
            $1.name,
            relation_directory.table_schema()
        ),
        format(
            'GRANT SELECT ON TABLE %I.%I TO minerva;',
            relation_directory.table_schema(),
            $1.name
        ),
        format(
            'GRANT INSERT,DELETE,UPDATE ON TABLE %I.%I TO minerva_writer;',
            relation_directory.table_schema(),
            $1.name
        ),
        format(
            'CREATE INDEX %I ON %I.%I USING btree (target_id);',
            'ix_' || $1.name || '_target_id',
            relation_directory.table_schema(),
            $1.name
        )
    ];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION relation_directory.create_relation_table(relation_directory.type)
    RETURNS relation_directory.type
AS $$
    SELECT public.action($1, relation_directory.create_relation_table_sql($1));
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION relation_directory.drop_relation_table_sql(relation_directory.type)
    RETURNS text
AS $$
    SELECT format('DROP TABLE %I.%I', relation_directory.table_schema(), $1.name);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION relation_directory.drop_relation_table(relation_directory.type)
    RETURNS relation_directory.type
AS $$
    SELECT public.action($1, relation_directory.drop_relation_table_sql($1));
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION relation_directory.get_type(name)
    RETURNS relation_directory.type
AS $$
    SELECT type FROM relation_directory.type WHERE name = $1;
$$ LANGUAGE SQL STABLE STRICT;


CREATE FUNCTION relation_directory.create_type(name)
    RETURNS relation_directory.type
AS $$
    INSERT INTO relation_directory.type (name) VALUES ($1) RETURNING type;
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE FUNCTION relation_directory.name_to_type(name)
    RETURNS relation_directory.type
AS $$
    SELECT COALESCE(
        relation_directory.get_type($1),
        relation_directory.create_type($1)
    );
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION relation_directory.create_relation_view_sql(relation_directory.type, text)
    RETURNS text
AS $$
    SELECT format(
        'CREATE VIEW %I.%I AS %s',
        relation_directory.view_schema(),
        $1.name,
        $2
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION relation_directory.create_relation_view(relation_directory.type, text)
    RETURNS relation_directory.type
AS $$
    SELECT public.action(
        $1,
        relation_directory.create_relation_view_sql($1, $2)
    );
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION relation_directory.drop_relation_view_sql(relation_directory.type)
    RETURNS text
AS $$
    SELECT format(
        'DROP VIEW IF EXISTS %I.%I',
        relation_directory.view_schema(),
        $1.name
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION relation_directory.drop_relation_view(relation_directory.type)
    RETURNS relation_directory.type
AS $$
    SELECT public.action(
        $1,
        relation_directory.drop_relation_view_sql($1)
    );
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION relation_directory.define(name)
    RETURNS relation_directory.type
AS $$
    SELECT relation_directory.create_relation_table(
        relation_directory.create_type($1)
    );
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION relation_directory.define(name) IS
'Defines a new relation type, creates the corresponding table and then returns
the new type record';


CREATE FUNCTION relation_directory.define(name, view_sql text)
    RETURNS relation_directory.type
AS $$
    SELECT relation_directory.create_relation_view(
        relation_directory.define($1),
        $2
    );
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION relation_directory.define(name, view_sql text) IS
'Defines a new relation type (just like relation_directory.define(name)),
including a view that will be used to populate the relation table.';


CREATE FUNCTION relation_directory.remove(name)
    RETURNS void
AS $$
    SELECT relation_directory.drop_relation_view(
        relation_directory.drop_relation_table(type)
    )
    FROM relation_directory.type WHERE name = $1;

    DELETE FROM relation_directory.type WHERE name = $1;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION relation_directory.create_or_replace_relation_view_sql(
        relation_directory.type, text)
    RETURNS text
AS $$
    SELECT format(
        'CREATE OR REPLACE VIEW %I.%I AS %s',
        relation_directory.view_schema(),
        $1.name,
        $2
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION relation_directory.update(relation_directory.type, text)
    RETURNS relation_directory.type
AS $$
    SELECT public.action(
        $1,
        relation_directory.create_or_replace_relation_view_sql($1, $2)
    );
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION relation_directory.define_reverse(reverse name, original name)
    RETURNS relation_directory.type
AS $$
SELECT relation_directory.define(
    $1,
    format(
        $query$SELECT
    target_id AS source_id,
    source_id AS target_id
FROM %I.%I$query$,
        relation_directory.view_schema(),
        $2
    )
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION relation_directory.define_reverse(reverse name, original relation_directory.type)
    RETURNS relation_directory.type
AS $$
SELECT relation_directory.define(
    $1,
    format(
        $query$SELECT
    target_id AS source_id,
    source_id AS target_id
FROM %I.%I$query$,
        relation_directory.view_schema(),
        $2.name
    )
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION relation_directory.materialize_relation(type relation_directory.type)
  RETURNS integer AS
$$
DECLARE
    result integer;
BEGIN
    EXECUTE format('DELETE FROM relation.%I;', $1.name);
    EXECUTE format('INSERT INTO relation.%I SELECT *, %L FROM relation_def.%I;', $1.name, $1.id, $1.name);

    GET DIAGNOSTICS result = ROW_COUNT;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

