CREATE CAST (trend_directory.trend_store AS text) WITH FUNCTION trend_directory.to_char(trend_directory.trend_store) AS IMPLICIT;

CREATE CAST (trend_directory.table_trend_store AS text) WITH FUNCTION trend_directory.to_char(trend_directory.table_trend_store) AS IMPLICIT;

CREATE CAST (trend_directory.view_trend_store AS text) WITH FUNCTION trend_directory.to_char(trend_directory.view_trend_store) AS IMPLICIT;
