FROM postgres:9.4
MAINTAINER Hendrikx ITC

RUN apt-get update

ADD https://github.com/hendrikx-itc/db-deps/archive/7cd7beb062093cff389eb6761fab84bab3f7e285.tar.gz /db-deps.tar.gz
RUN mkdir /db-deps
RUN tar -xzvf /db-deps.tar.gz -C /db-deps --strip-components=1

COPY docker-resources/create-minerva-database /usr/bin/
COPY docker-resources/drop-minerva-database /usr/bin/
COPY docker-resources/recreate-minerva-database /usr/bin/
COPY scripts /minerva

ADD init-minerva-db.sh /docker-entrypoint-initdb.d/
