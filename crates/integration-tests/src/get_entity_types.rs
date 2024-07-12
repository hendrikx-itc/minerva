#[cfg(test)]
mod tests {
    use std::net::{Ipv4Addr, SocketAddr, TcpStream};
    use std::path::PathBuf;

    use log::debug;

    use tokio::time::Duration;

    use minerva::change::Change;
    use minerva::changes::trend_store::AddTrendStore;
    use minerva::schema::create_schema;
    use minerva::trend_store::{create_partitions_for_timestamp, TrendStore};
    use minerva::cluster::MinervaCluster;

    use crate::common::{get_available_port, MinervaServiceConfig, MinervaService};

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

    #[tokio::test]
    async fn get_entity_types() -> Result<(), Box<dyn std::error::Error>> {
        crate::setup();

        let config_file = PathBuf::from(concat!(env!("CARGO_MANIFEST_DIR"), "/postgresql.conf"));

        let cluster = MinervaCluster::start(&config_file, 3).await?;

        debug!("Containers started");

        let test_database = cluster.create_db().await?;

        debug!("Created database '{}'", test_database.name);

        {
            let mut client = test_database.connect().await?;

            create_schema(&mut client).await?;

            let trend_store: TrendStore = serde_yaml::from_str(TREND_STORE_DEFINITION)
                .map_err(|e| format!("Could not read trend store definition: {}", e))?;

            let add_trend_store = AddTrendStore { trend_store };

            let mut tx = client.transaction().await?;

            add_trend_store.apply(&mut tx).await?;

            tx.commit().await?;

            let timestamp =
                chrono::DateTime::parse_from_rfc3339("2023-03-25T14:00:00+00:00").unwrap();
            create_partitions_for_timestamp(&mut client, timestamp.into()).await?;
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

            let mut service = MinervaService::start(service_conf)?;

            println!("Started service");

            service.wait_for().await?;

            let address = format!("{service_address}:{service_port}");

            let url = format!("http://{address}/entity-types");

            let response = reqwest::get(url).await?;
            let body = response.text().await?;

            assert_eq!(body, "[{\"id\":1,\"name\":\"entity_set\",\"description\":\"\"},{\"id\":2,\"name\":\"node\",\"description\":\"\"}]");
        }

        let mut admin_client = cluster.connect_to_coordinator().await;

        test_database.drop_database(&mut admin_client).await;

        println!("Dropped database '{}'", test_database.name);

        Ok(())
    }
}
