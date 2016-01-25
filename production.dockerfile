FROM postgres:9.4
MAINTAINER Hendrikx ITC

ADD https://github.com/hendrikx-itc/db-deps/archive/274f0f3300077a859426912337ffc04983663ff3.tar.gz /db-deps.tar.gz
RUN mkdir /db-deps
RUN tar -xzvf /db-deps.tar.gz -C /db-deps --strip-components=1
ADD src /minerva

ADD init-minerva-db.sh /docker-entrypoint-initdb.d/
