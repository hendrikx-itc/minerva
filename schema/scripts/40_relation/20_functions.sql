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


CREATE FUNCTION relation_directory.create_relation_table_sql(name text, type_id int)
    RETURNS text[]
AS $$
    SELECT ARRAY[
        format(
            'CREATE TABLE %I.%I (
    CHECK (type_id=%L)
    ) INHERITS (%I."all");',
            relation_directory.table_schema(),
            name,
            type_id,
            relation_directory.table_schema()
        ),
        format(
            'ALTER TABLE ONLY %I.%I
    ADD CONSTRAINT %I
    PRIMARY KEY (source_id, target_id);',
            relation_directory.table_schema(),
            name,
            name || '_pkey'
        ),
        format(
            'GRANT SELECT ON TABLE %I.%I TO minerva;',
            relation_directory.table_schema(),
            name
        ),
        format(
            'GRANT INSERT,DELETE,UPDATE ON TABLE %I.%I TO minerva_writer;',
            relation_directory.table_schema(),
            name
        ),
        format(
            'CREATE INDEX %I ON %I.%I USING btree (source_id);',
            'ix_' || name || '_source_id',
            relation_directory.table_schema(), name
        ),
        format(
            'CREATE INDEX %I ON %I.%I USING btree (target_id);',
            'ix_' || name || '_target_id',
            relation_directory.table_schema(),
            name
        )
    ];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION relation_directory.create_relation_table(name name, type_id int)
    RETURNS name
AS $$
    SELECT public.action($1, relation_directory.create_relation_table_sql($1, $2));
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION relation_directory.get_type(character varying)
    RETURNS relation_directory.type
AS $$
    SELECT type FROM relation_directory.type WHERE name = $1;
$$ LANGUAGE SQL STABLE STRICT;


CREATE FUNCTION relation_directory.create_type(character varying)
    RETURNS relation_directory.type
AS $$
    INSERT INTO relation_directory.type (name) VALUES ($1) RETURNING type;
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE FUNCTION relation_directory.name_to_type(character varying)
    RETURNS relation_directory.type
AS $$
    SELECT COALESCE(
        relation_directory.get_type($1),
        relation_directory.create_type($1)
    );
$$ LANGUAGE sql VOLATILE STRICT;


CREATE FUNCTION relation_directory.create_relation_view_sql(relation_directory.type, text)
    RETURNS text[]
AS $$
    SELECT ARRAY[
        format('CREATE VIEW %I.%I AS %s', relation_directory.view_schema(), $1.name, $2)
    ];
$$ LANGUAGE sql STABLE;


CREATE FUNCTION relation_directory.create_relation_view(relation_directory.type, text)
    RETURNS relation_directory.type
AS $$
    SELECT public.action(
        $1,
        relation_directory.create_relation_view_sql($1, $2)
    );
$$ LANGUAGE sql VOLATILE SECURITY DEFINER;


CREATE FUNCTION relation_directory.define(name, text)
    RETURNS relation_directory.type
AS $$
    SELECT relation_directory.create_relation_view(
        relation_directory.name_to_type($1::character varying),
        $2
    );
$$ LANGUAGE sql VOLATILE;


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


CREATE OR REPLACE FUNCTION relation.materialize_relation(type relation.type)
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

