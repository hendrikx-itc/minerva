BEGIN;

SELECT plan(5);

SELECT isa_ok(
	notification.create_notificationstore('some_datasource_name'),
	'notification.notificationstore',
	'the result of create_notificationstore'
);

SELECT has_table(
	'notification'::name, 'some_datasource_name'::name,
	'table with name of datasource should exist'
);

SELECT has_column(
	'notification'::name, 'some_datasource_name'::name, 'id'::name,
	'notification store table has a column id'
);

SELECT has_column(
	'notification'::name, 'some_datasource_name'::name, 'entity_id'::name,
	'notification store table has a column entity_id'
);

SELECT has_column(
	'notification'::name, 'some_datasource_name'::name, 'timestamp'::name,
	'notification store table has a column timestamp'
);

SELECT * FROM finish();
ROLLBACK;
