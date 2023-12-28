DROP SCHEMA IF EXISTS "entity_set";

DROP TABLE "directory"."entity_set";

DROP FUNCTION "directory"."update_modified_column"();

SELECT directory.create_entity_type('entity_set');

SELECT directory.create_data_source('minerva');

SELECT attribute_directory.create_attribute_store(
  'minerva',
  'entity_set',
  ARRAY[
    ('name', 'text', ''),
    ('fullname', 'text', ''),
    ('group', 'text', ''),
    ('source_entity_type', 'text', ''),
    ('owner', 'text', ''),
    ('description', 'text', ''),
    ('last_update', 'date', '')
  ]::attribute_directory.attribute_descr[]
);

CREATE FUNCTION "relation_directory"."entity_set_exists"("owner" text, "name" text)
    RETURNS boolean
AS $$
SELECT CASE COUNT(*)
  WHEN 0 THEN false
  ELSE true
END
FROM attribute.minerva_entity_set WHERE owner = $1 AND name = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "relation_directory"."create_entity_set"("name" text, "group" text, "entity_type_name" text, "owner" text, "description" text)
    RETURNS attribute.minerva_entity_set
AS $$
DECLARE
  entity_id integer;
BEGIN
  EXECUTE FORMAT(
    'CREATE TABLE IF NOT EXISTS relation."%s->entity_set"('
    'source_id integer, '
    'target_id integer, '
    'PRIMARY KEY (source_id, target_id));',
    entity_type_name
  );
  PERFORM relation_directory.name_to_type(entity_type_name || '->entity_set');
  SELECT id FROM entity.to_entity_set(name || '_' || "group" || '_' || owner) INTO entity_id;
  INSERT INTO attribute_staging.minerva_entity_set(
      entity_id, timestamp, name, fullname, "group", source_entity_type, owner, description, last_update
    ) VALUES (
      entity_id,
      now(),
      name,
      name || '_' || "group" || '_' || owner,
      "group",
      entity_type_name,
      owner,
      description,
      CURRENT_DATE
    );
  PERFORM attribute_directory.transfer_staged(attribute_directory.get_attribute_store('minerva', 'entity_set'));
  PERFORM attribute_directory.materialize_curr_ptr(attribute_directory.get_attribute_store('minerva', 'entity_set'));
  RETURN es FROM attribute.minerva_entity_set es WHERE es.name = $1 AND es.owner = $4;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "relation_directory"."update_entity_set_attributes"(attribute.minerva_entity_set)
    RETURNS void
AS $$
INSERT INTO attribute_staging.minerva_entity_set(
  entity_id, timestamp, name, fullname, "group", source_entity_type, owner, description, last_update
) VALUES (
  $1.entity_id,
  now(),
  $1.name,
  $1.fullname,
  $1."group",
  $1.source_entity_type,
  $1.owner,
  $1.description,
  CURRENT_DATE
);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "relation_directory"."get_entity_set_data"("name" text, "owner" text)
    RETURNS attribute.minerva_entity_set
AS $$
SELECT * FROM attribute.minerva_entity_set WHERE name = $1 AND owner = $2;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "relation_directory"."add_entity_to_set"(attribute.minerva_entity_set, "entity" text)
    RETURNS attribute.minerva_entity_set
AS $$
SELECT relation_directory.update_entity_set_attributes($1);
SELECT action(FORMAT(
  'INSERT INTO relation."%s->entity_set" (source_id, target_id) '
  'SELECT source.id AS source_id, %s AS target '
  'FROM entity.%I source '
  'WHERE source.name = ''%s'''
  'ON CONFLICT DO NOTHING;',
  $1.source_entity_type,
  $1.entity_id,
  $1.source_entity_type,
  $2
));
SELECT * FROM attribute.minerva_entity_set es WHERE es.entity_id = $1.entity_id;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "relation_directory"."remove_entity_from_set"(attribute.minerva_entity_set, "entity" text)
    RETURNS void
