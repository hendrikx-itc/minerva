CREATE FUNCTION dimension.update_month()
    RETURNS void
AS $$
    TRUNCATE dimension.month;
    INSERT INTO dimension.month SELECT
        timestamp,
        timestamp - '1 month'::interval,
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('month', now() - '1 year'::interval),
            date_trunc('month', now() + '1 year'::interval),
            '1 month'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE SQL;


CREATE FUNCTION dimension.update_week()
    RETURNS void
AS $$
    TRUNCATE dimension.week;
    INSERT INTO dimension.week SELECT
        timestamp,
        timestamp - '1 week'::interval,
        timestamp,
        date_part('isoyear'::text, timestamp - '7 days'::interval),
        date_part('week'::text, timestamp - '7 days'::interval)
    FROM (
        SELECT generate_series(
            date_trunc('week', now() - '1 year'::interval),
            date_trunc('week', now() + '1 year'::interval),
            '1 week'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE SQL;


CREATE FUNCTION dimension.update_day()
    RETURNS void
AS $$
    TRUNCATE dimension.day;
    INSERT INTO dimension.day SELECT
        timestamp,
        timestamp - '1 day'::interval,
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('day', now()) - '1 year'::interval,
            date_trunc('day', now()) + '1 year'::interval,
            '1 day'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE SQL;


CREATE FUNCTION dimension.update_hour()
    RETURNS void
AS $$
    TRUNCATE dimension.hour;
    INSERT INTO dimension.hour SELECT
        timestamp,
        timestamp - '1 hour'::interval,
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('hour', now()) - '1 year'::interval,
            date_trunc('hour', now()) + '1 year'::interval,
            '1 hour'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE SQL;


CREATE FUNCTION dimension.update_quarter()
    RETURNS void
AS $$
    TRUNCATE dimension.quarter;
    INSERT INTO dimension.quarter SELECT
        timestamp,
        timestamp - '15 minute'::interval,
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('hour', now()) - '1 year'::interval,
            date_trunc('hour', now()) + '1 year'::interval,
            '15 minute'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE SQL;


CREATE FUNCTION dimension.update_5m()
    RETURNS void
AS $$
    TRUNCATE dimension."5m";
    INSERT INTO dimension."5m" SELECT
        timestamp,
        timestamp - '5 minute'::interval,
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('hour', now()) - '1 year'::interval,
            date_trunc('hour', now()) + '1 year'::interval,
            '5 minute'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE SQL;

CREATE FUNCTION dimension.update_four_consec_qtr()
    RETURNS void
AS $$
    TRUNCATE dimension."four_consec_qtr";
    INSERT INTO dimension."four_consec_qtr" SELECT
        timestamp,
        timestamp - '1 hour'::interval,
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('hour', now()) - '1 year'::interval,
            date_trunc('hour', now()) + '1 year'::interval,
            '15 minute'::interval) AS timestamp
    ) timestamps;
$$ LANGUAGE SQL;


CREATE FUNCTION dimension.update_month_15m()
    RETURNS void
AS $$
    TRUNCATE dimension.month_15m;
    INSERT INTO dimension.month_15m SELECT
        date_trunc('month', timestamp_15m) as timestamp,
        timestamp_15m
    FROM 
        generate_series(
            date_trunc('month', now() - '1 year'::interval),
            date_trunc('month', now() + '1 year'::interval),
            '15 minutes'::interval
        ) AS timestamps(timestamp_15m);
$$ LANGUAGE SQL;


CREATE FUNCTION dimension.update_week_15m()
    RETURNS void
AS $$
    TRUNCATE dimension.week_15m;
    INSERT INTO dimension.week_15m SELECT
        date_trunc('week', timestamp_15m) as timestamp,
        timestamp_15m
    FROM 
        generate_series(
            date_trunc('week', now() - '1 year'::interval),
            date_trunc('week', now() + '1 year'::interval),
            '15 minutes'::interval
        ) AS timestamps(timestamp_15m);
$$ LANGUAGE SQL;


CREATE FUNCTION dimension.update_day_15m()
    RETURNS void
AS $$
    TRUNCATE dimension.day_15m;
    INSERT INTO dimension.day_15m SELECT
        date_trunc('day', timestamp),
        timestamp
    FROM (
        SELECT generate_series(
            date_trunc('hour', now()) - '1 year'::interval,
            date_trunc('hour', now()) + '1 year'::interval,
            '15 minute'::interval
        ) AS timestamp
    ) timestamps;
$$ LANGUAGE SQL;
