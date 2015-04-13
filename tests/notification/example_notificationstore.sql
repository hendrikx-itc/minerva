BEGIN;

SELECT plan(3);

SELECT isa_ok(
	notification.create_notificationsetstore(
		'ticket'::name,
		notification.create_notificationstore('state_changes')
	),
	'notification.notificationsetstore',
	'the result of create_notificationsetstore'
);

SELECT has_table(
	'notification'::name, 'ticket'::name,
	'table with name of notificationsetstore should exist'
);

SELECT has_table(
	'notification'::name, 'ticket_link'::name,
	'link table for notificationsetstore should exist'
);

SELECT * FROM finish();
ROLLBACK;
