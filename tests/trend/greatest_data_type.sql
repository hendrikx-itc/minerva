BEGIN;

SELECT plan(9);

SELECT is(trend_directory.greatest_data_type('smallint','integer'), 'integer');
SELECT is(trend_directory.greatest_data_type('bigint','integer'), 'bigint');
SELECT is(trend_directory.greatest_data_type('bigint','double precision'), 'double precision');
SELECT is(trend_directory.greatest_data_type('numeric','smallint[]'), 'smallint[]');
SELECT is(trend_directory.greatest_data_type('smallint[]','integer[]'), 'integer[]'); 
SELECT is(trend_directory.greatest_data_type('integer[]','text[]'), 'text[]');
SELECT is(trend_directory.greatest_data_type('text','text[]'), 'text');
SELECT is(trend_directory.greatest_data_type('integer','integer[]'), 'integer[]');
SELECT throws_ok($$SELECT trend_directory.greatest_data_type('integer','elephant')$$, 'Unsupported data type: elephant');


SELECT * FROM finish();
ROLLBACK;

