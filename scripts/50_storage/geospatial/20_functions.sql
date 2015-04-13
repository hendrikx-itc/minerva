
-- ===================
--  handover_relation
-- ===================
-- All cell relations based on relation records of HandoverRelation and Cell.

CREATE OR REPLACE VIEW gis.vhandover_relation AS
         SELECT cell_ho.source_id AS cell_entity_id, 'OUT'::text AS direction, ho_cell.target_id AS neighbour_entity_id, cell_ho.source_id AS source_entity_id, ho_cell.target_id AS target_entity_id, cell_ho.target_id AS ho_entity_id
           FROM relation."Cell->HandoverRelation" cell_ho
      JOIN relation."HandoverRelation->Cell" ho_cell ON cell_ho.target_id = ho_cell.source_id
UNION ALL
         SELECT ho_cell.target_id AS cell_entity_id, 'IN'::text AS direction, cell_ho.source_id AS neighbour_entity_id, cell_ho.source_id AS source_entity_id, ho_cell.target_id AS target_entity_id, cell_ho.target_id AS ho_entity_id
           FROM relation."Cell->HandoverRelation" cell_ho
      JOIN relation."HandoverRelation->Cell" ho_cell ON cell_ho.target_id = ho_cell.source_id;
ALTER TABLE gis.vhandover_relation OWNER TO minerva_admin;
GRANT ALL ON TABLE gis.vhandover_relation TO minerva_admin;
GRANT SELECT ON TABLE gis.vhandover_relation TO minerva;


-- ============================
--  existence_HandoverRelation
-- ============================
-- The existence records for HandoverRelation (virtual) entities based
--  on existence records of the real_handover relations.

CREATE OR REPLACE VIEW gis."vexistence_HandoverRelation" AS
 SELECT DISTINCT existence."timestamp", (true IN ( SELECT last(ex."exists" ORDER BY ex."timestamp") AS last
           FROM directory.existence ex
          WHERE (ex.entity_id = ANY (source_targets.target_ids)) AND ex."timestamp" <= existence."timestamp"
          GROUP BY ex.entity_id)) AS "exists", source_targets.source_id AS entity_id, 305 AS entitytype_id
   FROM ( SELECT rho.source_id, array_agg(rho.target_id) AS target_ids
           FROM relation.real_handover rho
          GROUP BY rho.source_id) source_targets
   JOIN directory.existence ON existence.entity_id = ANY (source_targets.target_ids);
ALTER TABLE gis."vexistence_HandoverRelation" OWNER TO minerva_admin;
GRANT ALL ON TABLE gis."vexistence_HandoverRelation" TO minerva_admin;
GRANT SELECT ON TABLE gis."vexistence_HandoverRelation" TO minerva;

-- ============================
--  handover_relation_existence
-- ============================
-- Handover Relation records with existence information.

CREATE OR REPLACE VIEW gis.vhandover_relation_existence AS
 SELECT handover_relation.cell_entity_id AS entity_id, handover_relation.source_entity_id AS source_id, handover_relation.ho_entity_id AS handover_id, handover_relation.target_entity_id AS target_id, trg_et.name AS target_name, src_et.name AS source_name, tag.name AS tag_name, handover_relation.direction, array_agg((x."exists" || ','::text) || date_part('epoch'::text, x."timestamp") ORDER BY x."timestamp") AS existence, array_agg(htag.name) AS handover_tags
   FROM gis.vhandover_relation handover_relation
   JOIN directory.entity src_et ON src_et.id = handover_relation.source_entity_id
   JOIN directory.entity trg_et ON trg_et.id = handover_relation.target_entity_id
   JOIN directory.entitytaglink etl ON etl.entity_id = handover_relation.neighbour_entity_id
   JOIN directory.tag ON etl.tag_id = tag.id
   JOIN directory.taggroup etg ON etg.id = tag.taggroup_id AND etg.name::text = 'generation'::text
   JOIN gis."existence_HandoverRelation" x ON x.entity_id = handover_relation.ho_entity_id
   JOIN directory.entitytaglink htl ON htl.entity_id = handover_relation.ho_entity_id
   JOIN directory.tag htag ON htl.tag_id = htag.id
   JOIN directory.taggroup ON taggroup.name::text = 'handover'::text AND taggroup.id = htag.taggroup_id
  GROUP BY handover_relation.cell_entity_id, handover_relation.source_entity_id, handover_relation.ho_entity_id, handover_relation.target_entity_id, trg_et.name, src_et.name, tag.name, handover_relation.direction;
ALTER TABLE gis.vhandover_relation_existence OWNER TO minerva_admin;
GRANT ALL ON TABLE gis.vhandover_relation_existence TO minerva_admin;
GRANT SELECT ON TABLE gis.vhandover_relation_existence TO minerva;


-- ===============
--  get_handovers
-- ===============
-- Function to get all handover information about the handovers to and from a certain Cell.

CREATE OR REPLACE FUNCTION gis.get_handovers(IN integer)
  RETURNS TABLE(source_id integer, handover_id integer, target_id integer, target_name character varying, source_name character varying, tag_name character varying, direction text, existence text[], handover_tags character varying[]) AS
$BODY$
  SELECT source_id, handover_id, target_id, target_name, source_name, tag_name, direction, existence, handover_tags
  FROM gis.handover_relation_existence t WHERE t.entity_id = $1
$BODY$ LANGUAGE sql STABLE COST 100 ROWS 1000;
ALTER FUNCTION gis.get_handovers(integer) OWNER TO minerva_admin;


-- ===================================
--  update_existence_handoverrelation
-- ===================================
-- Function to materialize (v)existence_HandoverRelation

CREATE OR REPLACE FUNCTION gis.update_existence_handoverrelation()
  RETURNS integer AS
$BODY$
DECLARE
  max_ts timestamp with time zone;
  result integer;
BEGIN
  SELECT max(timestamp) INTO max_ts FROM gis."existence_HandoverRelation";
  INSERT INTO gis."existence_HandoverRelation" SELECT * FROM gis."vexistence_HandoverRelation" WHERE timestamp > max_ts;

  SELECT count(*) INTO result FROM gis.handover_relation_existence;

  RETURN result;
END;
$BODY$ LANGUAGE plpgsql VOLATILE COST 1000;
ALTER FUNCTION gis.update_existence_handoverrelation() OWNER TO minerva_admin;


-- ===================================
--  update_handover_relation_existence
-- ===================================
-- Function to materialize (v)handover_relation_existence

CREATE OR REPLACE FUNCTION gis.update_handover_relation_existence()
  RETURNS integer AS
$BODY$
DECLARE
  result integer;
BEGIN
  DELETE FROM gis.handover_relation_existence;
  INSERT INTO gis.handover_relation_existence SELECT * FROM gis.vhandover_relation_existence;

  SELECT count(*) INTO result FROM gis.handover_relation_existence;

  RETURN result;
END;
$BODY$ LANGUAGE plpgsql VOLATILE COST 1000;
ALTER FUNCTION gis.update_handover_relation_existence() OWNER TO postgres;
