CREATE CAST (integer AS integer[])
    WITH FUNCTION integer_to_array(integer);


CREATE CAST (smallint AS smallint[])
    WITH FUNCTION smallint_to_array(smallint);


CREATE CAST (smallint as timestamp without time zone)
    WITH FUNCTION smallint_to_timestamp_without_time_zone (smallint);


CREATE CAST (smallint as timestamp with time zone)
    WITH FUNCTION smallint_to_timestamp_with_time_zone (smallint);
