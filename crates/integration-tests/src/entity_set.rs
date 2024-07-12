#[cfg(test)]
mod tests {
    use std::net::{Ipv4Addr, SocketAddr, TcpStream};
    use std::process::Command;
    use std::path::PathBuf;

    use log::{debug, error};
    use serde_json::{json, Value};

    use tokio::time::Duration;

    use assert_cmd::prelude::*;

    use minerva::change::Change;
    use minerva::trend_store::TrendStore;
    use minerva::changes::trend_store::AddTrendStore;
    use minerva::schema::create_schema;
    use minerva::cluster::MinervaCluster;

    use crate::common::get_available_port;

    struct MinervaServiceConfig {
        pub pg_host: String,
        pub pg_port: String,
        pub pg_sslmode: String,
        pub pg_database: String,
        pub service_address: String,
        pub service_port: u16,
    }

    struct MinervaService {
        conf: MinervaServiceConfig,
        proc_handle: std::process::Child,
    }

    impl MinervaService {
        fn start(conf: MinervaServiceConfig) -> Result<MinervaService, Box<dyn std::error::Error>> {
            let mut cmd = Command::cargo_bin("minerva-service")?;

            cmd.env("PGHOST", conf.pg_host.to_string())
                .env("PGPORT", conf.pg_port.to_string())
                .env("PGSSLMODE", conf.pg_sslmode.to_string())
                .env("PGDATABASE", conf.pg_database.to_string())
                .env("SERVICE_ADDRESS", conf.service_address.to_string())
                .env("SERVICE_PORT", conf.service_port.to_string());

            let proc_handle = cmd.spawn()?;

            Ok(MinervaService {
                conf,
                proc_handle,
            })
        }

        async fn wait_for(&self) {
            let service_address = format!("{}:{}", self.conf.service_address, self.conf.service_port);

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
        }

        fn base_url(&self) -> String {
            format!("http://{}:{}", self.conf.service_address, self.conf.service_port)
        }
    }

    impl Drop for MinervaService {
        fn drop(&mut self) {
            match self.proc_handle.kill() {
                Err(e) => error!("Could not stop web service: {e}"),
                Ok(_) => debug!("Stopped web service"),
            }
        }
    }

    /// Test the listing and creation of new entity sets
    #[tokio::test]
    async fn get_and_create_entity_sets() -> Result<(), Box<dyn std::error::Error>> {
        crate::setup();

        let config_file = PathBuf::from(concat!(env!("CARGO_MANIFEST_DIR"), "/postgresql.conf"));

        let cluster = MinervaCluster::start(&config_file, 3).await?;

        debug!("Containers started");

        let test_database = cluster.create_db().await?;

        {
            let mut client = test_database.connect().await?;
            create_schema(&mut client).await?;

            let trend_store: TrendStore = TrendStore {
                data_source: "integration_test".to_string(),
                entity_type: "pvpanel".to_string(),
                granularity: Duration::from_secs(300),
                partition_size: Duration::from_secs(86400), 
                parts: [].to_vec(),
            };

            let add_trend_store = AddTrendStore { trend_store };

            let mut tx = client.transaction().await?;

            // Using this as a hack to make sure the entity type is created
            add_trend_store.apply(&mut tx).await?;

            let entities = vec!(
                "panel_01".to_string(),
                "panel_02".to_string(),
            );

            tx.execute("INSERT INTO entity.pvpanel(name) SELECT unnest($1::text[])", &[&entities]).await?;

            tx.commit().await?;
        }

        {
            let service_address = Ipv4Addr::new(127, 0, 0, 1);
            let service_port = get_available_port(service_address).unwrap();

            let service_conf = MinervaServiceConfig {
                pg_host: cluster.controller_host.to_string(),
                pg_port: cluster.controller_port.to_string(),
                pg_sslmode: "disable".to_string(),
                pg_database: test_database.name.to_string(),
                service_address: service_address.to_string(),
                service_port,
            };

            let service = MinervaService::start(service_conf)?;

            debug!("Started service");

            service.wait_for().await;

            let http_client = reqwest::Client::new();
            let url = format!("{}/entitysets", service.base_url());
            let response = http_client.get(url.clone()).send().await?;
            let body = response.text().await?;

            assert_eq!(body, "[]");

            let create_entity_set_data = json!({
                "name": "TinySet",
                "owner": "John Doe",
                "entities": ["panel_01", "panel_02"],
                "entity_type": "pvpanel",
            });

            let response = http_client
                .post(url.clone())
                .json(&create_entity_set_data)
                .send()
                .await?;

            assert_eq!(response.status(), 200);

            let body: Value = response.json().await?;

            assert_eq!(
                body,
                json!({
                    "code": 200,
                    "message": "Entity set created",
                })
            );
        }

        let mut admin_client = cluster.connect_to_coordinator().await;

        test_database.drop_database(&mut admin_client).await;

        Ok(())
    }
}
