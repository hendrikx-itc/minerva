CREATE CAST (attribute_directory.attributestore AS text)
WITH FUNCTION attribute_directory.to_char(attribute_directory.attributestore);

CREATE CAST (attribute_directory.sampled_view_materialization AS text)
WITH FUNCTION attribute_directory.to_char(attribute_directory.sampled_view_materialization);

