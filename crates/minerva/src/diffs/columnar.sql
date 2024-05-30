

ALTER TABLE "trend_directory"."trend_store" ADD COLUMN "columnar_period" interval NOT NULL DEFAULT '1d'::interval;


ALTER TABLE "trend_directory"."partition" ADD COLUMN "is_columnar" boolean NOT NULL DEFAULT false;


CREATE FUNCTION "trend_directory"."needs_columnar_store"(trend_directory.partition)
    RETURNS boolean
AS $$
SELECT not p.is_columnar and p.from + ts.columnar_period < now()
FROM trend_directory.partition p
  JOIN trend_directory.trend_store_part tsp ON p.trend_store_part_id = tsp.id
  JOIN trend_directory.trend_store ts ON tsp.trend_store_id = ts.id
WHERE p.id = $1.id;
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "trend_directory"."convert_to_columnar"(trend_directory.partition)
    RETURNS void
AS $$
SELECT alter_table_set_access_method(format('%I.%I', trend_directory.partition_schema(), $1.name)::regclass, 'columnar');
UPDATE trend_directory.partition SET is_columnar = 'true' WHERE id = $1.id;
$$ LANGUAGE sql VOLATILE;
