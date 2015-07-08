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


CREATE OR REPLACE FUNCTION directory.new_existence_state(timestamp with time zone, entitytype_id integer)
    RETURNS SETOF directory.existence
AS $$
DECLARE
    store attribute_directory.attributestore;
    functionname text;
BEGIN
    store = attribute_directory.get_attributestore((directory.get_datasource('existence')).id, entitytype_id);
    functionname = attribute_directory.at_function_name(store);

    EXECUTE format('

        SELECT staging_state.timestamp, staging_state.exists, staging_state.entity_id, staging_state.entitytype_id
        FROM directory.existence_staging_state($1) staging_state
        LEFT JOIN attribute_history.%I($1) existence_at
            ON existence_at.entity_id = staging_state.entity_id
        WHERE existence_at.entity_id IS NULL
            OR (existence_at.exists <> staging_state.exists AND existence_at.timestamp < staging_state.timestamp)',
        functionname ) USING $1;
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
			SELECT s.timestamp, s.exists, s.entity_id
			FROM directory.new_existence_state($1, $2) s
			WHERE s.entitytype_id = $2 )', tablename ) USING $1, et_id;

	astore = attribute_directory.transfer_staged( astore );

  END LOOP;

  TRUNCATE directory.existence_staging;

  RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;