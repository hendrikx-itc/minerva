DO
$$
BEGIN
    IF NOT EXISTS(SELECT * FROM pg_roles WHERE rolname = 'minerva') THEN
        CREATE ROLE minerva
            NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
    END IF;
END
$$;

DO
$$
BEGIN
    IF NOT EXISTS(SELECT * FROM pg_roles WHERE rolname = 'minerva_writer') THEN
        CREATE ROLE minerva_writer
            NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
    END IF;
END
$$;

GRANT minerva TO minerva_writer;

DO
$$
BEGIN
    IF NOT EXISTS(SELECT * FROM pg_roles WHERE rolname = 'minerva_admin') THEN
        CREATE ROLE minerva_admin LOGIN
            NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
    END IF;
END
$$;

GRANT minerva TO minerva_admin;
GRANT minerva_writer TO minerva_admin;
