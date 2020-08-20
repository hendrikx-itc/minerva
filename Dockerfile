FROM postgres:12
MAINTAINER Hendrikx ITC

COPY docker-resources/usr/bin/* /usr/bin/
COPY docker-resources/init-minerva-db-develop.sh /docker-entrypoint-initdb.d/
COPY src /minerva

VOLUME /custom
