# Minerva ETL

This repository contains the PostgreSQL based database schema for the Minerva ETL platform.

## Development

Developing on and with Minerva is easy using development Docker containers and
the commands provided in this repository.

### Prerequisites

 - [Docker](https://www.docker.com)

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

