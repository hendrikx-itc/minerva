export MINERVA_DB_NAME=minerva
export PGDATABASE=$MINERVA_DB_NAME

create-minerva-database

echo 'minerva.trigger_mark_modified = on' >> /var/lib/postgresql/data/postgresql.conf
