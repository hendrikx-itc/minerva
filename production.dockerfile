FROM postgres:9.6
MAINTAINER Hendrikx ITC

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libpq-dev make patch perl postgresql-server-dev-9.6 postgresql-9.6-postgis-2.3

ADD https://github.com/hendrikx-itc/db-deps/archive/v0.8.0.tar.gz /db-deps.tar.gz
RUN mkdir /db-deps
RUN tar -xzvf /db-deps.tar.gz -C /db-deps --strip-components=1

COPY docker-resources/create-minerva-prod-database /usr/bin/create-minerva-database
COPY docker-resources/drop-minerva-database /usr/bin/
COPY docker-resources/recreate-minerva-database /usr/bin/
COPY src /minerva

VOLUME /custom_scripts

ADD init-minerva-db.sh /docker-entrypoint-initdb.d/

