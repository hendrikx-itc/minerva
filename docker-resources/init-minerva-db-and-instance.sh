export MINERVA_DB_NAME=minerva
export PGDATABASE=$MINERVA_DB_NAME
export PGUSER=postgres
export ADD_PGTAB_EXTENSION=true
export PYTHONUNBUFFERED=1

create-minerva-database

minerva initialize -i /instance
