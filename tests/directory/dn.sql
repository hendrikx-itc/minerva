BEGIN;

SELECT plan(5);

SELECT is(directory.dn_part_to_string(
    ARRAY['Network','local']::directory.dn_part
    ), 'Network=local', 'Array can be interpreted as dn_part');

SELECT is(directory.dn_part_to_string(
    directory.split_raw_part('Operator=company')), 'Operator=company',
    'dn_part can be created from string');

SELECT is(directory.explode_dn('Network=local,Switch=main'),
    ARRAY[
        ARRAY['Network','local']::directory.dn_part,
        ARRAY['Switch','main']::directory.dn_part
    ],
    'dn can be created by exploding');
    
SELECT is(directory.glue_dn(directory.explode_dn('Network=local,Switch=main')),
    'Network=local,Switch=main','glueing dn is reverse of exploding');

SELECT is(directory.last_dn_part(directory.explode_dn('Network=local,Switch=main')),
    ARRAY['Switch','main']::directory.dn_part);

SELECT * FROM finish();
ROLLBACK;
