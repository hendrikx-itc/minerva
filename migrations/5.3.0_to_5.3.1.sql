

DROP FUNCTION "trend_directory"."define_materialization"(integer, interval, interval, interval);

ALTER TABLE "trend_directory"."materialization" ADD COLUMN "description" jsonb NOT NULL DEFAULT '{}';


CREATE FUNCTION "trend_directory"."define_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "description" jsonb)
    RETURNS trend_directory.materialization
AS $$
INSERT INTO trend_directory.materialization(dst_trend_store_part_id, processing_delay, stability_delay, reprocessing_period, description)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT DO NOTHING
RETURNING *;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."define_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "description" jsonb) IS 'Define a materialization';


CREATE FUNCTION "trend_directory"."define_view_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_view" regclass, "description" jsonb)
    RETURNS trend_directory.view_materialization
AS $$
INSERT INTO trend_directory.view_materialization(materialization_id, src_view)
VALUES((trend_directory.define_materialization($1, $2, $3, $4, $6)).id, $5) RETURNING *;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."define_view_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_view" regclass, "description" jsonb) IS 'Define a materialization that uses a view as source';


CREATE FUNCTION "trend_directory"."define_function_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_function" regproc, "description" jsonb)
    RETURNS trend_directory.function_materialization
AS $$
INSERT INTO trend_directory.function_materialization(materialization_id, src_function)
VALUES((trend_directory.define_materialization($1, $2, $3, $4, $6)).id, $5::text)
ON CONFLICT DO NOTHING
RETURNING *;
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."define_function_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_function" regproc, "description" jsonb) IS 'Define a materialization that uses a function as source';


CREATE OR REPLACE FUNCTION "trend_directory"."define_view_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_view" regclass)
    RETURNS trend_directory.view_materialization
AS $$
SELECT trend_directory.define_view_materialization($1, $2, $3, $4, $5, NULL);
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."define_view_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_view" regclass) IS 'Define a materialization that uses a view as source';


CREATE OR REPLACE FUNCTION "trend_directory"."define_function_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_function" regproc)
    RETURNS trend_directory.function_materialization
AS $$
SELECT trend_directory.define_function_materialization($1, $2, $3, $4, $5, NULL)
$$ LANGUAGE sql VOLATILE;

COMMENT ON FUNCTION "trend_directory"."define_function_materialization"("dst_trend_store_part_id" integer, "processing_delay" interval, "stability_delay" interval, "reprocessing_period" interval, "src_function" regproc) IS 'Define a materialization that uses a function as source';
