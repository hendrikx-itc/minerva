export MINERVA_DB_NAME=minerva
export PGDATABASE=$MINERVA_DB_NAME

gosu postgres pg_ctl -w start

gosu postgres create-minerva-database

gosu postgres pg_ctl stop

