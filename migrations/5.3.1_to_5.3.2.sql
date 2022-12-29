

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,3,2)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;


ALTER TABLE "trigger"."rule" ADD COLUMN "description" text;
