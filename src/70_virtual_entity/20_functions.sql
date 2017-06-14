CREATE OR REPLACE FUNCTION virtual_entity.update(name name)
	RETURNS integer
AS $$
DECLARE
	result integer;
BEGIN
	EXECUTE format('SELECT count(directory.dn_to_entity(v.dn)) FROM virtual_entity.%I v LEFT JOIN directory.entity ON entity.dn = v.dn WHERE entity.dn IS NULL', name) INTO result;

	RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;
