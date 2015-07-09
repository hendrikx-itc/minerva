
CREATE TYPE directory.existence AS (
    "timestamp" timestamp with time zone,
    "exists" boolean,
    "entity_id" integer );


CREATE OR REPLACE FUNCTION directory.existing_staging(timestamp with time zone, entitytype_id integer)
    RETURNS SETOF directory.existence
AS $$
    SELECT
        $1, True, entity.id
    FROM directory.existence_staging
    JOIN directory.entity ON entity.dn = existence_staging.dn
        AND entity.entitytype_id = entitytype_id;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION directory.non_existing_staging(timestamp with time zone, entitytype_id integer)
    RETURNS SETOF directory.existence
AS $$
    SELECT $1, False, entity.id
    FROM directory.entity
    LEFT JOIN directory.existence_staging ON existence_staging.dn = entity.dn
    WHERE existence_staging.dn IS NULL AND entity.entitytype_id = entitytype_id;
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION directory.existence_staging_state(timestamp with time zone, entitytype_id integer)
    RETURNS SETOF directory.existence
AS $$
    SELECT * FROM directory.existing_staging($1, $2)
    UNION
    SELECT * FROM directory.non_existing_staging($1, $2)
$$ LANGUAGE sql STABLE;


CREATE OR REPLACE FUNCTION directory.new_existence_state(timestamp with time zone, entitytype_id integer)
   RETURNS SETOF directory.existence
AS $$
DECLARE
    store attribute_directory.attributestore;
    functionname text;
BEGIN
    store = attribute_directory.get_attributestore((directory.get_datasource('existence')).id, entitytype_id);
    functionname = attribute_directory.at_function_name(store);

    RETURN QUERY EXECUTE format('
        SELECT staging_state.timestamp, staging_state.exists, staging_state.entity_id
        FROM directory.existence_staging_state($1, $2) staging_state
        LEFT JOIN attribute_history.%I($1) existence_at
            ON existence_at.entity_id = staging_state.entity_id
        WHERE existence_at.entity_id IS NULL
            OR (existence_at.exists <> staging_state.exists AND existence_at.timestamp < staging_state.timestamp)',
        functionname ) USING $1, $2;
END;
$$ LANGUAGE plpgsql STABLE;


CREATE OR REPLACE FUNCTION directory.transfer_existence(timestamp with time zone)
  RETURNS timestamp with time zone AS
$$
DECLARE
  et_id integer;
  tablename name;
  astore attribute_directory.attributestore;
BEGIN
  FOR et_id in SELECT distinct t.id
	FROM directory.entitytype t
	JOIN directory.entity e ON e.entitytype_id = t.id
	JOIN directory.existence_staging es ON es.dn = e.dn
  LOOP
	astore = attribute_directory.get_attributestore((directory.get_datasource('existence')).id, et_id);

	tablename = attribute_directory.to_table_name( astore );

	EXECUTE FORMAT(
		'INSERT INTO attribute_staging.%I(timestamp, exists, entity_id) (
		   SELECT timestamp, exists, entity_id FROM directory.new_existence_state($1, $2)
		 )', tablename ) USING $1, et_id;

	astore = attribute_directory.transfer_staged( astore );

  END LOOP;

  DELETE FROM directory.existence_staging;

  RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;