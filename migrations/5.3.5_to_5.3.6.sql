DO
$$
BEGIN
  IF NOT EXISTS(SELECT * FROM pg_roles WHERE rolname = 'postgres') THEN
    CREATE ROLE postgres
      SUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
  END IF;
END
$$;


GRANT postgres TO minerva_admin;

