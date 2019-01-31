FROM postgres:9.4
MAINTAINER Hendrikx ITC

RUN apt-get update && apt-get install -y \
    make \
    patch \
    libpq-dev \
    postgresql-server-dev-9.4 \
    postgresql-9.4-postgis-2.5 \
    perl-modules

ADD https://github.com/hendrikx-itc/db-deps/archive/v0.8.0.tar.gz /db-deps.tar.gz
RUN mkdir /db-deps
RUN tar -xzvf /db-deps.tar.gz -C /db-deps --strip-components=1

ADD https://github.com/theory/pgtap/archive/master.tar.gz /pgtap.tar.gz
RUN mkdir /pgtap
RUN tar -xzvf /pgtap.tar.gz -C /pgtap --strip-components=1

RUN cd /pgtap && make && make install
RUN PERL_MM_USE_DEFAULT=1 cpan TAP::Parser::SourceHandler::pgTAP

COPY docker-resources/run-tests /usr/bin/
COPY docker-resources/create-minerva-database /usr/bin/
COPY docker-resources/drop-minerva-database /usr/bin/
COPY docker-resources/recreate-minerva-database /usr/bin/

ADD init-minerva-db.sh /docker-entrypoint-initdb.d/
