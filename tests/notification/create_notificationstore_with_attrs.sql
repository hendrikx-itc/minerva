BEGIN;

SELECT plan(2);

SELECT isa_ok(
	notification.create_notificationstore(
		'some_datasource_name',
		ARRAY[('NV_ALARM_ID', 'integer')]::notification.attr_def[]
	),
	'notification.notificationstore',
	'the result of create_notificationstore'
);

SELECT has_column(
	'notification'::name, 'some_datasource_name'::name, 'NV_ALARM_ID'::name,
	'notification store table has a custom attribute column NV_ALARM_ID'
);

SELECT * FROM finish();
ROLLBACK;
