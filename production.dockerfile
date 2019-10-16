FROM postgres:12
MAINTAINER Hendrikx ITC

RUN apt-get update && apt-get install -y python3-pip
RUN pip3 install minerva-etl

COPY docker-resources/usr/bin/* /usr/bin/
COPY docker-resources/init-minerva-db-production.sh /docker-entrypoint-initdb.d/init-minerva-db.sh
COPY /src /minerva

VOLUME /custom
