export MINERVA_DB_NAME=minerva
export PGDATABASE=$MINERVA_DB_NAME
export PGUSER=postgres
export ADD_PGTAB_EXTENSION=true

create-minerva-database
minerva initialize
