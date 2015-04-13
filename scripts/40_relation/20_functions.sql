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

    EXECUTE format('CREATE INDEX %I ON %I.%I USING btree (source_id);', 'ix_' || name || '_source_id', 'relation', name);
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


CREATE OR REPLACE FUNCTION relation.define(name, text)
    RETURNS relation.type
AS $$
DECLARE
    result relation.type;
BEGIN
    result = relation.name_to_type($1::character varying);

    EXECUTE format('CREATE OR REPLACE VIEW relation_def.%I AS %s', $1, $2);
    EXECUTE format('ALTER VIEW relation_def.%I OWNER TO minerva_admin', $1);

    return result;
END;
$$ LANGUAGE plpgsql VOLATILE;


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
