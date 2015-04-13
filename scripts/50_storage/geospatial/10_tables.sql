--=============
-- Schema: gis
--=============

CREATE SCHEMA gis AUTHORIZATION minerva_admin;
GRANT ALL ON SCHEMA gis TO minerva_admin;
GRANT USAGE ON SCHEMA gis TO minerva;
GRANT ALL ON SCHEMA gis TO minerva_writer;


-- ===================
--  extension Postgis
-- ===================

CREATE EXTENSION IF NOT EXISTS postgis;
GRANT SELECT ON public.geometry_columns TO PUBLIC;
GRANT SELECT ON public.spatial_ref_sys TO PUBLIC;


-- =======================
--  gis.Cell and gis.Site
-- =======================
-- Base tables for GIS with position (postgis geometry) information and
--  information to visualize on a GIS (azimuth, celltype, etc)

-- Create gis.cell tables
CREATE TABLE gis.cell (
    entity_id integer NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    hash character varying,
    azimuth integer NOT NULL,
    "type" character varying,
    CONSTRAINT cell_pkey PRIMARY KEY (entity_id, timestamp)
) WITHOUT OIDS;

ALTER TABLE gis.cell OWNER TO minerva_admin;
GRANT SELECT ON TABLE gis.cell TO minerva;
GRANT INSERT, DELETE, UPDATE ON TABLE gis.cell TO minerva_writer;

CREATE TABLE gis.cell_curr (
    CONSTRAINT cell_curr_pkey PRIMARY KEY (entity_id)
) INHERITS (gis.cell);

ALTER TABLE gis.cell_curr OWNER TO minerva_admin;
GRANT SELECT ON TABLE gis.cell_curr TO minerva;
GRANT INSERT, DELETE, UPDATE ON TABLE gis.cell_curr TO minerva_writer;

-- Create gis.site tables
CREATE TABLE gis.site (
    entity_id integer NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    hash character varying,
    CONSTRAINT site_pkey PRIMARY KEY (entity_id, timestamp)
)  WITH ( OIDS=FALSE );
SELECT AddGeometryColumn('minerva', 'gis', 'site', 'position', 900913, 'POINT', 2);
ALTER TABLE gis.site OWNER TO minerva_admin;
GRANT SELECT ON TABLE gis.site TO minerva;
GRANT INSERT, DELETE, UPDATE ON TABLE gis.site TO minerva_writer;

CREATE TABLE gis.site_curr (
    CONSTRAINT site_curr_pkey PRIMARY KEY (entity_id)
) INHERITS (gis.site);
ALTER TABLE gis.site_curr OWNER TO minerva_admin;
GRANT SELECT ON TABLE gis.site_curr TO minerva;
GRANT INSERT, DELETE, UPDATE ON TABLE gis.site_curr TO minerva_writer;


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

CREATE TABLE gis."existence_HandoverRelation"
(
  "timestamp" timestamp with time zone NOT NULL,
  "exists" boolean NOT NULL,
  entity_id integer NOT NULL,
  entitytype_id integer NOT NULL,
  CONSTRAINT existence_pkey PRIMARY KEY (entity_id, "timestamp")
) WITH ( OIDS=FALSE );
ALTER TABLE gis."existence_HandoverRelation" OWNER TO minerva_admin;
GRANT ALL ON TABLE gis."existence_HandoverRelation" TO minerva_admin;
GRANT SELECT ON TABLE gis."existence_HandoverRelation" TO minerva;
GRANT UPDATE, INSERT, DELETE ON TABLE gis."existence_HandoverRelation" TO minerva_writer;

CREATE INDEX ix_gis_existence_timestamp ON gis."existence_HandoverRelation" USING btree ("timestamp");


-- ============================
--  handover_relation_existence
-- ============================
-- Handover Relation records with existence information.

CREATE TABLE gis.handover_relation_existence
(
  entity_id integer,
  source_id integer,
  handover_id integer,
  target_id integer,
  target_name character varying,
  source_name character varying,
  tag_name character varying,
  direction text,
  existence text[],
  handover_tags character varying[]
) WITH ( OIDS=FALSE );
ALTER TABLE gis.handover_relation_existence OWNER TO minerva_admin;
GRANT ALL ON TABLE gis.handover_relation_existence TO minerva_admin;
GRANT SELECT ON TABLE gis.handover_relation_existence TO minerva;
GRANT UPDATE, INSERT, DELETE ON TABLE gis.handover_relation_existence TO minerva_writer;

CREATE INDEX handover_relation_existence_entity_id_idx ON gis.handover_relation_existence USING btree (entity_id);

