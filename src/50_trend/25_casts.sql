CREATE CAST (trend_directory.trend_store_part AS text) WITH FUNCTION trend_directory.to_char(trend_directory.trend_store_part) AS IMPLICIT;

CREATE CAST (trend_directory.table_trend_store_part AS text) WITH FUNCTION trend_directory.to_char(trend_directory.table_trend_store_part) AS IMPLICIT;

CREATE CAST (trend_directory.table_trend_store_part AS name) WITH FUNCTION trend_directory.base_table_name(trend_directory.table_trend_store_part) AS IMPLICIT;

CREATE CAST (trend_directory.view_trend_store_part AS text) WITH FUNCTION trend_directory.to_char(trend_directory.view_trend_store_part) AS IMPLICIT;

CREATE CAST (trend_directory.view_trend_store_part AS name) WITH FUNCTION trend_directory.view_name(trend_directory.view_trend_store_part) AS IMPLICIT;

CREATE CAST (trend_directory.materialization AS text) WITH FUNCTION trend_directory.to_char(trend_directory.materialization);

