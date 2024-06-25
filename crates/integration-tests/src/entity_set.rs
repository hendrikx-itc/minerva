#[cfg(test)]
mod tests {
    use assert_cmd::prelude::*;
    use std::net::{Ipv4Addr, SocketAddr, TcpStream};
    use std::process::Command;

    use log::debug;
    use serde_json::json;

    use tokio::time::Duration;
    use tokio_postgres::config::Config;

    use minerva::database::{connect_to_db, create_database, drop_database};
    use minerva::schema::create_schema;

    use crate::common::{generate_name, get_available_port, MinervaCluster};

    #[cfg(test)]
    #[tokio::test]
    async fn get_entity_sets() -> Result<(), Box<dyn std::error::Error>> {
        env_logger::init();

        let cluster = MinervaCluster::start(3).await;

        debug!("Containers started");

        let mut client = cluster.connect_to_coordinator().await;

        let database_name = generate_name();
        create_database(&mut client, &database_name).await?;
        debug!("Created database '{database_name}'");

        {
            let mut config = Config::new();

            let config = config
                .host(&cluster.controller_host.to_string())
                .port(cluster.controller_port)
                .user("postgres")
                .dbname(&database_name)
                .ssl_mode(tokio_postgres::config::SslMode::Disable);

            let mut client = connect_to_db(config).await?;
            create_schema(&mut client).await?;
        }

        let service_address = Ipv4Addr::new(127, 0, 0, 1);
        let service_port = get_available_port(service_address).unwrap();

        let mut cmd = Command::cargo_bin("minerva-service")?;
        cmd.env("PGHOST", cluster.controller_host.to_string())
            .env("PGPORT", cluster.controller_port.to_string())
            .env("PGSSLMODE", "disable")
            .env("PGDATABASE", &database_name)
            .env("SERVICE_ADDRESS", service_address.to_string())
            .env("SERVICE_PORT", service_port.to_string());

        let mut proc_handle = cmd.spawn().expect("Process started");

        debug!("Started service");

        let service_address = format!("{service_address}:{service_port}");

        let timeout = Duration::from_millis(1000);

        let ipv4_addr: SocketAddr = service_address.parse().unwrap();

        loop {
            let result = TcpStream::connect_timeout(&ipv4_addr, timeout);

            debug!("Trying to connect to service at {}", ipv4_addr);

            match result {
                Ok(_) => break,
                Err(_) => tokio::time::sleep(timeout).await,
            }
        }

        let http_client = reqwest::Client::new();
        let url = format!("http://{service_address}/entitysets");
        let response = http_client.get(url.clone()).send().await?;
        let body = response.text().await?;

        assert_eq!(body, "[]");

        let create_entity_set_data = json!({
            "name": "TinySet",
            "owner": "John Doe",
            "entities": [],
        });

        let response = http_client
            .post(url.clone())
            .json(&create_entity_set_data)
            .send()
            .await?;

        let body = response.text().await?;

        assert_eq!(body, "{}");

        match proc_handle.kill() {
            Err(e) => println!("Could not stop web service: {e}"),
            Ok(_) => println!("Stopped web service"),
        }

        drop_database(&mut client, &database_name).await?;

        debug!("Dropped database '{database_name}'");

        Ok(())
    }
}
