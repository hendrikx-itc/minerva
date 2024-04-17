# Minerva Notification Event Service

We want to be able to have a function to poll trigger notification events
from Minerva by TripAiku or other services. Here we create a design for this
service.

## Polling method - request function

The poller should be able to request the notifications after the ones that
they already have. To do so, the service specifies the last notification
that it has received.

There are two functions to be created:
notification\_directory.get\_notifications(notification\_store\_id, signifier, 
number) asks for the next at most _number_ notifications, and 
notification\_directory.get\_notifications(notification\_store\_id, signifier) 
does the same with a default _number_. Signifier here is the id of the last 
message that has been received.

There also has to be a possibility to receive the last messages, to start
the receipt of messages from a new entity. This is done with a special 
function get\_last\_notifications(number), which receives the last _number_
messages.

## Return data

The function returns a list of notification objects, where
the notification object has the following components:
* id <integer>: the id of the notification
* timestamp <timestamp>: the timestamp to which the notification applies
* rule <string>: the name of the rule that triggered the notification
* entity <string>: the name of the entity to which the notification applies
* details <string>: the details field of the notification
* data <object>: the data field of the notification

This is a new type which I'll call notification.notification_description

## Notification-entity connection

To be able to get this data, we need to have the entity type available for a
notification, as without that we cannot get the name of the entity. To do so,
a column is added to the notification with the entity\_type\_id.

## Functions

notification\_directory.get\_notifications(notification\_store\_id, signifier, 
number) asks for the next at most _number_ notifications, and returns them
as notification.notification_description objects.


This way we get a function (untested):
```
CREATE FUNCTION notification_directory."get_notifications(notification_store_id integer, signifier integer, 
number integer)
  RETURNS SETOF notification.notification_description
AS $$
DECLARE
  entity_type text,
  notification_store text;
  result SETOF notification.notification_description;
BEGIN
  SELECT e.name FROM notification_directory.notification_store ns JOIN directory.entity e ON e.id = ns.entity_type_id WHERE ns.id = $1 INTO entity_type;
  SELECT notification_directory.table_name(ns) FROM notification_directory.notification_store WHERE ns.id = $1 INTO notification_store,
  RETURN QUERY EXECUTE FORMAT(
    'SELECT n.id, n.timestamp, r.name, e.name, n.details, n.data '
    'FROM notification.%I n '
    'JOIN entity.%I e ON n.entity_id = e.id '
    'JOIN trigger.rule r ON n.rule_id = r.id '
    'WHERE ns.id > %s '
    'ORDER BY ns.id LIMIT %s',
    notification_store,
    entity_type,
    $2,
    $3
  );
END;
$$ LANGUAGE plpgsql STABLE
```

The application can then easily turn this into JSON.

## Keeping track

To keep track of the last message that has been received by a service,
a table is to be created where the name of the service and the last message
received are saved. I propose to name this table 
notification\_directory.receiving\_application with columns name,
notification\_store\_id and last\_notification. Two functions are of course 
needed: notification\_directory.get\_last\_notification\_id(name, 
notification\_store\_id) and 
notification\_directory.set\_last\_notification\_id(name, 
notification\_store\_id, number). notification\_id may be None, so that
services can choose themselves whether they use this information or not.
