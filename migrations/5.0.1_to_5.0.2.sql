

CREATE OR REPLACE FUNCTION "system"."version"()
    RETURNS system.version_tuple
AS $$
SELECT (5,0,2)::system.version_tuple;
$$ LANGUAGE sql IMMUTABLE;
