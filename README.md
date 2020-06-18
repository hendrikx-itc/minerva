# Minerva ETL

This repository contains the PostgreSQL based database schema for the Minerva ETL platform.

## Development

Developing on and with Minerva is easy using development Docker containers and
the commands provided in this repository.

### Prerequisites

 - [Docker](https://www.docker.com) (incl. [Docker Compose](https://docs.docker.com/compose/install/)
 - PostgreSQL client `psql`

### Initialize environment

Initialize the environment so that commands are available in the search path:

```bash
source bin/activate
```

### Start container with Minerva database

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

### Connect to Minerva database

To connect to the Minerva database and look around, you can use the PostgreSQL
client `psql`. When you are in a terminal session with the Minerva environment
initialized, you can just type:

```bash
psql
```

This works because all environment variables have been set so that psql knows
where to connect (PGDATABASE etc.).
