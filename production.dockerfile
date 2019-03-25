FROM postgres:11
MAINTAINER Hendrikx ITC

COPY docker-resources/usr/* /usr/
COPY docker-resources/init-minerva-db-production.sh /docker-entrypoint-initdb.d/docker-resources/init-minerva-db.sh
COPY /src /minerva

VOLUME /custom
