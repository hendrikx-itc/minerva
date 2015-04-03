CREATE CAST (notification_directory.notification_store AS text)
WITH FUNCTION notification_directory.to_char(notification_directory.notification_store);
