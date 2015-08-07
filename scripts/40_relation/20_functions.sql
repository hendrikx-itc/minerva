CREATE OR REPLACE FUNCTION relation.create_relation_table(name text, type_id int)
    RETURNS void
AS $$
DECLARE
    sql text;
    full_table_name text;
BEGIN
    EXECUTE format('CREATE TABLE %I.%I (
    CHECK (type_id=%L)
    ) INHERITS (relation."all");', 'relation', name, type_id);

    EXECUTE format('ALTER TABLE %I.%I OWNER TO minerva_admin;', 'relation', name);

    EXECUTE format('ALTER TABLE ONLY %I.%I
    ADD CONSTRAINT %I
    PRIMARY KEY (source_id, target_id);', 'relation', name, name || '_pkey');

    EXECUTE format('GRANT SELECT ON TABLE %I.%I TO minerva;', 'relation', name);
    EXECUTE format('GRANT INSERT,DELETE,UPDATE ON TABLE %I.%I TO minerva_writer;', 'relation', name);

    EXECUTE format('CREATE INDEX %I ON %I.%I USING btree (target_id);', 'ix_' || name || '_target_id', 'relation', name);
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;


CREATE OR REPLACE FUNCTION relation.get_type(character varying)
    RETURNS relation.type
AS $$
    SELECT type FROM relation.type WHERE name = $1;
$$ LANGUAGE SQL STABLE STRICT;


CREATE OR REPLACE FUNCTION relation.create_type(character varying)
    RETURNS relation.type
AS $$
    INSERT INTO relation.type (name) VALUES ($1) RETURNING type;
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE OR REPLACE FUNCTION relation.name_to_type(character varying)
    RETURNS relation.type
AS $$
    SELECT COALESCE(relation.get_type($1), relation.create_type($1));
$$ LANGUAGE SQL VOLATILE STRICT;


CREATE OR REPLACE FUNCTION relation.update(relation.type, text)
    RETURNS relation.type
AS $$
    SELECT public.action(
        $1,
        ARRAY[
            format('CREATE OR REPLACE VIEW relation_def.%I AS %s', $1.name, $2),
            format('ALTER VIEW relation_def.%I OWNER TO minerva_admin', $1.name)
        ]::text[]
    );
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION relation.set_view_permissions(relation.type)
    RETURNS relation.type
AS $$
    SELECT public.action(
        $1, format('GRANT SELECT ON relation_def.%I TO minerva', $1.name)
    );
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION relation.define(name, text)
    RETURNS relation.type
AS $$
    SELECT relation.set_view_permissions(
        relation.update(
            relation.name_to_type($1::character varying),
            $2
        )
    );
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION relation.define_reverse(reverse name, original name)
    RETURNS relation.type
AS $$
SELECT relation.define($1, format(
$query$SELECT
    target_id AS source_id,
    source_id AS target_id
FROM relation_def.%I$query$, $2));
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION relation.define_reverse(reverse name, original relation.type)
    RETURNS relation.type
AS $$
SELECT relation.define($1, format(
$query$SELECT
    target_id AS source_id,
    source_id AS target_id
FROM relation_def.%I$query$, $2.name));
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


CREATE VIEW relation.dependencies AS
SELECT
    type,
    max(depth) depth
FROM (SELECT dep_recurse.view_ref('relation_def', type.name) AS ref FROM relation.type) root_obj
JOIN dep_recurse.dependency_tree ON
    (root_obj.ref).obj_id = dependency_tree.root_obj_id
    AND
    (root_obj.ref).obj_type = dependency_tree.root_obj_type
JOIN pg_class ON pg_class.oid = (dependency_tree.obj_ref).obj_id
JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace AND pg_namespace.nspname = 'relation'
JOIN relation.type ON type.name = pg_class.relname
GROUP BY type;


CREATE VIEW relation.materialization_order AS
SELECT (foo.t).*, depth
FROM (
    SELECT t, coalesce(depth, 0) depth
    FROM relation.type t
    LEFT JOIN relation.dependencies ON (dependencies.type).id = t.id
    WHERE dep_recurse.view_ref('relation_def', t.name) IS NOT NULL
) foo
ORDER BY depth DESC;

GRANT SELECT ON relation.materialization_order TO minerva;


CREATE OR REPLACE FUNCTION relation.create_all_materialized(name)
    RETURNS name
AS $$
    SELECT public.action(
        $1,
        ARRAY[
            format(
                'CREATE TABLE relation.%I ('
                'source_id integer NOT NULL, '
                'target_id integer NOT NULL, '
                'type_id integer NOT NULL'
                ');',
                $1
            ),

            format('ALTER TABLE relation.%I OWNER TO minerva_admin;', $1),

            format('GRANT ALL ON TABLE relation.%I TO minerva_admin;', $1),
            format('GRANT SELECT ON TABLE relation.%I TO minerva;', $1),
            format('GRANT INSERT,DELETE,UPDATE ON TABLE relation.%I TO minerva_writer;', $1)
        ]
    );
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION relation.create_all_materialized_indexes(name)
    RETURNS name
AS $$
    SELECT public.action(
        $1,
        ARRAY[
            format(
                'ALTER TABLE relation.%I
                ADD PRIMARY KEY (source_id, target_id, type_id);',
                $1
            ),
            format('CREATE INDEX ON relation.%I USING btree (target_id);', $1),
            format('CREATE INDEX ON relation."all_materialized" USING btree (type_id);', $1)
        ]
    );
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION relation.replace_all_materialized(name)
    RETURNS name
AS $$
    SELECT public.action($1, ARRAY[
        'DROP TABLE relation.all_materialized',
        format('ALTER TABLE relation.%I RENAME TO all_materialized', $1)
    ]);
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION relation.populate_all_materialized(name)
    RETURNS name
AS $$
    SELECT public.action(
        $1,
        format(
            'INSERT INTO relation.%I(source_id, target_id, type_id) '
            'SELECT source_id, target_id, type_id '
            'FROM relation.all',
            $1
        )
    );
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION relation.update_all_materialized(intermediate_name name)
    RETURNS name
AS $$
    SELECT relation.create_all_materialized($1);
    SELECT relation.populate_all_materialized($1);
    SELECT relation.replace_all_materialized($1);
    SELECT relation.create_all_materialized_indexes('all_materialized');
$$ LANGUAGE sql VOLATILE;

