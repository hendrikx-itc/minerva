export MINERVA_DB_NAME=minerva
export PGDATABASE=$MINERVA_DB_NAME
export PGUSER=postgres
export ADD_PGTAB_EXTENSION=true
export PYTHONUNBUFFERED=1

create-minerva-database

# Make sure all requirements for sample data generation etc. are loaded.
pip3 install -r /instance/requirements.txt

if [[ ! -z "$LOAD_SAMPLE_DATA" ]]
then
    minerva initialize -i /instance --load-sample-data
else
    minerva initialize -i /instance
fi

