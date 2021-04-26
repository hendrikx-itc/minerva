FROM postgres:12
MAINTAINER Hendrikx ITC

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libpq-dev \
    libyaml-cpp-dev

COPY docker-resources/usr/bin/* /usr/bin/
COPY docker-resources/init-minerva-db-and-instance.sh /docker-entrypoint-initdb.d/
COPY src /minerva

RUN pip3 install minerva-etl

VOLUME /custom
VOLUME /instance
