BEGIN;

SELECT plan(6);

SELECT bag_eq('SELECT job FROM logging.job', ARRAY[]::logging.job[], 'there should be no jobs initially');

SELECT logging.start_job('{}'::jsonb);

SELECT results_eq('SELECT COUNT(*)::integer FROM logging.job', ARRAY[1], 'start_job should create a job');

SELECT bag_ne('SELECT started FROM logging.job', ARRAY[null]::timestamp[], 'start_job should create a started time');

SELECT bag_eq('SELECT finished FROM logging.job', ARRAY[null]::timestamp[], 'start_job should not create a finished time');

SELECT logging.end_job(id) FROM logging.job;

SELECT bag_ne('SELECT finished FROM logging.job', ARRAY[null]::timestamp[], 'end_job should create a finished time');

SELECT ok(job.started < job.finished, 'job start should be before job finish') FROM logging.job;

SELECT * FROM finish();
ROLLBACK;
