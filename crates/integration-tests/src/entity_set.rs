#[cfg(test)]
mod tests {
    use assert_cmd::prelude::*;
    use std::net::{Ipv4Addr, SocketAddr, TcpStream};
    use std::process::Command;

    use log::debug;
    use serde_json::json;

    use tokio::time::Duration;

    use minerva::schema::create_schema;
    use minerva::cluster::MinervaCluster;

    use crate::common::get_available_port;

    /// Test the listing and creation of new entity sets
    #[tokio::test]
    async fn get_and_create_entity_sets() -> Result<(), Box<dyn std::error::Error>> {
        crate::setup();

        let cluster = MinervaCluster::start(3).await?;

        debug!("Containers started");

        let test_database = cluster.create_db().await?;

        {
            let mut client = test_database.connect().await?;
            create_schema(&mut client).await?;
        }

        let service_address = Ipv4Addr::new(127, 0, 0, 1);
        let service_port = get_available_port(service_address).unwrap();

        let mut cmd = Command::cargo_bin("minerva-service")?;
        cmd.env("PGHOST", cluster.controller_host.to_string())
            .env("PGPORT", cluster.controller_port.to_string())
            .env("PGSSLMODE", "disable")
            .env("PGDATABASE", &test_database.name)
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

        match proc_handle.kill() {
            Err(e) => println!("Could not stop web service: {e}"),
            Ok(_) => println!("Stopped web service"),
        }

        let mut admin_client = cluster.connect_to_coordinator().await;

        test_database.drop_database(&mut admin_client).await;

        assert_eq!(body, "{}");

        Ok(())
    }
}
