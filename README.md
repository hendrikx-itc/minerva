# Minerva ETL Platform

This project provides the Minerva ETL platform components:

1. Database schema definition.
2. Command line administration tools.
3. Library for interacting with Minerva instances.
4. Web service for Minerva instance administration.

# Installation

To install the latest version of the administration command for your system,
use the install script:

```
curl -sS https://raw.githubusercontent.com/hendrikx-itc/minerva-admin/master/install.sh | sh
```

# Start Test Database

To develop Minerva instances, or work on the code in this project, you will
need a running Minerva database. You can start an empty Minerva database using
Docker:

```
docker run -e POSTGRES_HOST_AUTH_METHOD=trust -p 5432:5432 citusdata/citus
```

# Run Integration Tests

After a test database is started, run the following command:

```
PGSSLMODE=disable PGHOST=127.0.0.1 PGUSER=postgres cargo test -p integration-tests --lib
```

# Load Test Instance

To load a provided test instance into the empty Minerva database, use the following command:

```
PGSSLMODE=disable PGUSER=postgres PGHOST=127.0.0.1 cargo run --bin=minerva-admin -- initialize --create-schema --with-definition examples/tiny_instance_v1
```

