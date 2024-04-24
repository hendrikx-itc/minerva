CREATE TABLE "notification_directory"."last_notification"
(
  "name" text NOT NULL,
  "notification_store" text,
  "last_notification" integer NOT NULL,
  PRIMARY KEY (name, notification_store)
);

COMMENT ON TABLE "notification_directory"."last_notification" IS 'Specifies the id of the last notification seen by a client of
the notification service';



ALTER TABLE "notification_directory"."notification_store" ADD COLUMN "entity_type_id" integer;


CREATE FUNCTION "notification_directory"."get_last_notification"("client" text, "notification_store" text)
    RETURNS integer
AS $$
DECLARE
  result integer;
BEGIN
  SELECT ln.last_notification FROM notification_directory.last_notification ln WHERE ln.name = $1 AND ln.notification_store = $2 INTO result;
  RETURN COALESCE(result, -1);
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "notification_directory"."get_last_notification"("client" text)
    RETURNS integer
AS $$
SELECT notification_directory.get_last_notification($1, $1);
$$ LANGUAGE sql STABLE;


CREATE FUNCTION "notification_directory"."set_last_notification"("client" text, "notification_store" text, "value" integer)
    RETURNS void
AS $$
INSERT INTO notification_directory.last_notification (name, notification_store, last_notification)
  VALUES ($1, $2, $3) ON CONFLICT DO UPDATE;
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."set_last_notification"("client" text, "value" integer)
    RETURNS void
AS $$
SELECT notification_directory.set_last_notification($1, $1, $2);
$$ LANGUAGE sql VOLATILE;


CREATE FUNCTION "notification_directory"."get_next_notifications"("notification_store" text, "last_notification_seen" integer, "max_notifications" integer)
    RETURNS SETOF notification.generic_notification
AS $$
DECLARE
  entity_type text;
BEGIN
  SELECT et.name FROM notification_directory.notification_store ns
    JOIN directory.data_source ds ON ds.id = ns.data_source_id
    JOIN directory.entity_type et ON et.id = ns.entity_type_id
    WHERE ds.name = $1
    INTO entity_type;
  RETURN QUERY EXECUTE(FORMAT(
    'SELECT n.id as id, timestamp, r.name::text as rule, e.name::text as entity, weight, details, data '
    'FROM notification.%I n '
    'JOIN trigger.rule r ON n.rule_id = r.id '
    'JOIN entity.%I e on n.entity_id = e.id '
    'WHERE n.id > %s ORDER BY n.id  LIMIT %s',
    $1,
    entity_type,
    $2,
    $3
  ));
END;
$$ LANGUAGE plpgsql STABLE;


CREATE FUNCTION "notification_directory"."get_last_notifications"("notification_store" text, "max_notifications" integer)
    RETURNS SETOF notification.generic_notification
AS $$
DECLARE
  entity_type text;
BEGIN
  SELECT et.name FROM notification_directory.notification_store ns
    JOIN directory.data_source ds ON ds.id = ns.data_source_id
    JOIN directory.entity_type et ON et.id = ns.entity_type_id
    WHERE ds.name = $1
    INTO entity_type;
  RETURN QUERY EXECUTE(FORMAT(
    'SELECT n.id as id, timestamp, r.name::text as rule, e.name::text as entity, weight, details, data '
    'FROM notification.%I n '
    'JOIN trigger.rule r ON n.rule_id = r.id '
    'JOIN entity.%I e on n.entity_id = e.id '
    'ORDER BY n.id DESC LIMIT %s',
    $1,
    entity_type,
    $2
  ));
END;
$$ LANGUAGE plpgsql STABLE;
