CREATE CAST (trend.trendstore AS text) WITH FUNCTION trend.to_char(trend.trendstore) AS IMPLICIT;

CREATE CAST (trend.view AS text) WITH FUNCTION trend.to_char(trend.view) AS IMPLICIT;
