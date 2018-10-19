FROM postgres:10
ENV LC_ALL C
MAINTAINER HENDRIKX-ITC

RUN apt-get update && apt-get upgrade -y && apt-get install -y make patch libpq-dev postgresql-server-dev-10 postgresql-contrib-10 postgis postgresql-10-postgis-2.3 python3-pip git net-tools
RUN pip3 install git+https://github.com/hendrikx-itc/pg-db-tools.git

ADD https://github.com/theory/pgtap/archive/master.tar.gz /pgtap.tar.gz
RUN mkdir /pgtap
RUN tar -xzvf /pgtap.tar.gz -C /pgtap --strip-components=1
RUN cd /pgtap && make && make install

COPY bin/ /usr/bin/

RUN mkdir /mimir -p

COPY src /src
COPY tests /tests

RUN mkdir /test_results -p
VOLUME /test_results

RUN PERL_MM_USE_DEFAULT=1 cpan TAP::Parser::SourceHandler::pgTAP

COPY run-tests /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/run-tests
