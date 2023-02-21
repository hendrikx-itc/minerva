FROM citusdata/citus:10.2-pg12
MAINTAINER Hendrikx ITC

RUN apt-get update && apt-get install -y python3-pip libpq-dev
RUN pip3 install minerva-etl

COPY docker-resources/usr/bin/* /usr/bin/
COPY docker-resources/init-minerva-db-production.sh /docker-entrypoint-initdb.d/init-minerva-db.sh
COPY /src /src

VOLUME /custom
