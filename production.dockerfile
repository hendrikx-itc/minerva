FROM postgres:10
MAINTAINER Hendrikx ITC

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  libpq-dev \
  make \
  patch \
  perl \
  postgresql-server-dev-10

ADD https://github.com/hendrikx-itc/db-deps/archive/274f0f3300077a859426912337ffc04983663ff3.tar.gz /db-deps.tar.gz
RUN mkdir /db-deps
RUN tar -xzvf /db-deps.tar.gz -C /db-deps --strip-components=1

ADD https://github.com/theory/pgtap/archive/master.tar.gz /pgtap.tar.gz
RUN mkdir /pgtap
RUN tar -xzvf /pgtap.tar.gz -C /pgtap --strip-components=1

RUN cd /pgtap && make && make install
RUN PERL_MM_USE_DEFAULT=1 cpan TAP::Parser::SourceHandler::pgTAP

COPY docker-resources/ /
COPY /src /minerva
