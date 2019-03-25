FROM postgres:11
MAINTAINER Hendrikx ITC

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  libpq-dev \
  make \
  patch \
  perl \
  postgresql-server-dev-11

ADD https://github.com/hendrikx-itc/db-deps/archive/274f0f3300077a859426912337ffc04983663ff3.tar.gz /db-deps.tar.gz
RUN mkdir /db-deps
RUN tar -xzvf /db-deps.tar.gz -C /db-deps --strip-components=1

COPY docker-resources/usr/* /usr/
COPY docker-resources/init-minerva-db-production.sh /docker-entrypoint-initdb.d/
COPY /src /minerva

VOLUME /custom
