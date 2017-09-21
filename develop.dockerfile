FROM postgres:9.6
MAINTAINER Hendrikx ITC

RUN apt-get update
RUN apt-get install -y make patch libpq-dev postgresql-server-dev-9.6

ADD https://github.com/hendrikx-itc/db-deps/archive/7cd7beb062093cff389eb6761fab84bab3f7e285.tar.gz /db-deps.tar.gz
RUN mkdir /db-deps
RUN tar -xzvf /db-deps.tar.gz -C /db-deps --strip-components=1

ADD https://github.com/theory/pgtap/archive/master.tar.gz /pgtap.tar.gz
RUN mkdir /pgtap
RUN tar -xzvf /pgtap.tar.gz -C /pgtap --strip-components=1

RUN cd /pgtap && make && make install
RUN PERL_MM_USE_DEFAULT=1 cpan TAP::Parser::SourceHandler::pgTAP

COPY docker-resources/ /
