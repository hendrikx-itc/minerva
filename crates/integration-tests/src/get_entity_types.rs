#[cfg(test)]
mod tests {
    use assert_cmd::prelude::*;
    use std::net::{Ipv4Addr, SocketAddr, TcpStream};
    use std::process::Command;

    use log::debug;

    use tokio::time::Duration;

    use minerva::change::Change;
    use minerva::changes::trend_store::AddTrendStore;
    use minerva::schema::create_schema;
    use minerva::trend_store::{create_partitions_for_timestamp, TrendStore};

    use crate::common::{MinervaCluster, get_available_port};

    const TREND_STORE_DEFINITION: &str = r###"
    title: Raw node data
    data_source: hub
    entity_type: node
    granularity: 15m
    partition_size: 1d
    parts:
      - name: hub_node_main_15m
        trends:
          - name: outside_temp
            data_type: numeric
          - name: inside_temp
            data_type: numeric
          - name: power_kwh
            data_type: numeric
          - name: freq_power
            data_type: numeric
        generated_trends:
          - name: power_Mwh
            data_type: numeric
            description: test
            expression: power_kwh / 1000

    "###;

    #[cfg(test)]
    #[tokio::test]
    async fn get_entity_types() -> Result<(), Box<dyn std::error::Error>> {
        env_logger::init();

        let cluster = MinervaCluster::start(3).await;

        debug!("Containers started");

        let mut test_database = cluster.create_db().await;

        debug!("Created database '{}'", test_database.name);

        create_schema(&mut test_database.client).await?;

        let trend_store: TrendStore = serde_yaml::from_str(TREND_STORE_DEFINITION)
            .map_err(|e| format!("Could not read trend store definition: {}", e))?;

        let add_trend_store = AddTrendStore { trend_store };

        let mut tx = test_database.client.transaction().await?;

        add_trend_store.apply(&mut tx).await?;

        tx.commit().await?;

        let timestamp =
            chrono::DateTime::parse_from_rfc3339("2023-03-25T14:00:00+00:00").unwrap();
        create_partitions_for_timestamp(&mut test_database.client, timestamp.into()).await?;

        let service_address = Ipv4Addr::new(127, 0, 0, 1);
        let service_port = get_available_port(service_address).unwrap();

        let mut cmd = Command::cargo_bin("minerva-service")?;
        cmd
            .env("PGHOST", cluster.controller_host.to_string())
            .env("PGPORT", cluster.controller_port.to_string())
            .env("PGSSLMODE", "disable")
            .env("PGDATABASE", &test_database.name)
            .env("SERVICE_ADDRESS", service_address.to_string())
            .env("SERVICE_PORT", service_port.to_string());

        let mut proc_handle = cmd.spawn().expect("Process started");

        println!("Started service");

        let address = format!("{service_address}:{service_port}");

        let url = format!("http://{address}/entity-types");
        let timeout = Duration::from_millis(1000);

        let ipv4_addr: SocketAddr = address.parse().unwrap();

        loop {
            let result = TcpStream::connect_timeout(&ipv4_addr, timeout);

            debug!("Trying to connect to service at {}", ipv4_addr);

            match result {
                Ok(_) => break,
                Err(_) => tokio::time::sleep(timeout).await,
            }
        }

        let response = reqwest::get(url).await?;
        let body = response.text().await?;

        match proc_handle.kill() {
            Err(e) => println!("Could not stop web service: {e}"),
            Ok(_) => println!("Stopped web service"),
        }

        let mut admin_client = cluster.connect_to_coordinator().await;

        test_database.drop_database(&mut admin_client).await;

        println!("Dropped database '{}'", test_database.name);

        assert_eq!(body, "[{\"id\":1,\"name\":\"entity_set\",\"description\":\"\"},{\"id\":2,\"name\":\"node\",\"description\":\"\"}]");

        Ok(())
    }
}
