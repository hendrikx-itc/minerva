CREATE FUNCTION trend_directory.changes_on_data_source_update()
    RETURNS TRIGGER
AS $$
BEGIN
    IF NEW.name <> OLD.name THEN
        UPDATE trend_directory.partition SET
            table_name = trend_directory.to_table_name(partition)
        FROM trend_directory.trend_store ts
        WHERE ts.data_source_id = NEW.id AND ts.id = partition.trend_store_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION trend_directory.cleanup_on_data_source_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    DELETE FROM trend_directory.trend_store WHERE data_source_id = OLD.id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION trend_directory.changes_on_trend_update()
    RETURNS TRIGGER
AS $$
DECLARE
    base_table_name text;
BEGIN
    IF NEW.name <> OLD.name THEN
        FOR base_table_name IN
            SELECT trend_directory.base_table_name(trend_store)
            FROM trend_directory.trend
            JOIN trend_directory.trend_store ON trend.trend_store_id = trend_store.id
            WHERE trend.id = NEW.id
        LOOP
            EXECUTE format('ALTER TABLE trend_directory.%I RENAME COLUMN %I TO %I', base_table_name, OLD.name, NEW.name);
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION trend_directory.drop_partition_table_on_delete()
    RETURNS TRIGGER
AS $$
DECLARE
    kind CHAR;
BEGIN
    SELECT INTO kind relkind
    FROM pg_class
    WHERE relname = trend_directory.table_name(OLD);

    IF kind = 'r' THEN
        EXECUTE format(
            'DROP TABLE IF EXISTS trend_directory.%I CASCADE',
            trend_directory.table_name(OLD)
        );
    ELSIF kind = 'v' THEN
        EXECUTE format(
            'DROP VIEW trend_directory.%I',
            trend_directory.table_name(OLD)
        );
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION trend_directory.update_modified_column()
    RETURNS TRIGGER
AS $$
BEGIN
    NEW.modified = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE FUNCTION trend_directory.cleanup_table_trend_store_on_delete()
    RETURNS TRIGGER
AS $$
DECLARE
    table_name text;
BEGIN

    EXECUTE format(
        'DROP TABLE IF EXISTS trend.%I CASCADE',
        trend_directory.base_table_name(OLD)
    );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION trend_directory.drop_view_on_delete()
    RETURNS TRIGGER
AS $$
BEGIN
    PERFORM trend_directory.drop_view(OLD);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
