CREATE FUNCTION public.integer_to_array(value integer)
    RETURNS integer[]
AS $$
BEGIN
    RETURN ARRAY[value];
END;
$$ LANGUAGE plpgsql STABLE STRICT;


CREATE FUNCTION public.smallint_to_array(value smallint)
    RETURNS smallint[]
AS $$
BEGIN
    RETURN ARRAY[value];
END;
$$ LANGUAGE plpgsql STABLE STRICT;


-- Used to 'cast' from smallint to timestamp without timezone. This normally
-- isn't possible but we want to be able to switch. Implicitly, we just set all
-- values to NULL when converting a column from smallint to timestamp without
-- time zone.
CREATE FUNCTION public.smallint_to_timestamp_without_time_zone (smallint)
    RETURNS timestamp without time zone AS
$$
BEGIN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE STRICT;


-- Same 'cast' support for timestamp with time zone
CREATE FUNCTION public.smallint_to_timestamp_with_time_zone (smallint)
    RETURNS timestamp with time zone
AS $$
BEGIN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE STRICT;


CREATE FUNCTION public.column_names(namespace name, "table" name)
    RETURNS SETOF name
AS $$
    SELECT a.attname
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
    JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
    WHERE
        n.nspname = $1 AND
        c.relname = $2 AND
        a.attisdropped = false AND
        a.attnum > 0;
$$ LANGUAGE SQL STABLE;


CREATE FUNCTION public.fst(anyelement, anyelement)
    RETURNS anyelement
AS $$
    SELECT $1;
$$ LANGUAGE SQL IMMUTABLE STRICT;


CREATE FUNCTION public.snd(anyelement, anyelement)
    RETURNS anyelement
AS $$
    SELECT $2;
$$ LANGUAGE SQL IMMUTABLE STRICT;


CREATE FUNCTION public.safe_division(numerator anyelement, denominator anyelement)
    RETURNS anyelement
AS $$
SELECT CASE
    WHEN $2 = 0 THEN
        NULL
    ELSE
        $1 / $2
    END;
$$ LANGUAGE SQL IMMUTABLE;

ALTER FUNCTION safe_division(anyelement, anyelement)
    OWNER TO postgres;


CREATE FUNCTION public.add_array(anyarray, anyarray) RETURNS anyarray
AS $$
SELECT array_agg((arr1 + arr2)) FROM
(
    SELECT
        unnest($1[1:least(array_length($1,1), array_length($2,1))]) AS arr1,
        unnest($2[1:least(array_length($1,1), array_length($2,1))]) AS arr2
) AS foo;
$$ LANGUAGE SQL STABLE STRICT;


CREATE AGGREGATE sum_array(anyarray)
(
    sfunc = public.add_array,
    stype = anyarray
);


CREATE FUNCTION public.divide_array(anyarray, anyelement)
    RETURNS anyarray
AS $$
SELECT array_agg(arr / $2) FROM
(
    SELECT unnest($1) AS arr
) AS foo;
$$ LANGUAGE SQL STABLE STRICT;


CREATE FUNCTION public.divide_array(anyarray, anyarray)
    RETURNS anyarray
AS $$
SELECT array_agg(public.safe_division(arr1, arr2)) FROM
(
    SELECT
    unnest($1[1:least(array_length($1,1), array_length($2,1))]) AS arr1,
    unnest($2[1:least(array_length($1,1), array_length($2,1))]) AS arr2
) AS foo;
$$ LANGUAGE SQL STABLE STRICT;


CREATE FUNCTION public.array_sum(anyarray) RETURNS anyelement
AS $$
SELECT sum(t) FROM unnest($1) t;
$$ LANGUAGE SQL IMMUTABLE STRICT;


CREATE FUNCTION public.to_pdf(text)
    RETURNS int[]
AS $$
    SELECT array_agg(nullif(x, '')::int)
    FROM unnest(string_to_array($1, ',')) AS x;
$$ LANGUAGE SQL STABLE STRICT;


CREATE FUNCTION public.action(sql text)
    RETURNS void
AS $$
BEGIN
    EXECUTE sql;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION public.action(anyelement, sql text)
    RETURNS anyelement
AS $$
BEGIN
    EXECUTE sql;

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION public.action(anyelement, sql text[])
    RETURNS anyelement
AS $$
DECLARE
    statement text;
BEGIN
    FOREACH statement IN ARRAY sql LOOP
        EXECUTE statement;
    END LOOP;

    RETURN $1;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION public.table_exists(schema_name name, table_name name)
    RETURNS boolean
AS $$
    SELECT exists(
        SELECT 1
        FROM pg_class
        JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
        WHERE relname = $2 AND relkind = 'r' AND pg_namespace.nspname = $1
    );
$$ LANGUAGE sql STABLE;


CREATE FUNCTION public.raise_exception(message anyelement)
    RETURNS void
AS $$
BEGIN
    RAISE EXCEPTION '%', message;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION public.raise_info(message anyelement)
    RETURNS void
AS $$
BEGIN
    RAISE INFO '%', message;
END;
$$ LANGUAGE plpgsql VOLATILE;