AS $$
SELECT relation_directory.update_entity_set_attributes($1);
SELECT action(FORMAT(
  'DELETE es FROM relation."%s->entity_set" es '
  'JOIN entity.%I source ON es.source_id = source.id '
  'WHERE source.name = ''%s'' AND target_id = %s;',
  $1.source_entity_type,
  $1.source_entity_type,
  $2,
  $1.entity_id
));
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "relation_directory"."add_entities_to_set"(attribute.minerva_entity_set, "entities" text[])
    RETURNS void
AS $$
SELECT relation_directory.add_entity_to_set($1, e) FROM unnest($2) e;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "relation_directory"."change_set_entities"(attribute.minerva_entity_set, "entities" text[])
    RETURNS void
AS $$
SELECT action(FORMAT(
  'DELETE FROM relation."%s->entity_set" '
  'WHERE target_id = %s;',
  $1.source_entity_type,
  $1.entity_id
));
SELECT relation_directory.add_entities_to_set($1, $2);
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "relation_directory"."change_set_entities"(attribute.minerva_entity_set, "entities" text[]) IS 'Set the entities in the set to exactly the specified entities';


CREATE FUNCTION "relation_directory"."change_set_entities_guarded"(attribute.minerva_entity_set, "entities" text[])
    RETURNS text[]
AS $$
DECLARE
  entity text;
  real_entity text;
  result text[];
  newresult text[];
BEGIN
  SELECT $2 INTO result;
  FOREACH entity IN ARRAY $2 LOOP
    EXECUTE FORMAT(
      'SELECT name FROM entity.%I WHERE name = ''%s'';',
      $1.source_entity_type,
      entity
    ) INTO real_entity;
    SELECT array_remove(result, real_entity) INTO result;
  END LOOP;
  IF ARRAY_LENGTH(result, 1) IS NULL THEN
    PERFORM relation_directory.change_set_entities($1, $2);
  END IF;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;

COMMENT ON FUNCTION "relation_directory"."change_set_entities_guarded"(attribute.minerva_entity_set, "entities" text[]) IS 'Only sets the entities if all specified entities are actually valid.
Returns those entities that were invalid.';


CREATE FUNCTION "relation_directory"."get_entity_set_members"(attribute.minerva_entity_set)
    RETURNS text[]
AS $$
DECLARE
  result text[];
BEGIN
  EXECUTE FORMAT(
    'SELECT array_agg(e.name) '
    'FROM relation."%s->entity_set" es JOIN entity.%I e ON es.source_id = e.id '
    'WHERE es.target_id = %s',
    $1.source_entity_type,
    $1.source_entity_type,
    $1.entity_id
  ) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "relation_directory"."create_entity_set_guarded"("name" text, "group" text, "entity_type_name" text, "owner" text, "description" text, "entities" text[])
    RETURNS text[]
AS $$
DECLARE
  entity text;
  real_entity text;
  result text[];
  newresult text[];
  entityset integer;
BEGIN
  SELECT $6 INTO result;
  FOREACH entity IN ARRAY $6 LOOP
    EXECUTE FORMAT(
      'SELECT name FROM entity.%I WHERE name = ''%s'';',
      $3,
      entity
    ) INTO real_entity;
    SELECT array_remove(result, real_entity) INTO result;
  END LOOP;
  IF ARRAY_LENGTH(result, 1) IS NULL THEN
    SELECT id FROM relation_directory.create_entity_set($1, $2, $3, $4, $5) INTO entityset;
    PERFORM relation_directory.change_set_entities(t, $6) 
      FROM attribute.minerva_entity_set t
      WHERE t.id = entityset;
  END IF;
  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION "relation_directory"."get_entity_set_members"("name" text, "owner" text)
    RETURNS text[]
AS $$
SELECT relation_directory.get_entity_set_members(es)
  FROM attribute.minerva_entity_set es 
  WHERE owner = $2 AND name = $1;
$$ LANGUAGE sql STABLE;

