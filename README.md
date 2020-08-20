# Minerva ETL

This repository contains the PostgreSQL based database schema for the Minerva ETL platform.

## Development

Developing on and with Minerva is easy using development Docker containers and
the commands provided in this repository.

### Prerequisites

- [Docker](https://www.docker.com) (incl. [Docker Compose](https://docs.docker.com/compose/install/)) *required
- PostgreSQL client `psql` *required
- Docker image `hendrikxitc/minerva`

## Initialize environment without Docker

Initialize the environment so that commands are available in the search path:

```bash
source bin/activate
```

## Start Minerva database without Docker image

Now a Minerva database can be started in a Docker container using:

```bash
db up
```

This will start the container in the foreground and all logs will be sent to
stdout. You can press Ctrl+C to stop the container.


To start the container in the background, use the `-d` option:

```bash
db up -d
```

Now you can use the `stop` command to stop the container that is running in the background:

```bash
db stop
```

## Start Minerva database with Docker image

```Docker
docker pull hendrikxitc/minerva:latest
```

Now start the container as follow:

```Docker
docker run --name minerva50db \
-e POSTGRES_HOST_AUTH_METHOD=trust \
-p 127.0.0.1:2345:5432 hendrikxitc/minerva
```

Validate if your intance is working.

```Postgres
psql -U postgres -h 127.0.0.1 -p 2345 minerva
```
