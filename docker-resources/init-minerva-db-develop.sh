export MINERVA_DB_NAME=minerva
export PGDATABASE=$MINERVA_DB_NAME
export ADD_PGTAB_EXTENSION=true

echo "shared_preload_libraries = 'timescaledb'" >> /var/lib/postgresql/data/postgresql.conf

create-minerva-database
