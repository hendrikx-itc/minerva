FROM postgres:12
MAINTAINER Hendrikx ITC

RUN apt update && apt install -y \
    git \
    python3 \
    python3-pip \
    libpq-dev \
    netcat \
    libyaml-cpp-dev

RUN pip3 install pyyaml

COPY docker-resources/usr/bin/* /usr/bin/
COPY docker-resources/init-minerva-db-develop.sh /docker-entrypoint-initdb.d/
COPY src /minerva

RUN git clone https://github.com/hendrikx-itc/python-minerva-etl.git
RUN cd python-minerva-etl && python3 setup.py install

VOLUME /custom