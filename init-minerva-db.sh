export MINERVA_DB_NAME=minerva
export PGDATABASE=$MINERVA_DB_NAME

gosu postgres create-minerva-database

echo 'minerva.trigger_mark_modified = on' >> /var/lib/postgresql/data/postgresql.conf
echo "minerva.trigger_entity_tag_denorm_update = on" >> /var/lib/postgresql/data/postgresql.conf
