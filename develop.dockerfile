FROM timescale/timescaledb:1.3.0-pg11
MAINTAINER Hendrikx ITC

COPY docker-resources/usr/bin/* /usr/bin/
COPY docker-resources/init-minerva-db-develop.sh /docker-entrypoint-initdb.d/
COPY src /src

VOLUME /custom
