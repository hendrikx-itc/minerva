FROM postgres:13
ENV LC_ALL C
MAINTAINER HENDRIKX-ITC

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
	make \
	patch \
	libpq-dev \
	postgresql-server-dev-13 \
	postgresql-contrib-13 \
	python3-pip \
	git \
	net-tools
RUN pip3 install git+https://github.com/hendrikx-itc/pg-db-tools.git

ADD https://github.com/theory/pgtap/archive/master.tar.gz /pgtap.tar.gz
RUN mkdir /pgtap
RUN tar -xzvf /pgtap.tar.gz -C /pgtap --strip-components=1
RUN cd /pgtap && make && make install

RUN PERL_MM_USE_DEFAULT=1 cpan TAP::Parser::SourceHandler::pgTAP

COPY bin/ /usr/bin/

COPY src /src
COPY tests /tests

RUN mkdir /test_results -p
VOLUME /test_results

COPY docker-resources/init-minerva-db-develop.sh /docker-entrypoint-initdb.d/
COPY docker-resources/usr/bin/create-minerva-database /usr/bin/
COPY run-tests.sh /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/run-tests.sh
