CREATE OR REPLACE FUNCTION entity_tag.define(type_name name, tag_group text, sql text)
	RETURNS entity_tag.type
AS $$
DECLARE
	result entity_tag.type;
BEGIN
	INSERT INTO entity_tag.type(name, taggroup_id) SELECT type_name, id FROM directory.taggroup WHERE name = tag_group;

	EXECUTE format('CREATE VIEW entity_tag.%I AS %s;', type_name, sql);
	EXECUTE format('ALTER VIEW entity_tag.%I OWNER TO minerva_admin', type_name);
    	EXECUTE format('GRANT SELECT ON TABLE entity_tag.%I TO minerva;', type_name);

	SELECT * INTO result FROM entity_tag.type WHERE name = type_name;

	RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION entity_tag.transfer_to_staging(name name)
	RETURNS bigint
AS $$
DECLARE
	insert_count bigint;
BEGIN
	EXECUTE format('INSERT INTO entity_tag.entitytaglink_staging(entity_id, tag_name, taggroup_id)
SELECT entity_id, tag, taggroup_id FROM entity_tag.%I, entity_tag.type WHERE type.name = $1', name)
	USING name;

	GET DIAGNOSTICS insert_count = ROW_COUNT;

	RETURN insert_count;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE VIEW entity_tag._new_tags_in_staging AS
SELECT
	staging.tag_name AS name,
	staging.taggroup_id
FROM entity_tag.entitytaglink_staging staging
LEFT JOIN directory.tag ON lower(tag.name) = lower(tag_name) WHERE tag.name IS NULL
GROUP BY staging.tag_name, staging.taggroup_id;

ALTER VIEW entity_tag._new_tags_in_staging OWNER TO minerva_admin;
GRANT SELECT ON TABLE entity_tag._new_tags_in_staging TO minerva;


CREATE OR REPLACE FUNCTION entity_tag.add_new_tags()
	RETURNS bigint
AS $$
	WITH t AS (
		INSERT INTO directory.tag(name, taggroup_id, description)
		SELECT name, taggroup_id, 'created by entity_tag.update'
		FROM entity_tag._new_tags_in_staging
		RETURNING *
	)
	SELECT count(*) FROM t;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE VIEW entity_tag._new_links_in_staging AS
SELECT
	staging.entity_id,
	tag.id AS tag_id
FROM entity_tag.entitytaglink_staging staging
JOIN directory.tag ON lower(tag.name) = lower(staging.tag_name)
LEFT JOIN directory.entitytaglink etl ON etl.entity_id = staging.entity_id AND etl.tag_id = tag.id
WHERE etl.entity_id IS NULL;

ALTER VIEW entity_tag._new_links_in_staging OWNER TO minerva_admin;
GRANT SELECT ON TABLE entity_tag._new_links_in_staging TO minerva;


CREATE OR REPLACE FUNCTION entity_tag.add_new_links(add_limit integer)
	RETURNS bigint
AS $$
	WITH t AS (
		INSERT INTO directory.entitytaglink(entity_id, tag_id)
		SELECT entity_id, tag_id
		FROM entity_tag._new_links_in_staging
        LIMIT $1
		RETURNING *
	)
	SELECT count(*) FROM t;
$$ LANGUAGE sql VOLATILE;


CREATE OR REPLACE VIEW entity_tag._obsolete_links AS
SELECT
	etl.entity_id,
	etl.tag_id
FROM directory.entitytaglink etl
JOIN directory.tag ON tag.id = etl.tag_id
LEFT JOIN entity_tag.entitytaglink_staging staging ON staging.tag_name = tag.name AND staging.entity_id = etl.entity_id
WHERE tag.name IN (SELECT tag_name FROM entity_tag.entitytaglink_staging GROUP BY tag_name) AND staging.entity_id IS NULL;

ALTER VIEW entity_tag._obsolete_links OWNER TO minerva_admin;
GRANT SELECT ON TABLE entity_tag._obsolete_links TO minerva;


CREATE OR REPLACE FUNCTION entity_tag.remove_obsolete_links()
	RETURNS bigint
AS $$
	WITH t AS (
		DELETE FROM directory.entitytaglink
		USING entity_tag._obsolete_links
		WHERE entitytaglink.entity_id = _obsolete_links.entity_id AND entitytaglink.tag_id = _obsolete_links.tag_id
		RETURNING *
	)
	SELECT count(*) FROM t;
$$ LANGUAGE sql VOLATILE;


CREATE TYPE entity_tag.process_staged_links_result AS (
	tags_added bigint,
	links_added bigint,
	links_removed bigint 
);


CREATE OR REPLACE FUNCTION entity_tag.process_staged_links(process_limit integer)
	RETURNS entity_tag.process_staged_links_result
AS $$
DECLARE
    result entity_tag.process_staged_links_result;
BEGIN
	result.tags_added = entity_tag.add_new_tags();
	result.links_added = entity_tag.add_new_links($1);
	result.links_removed = entity_tag.remove_obsolete_links();

	TRUNCATE entity_tag.entitytaglink_staging;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE TYPE entity_tag.update_result AS (
	staged bigint,
	tags_added bigint,
	links_added bigint,
	links_removed bigint 
);


CREATE OR REPLACE FUNCTION entity_tag.update(type_name name, update_limit integer DEFAULT 50000)
	RETURNS entity_tag.update_result
AS $$
DECLARE
    result entity_tag.update_result;
    process_result entity_tag.process_staged_links_result;
BEGIN
	result.staged = entity_tag.transfer_to_staging(type_name);

    process_result = entity_tag.process_staged_links(update_limit);

	result.tags_added = process_result.tags_added;
	result.links_added = process_result.links_added;
	result.links_removed = process_result.links_removed;

    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;
