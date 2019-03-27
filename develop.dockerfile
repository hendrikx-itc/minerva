FROM postgres:11.0
MAINTAINER Hendrikx ITC

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  libpq-dev \
  make \
  patch \
  perl \
  postgresql-server-dev-11

ADD https://github.com/theory/pgtap/archive/master.tar.gz /pgtap.tar.gz
RUN mkdir /pgtap
RUN tar -xzvf /pgtap.tar.gz -C /pgtap --strip-components=1

RUN cd /pgtap && make && make install
RUN PERL_MM_USE_DEFAULT=1 cpan TAP::Parser::SourceHandler::pgTAP

COPY docker-resources/usr/bin/* /usr/bin/
COPY docker-resources/init-minerva-db-develop.sh /docker-entrypoint-initdb.d/
COPY src /src

VOLUME /custom