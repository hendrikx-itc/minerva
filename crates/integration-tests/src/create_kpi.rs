#[cfg(test)]
mod tests {
    use assert_cmd::prelude::*;
    use std::net::{Ipv4Addr, SocketAddr, SocketAddrV4, TcpListener, TcpStream};
    use std::process::Command;
    use std::time::Duration;

    use rand::distributions::{Alphanumeric, DistString};

    use minerva::change::Change;
    use minerva::database::{connect_to_db, create_database, drop_database, get_db_config};

    use minerva::changes::trend_store::AddTrendStore;
    use minerva::schema::create_schema;
    use minerva::trend_store::TrendStore;

    const TREND_STORE_DEFINITION_15M: &str = r###"
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
    "###;

    const TREND_STORE_DEFINITION_1D: &str = r###"
    title: Raw node data
    data_source: hub
    entity_type: node
    granularity: 1d
    partition_size: 1d
    parts:
      - name: hub_node_main_1d
        trends:
          - name: outside_temp
            data_type: numeric
          - name: inside_temp
            data_type: numeric
          - name: power_kwh
            data_type: numeric
          - name: freq_power
            data_type: numeric
    "###;

    fn generate_name() -> String {
        Alphanumeric.sample_string(&mut rand::thread_rng(), 16)
    }

    #[cfg(test)]
    #[tokio::test]
    async fn create_kpi() -> Result<(), Box<dyn std::error::Error>> {
        use minerva::trend_materialization::get_function_def;

        let database_name = generate_name();
        let db_config = get_db_config()?;
        let mut client = connect_to_db(&db_config).await?;

        create_database(&mut client, &database_name).await?;
        println!("Created database '{database_name}'");

        {
            let mut client = connect_to_db(&db_config.clone().dbname(&database_name)).await?;
            create_schema(&mut client).await?;

            let trend_store: TrendStore = serde_yaml::from_str(TREND_STORE_DEFINITION_15M)
                .map_err(|e| format!("Could not read trend store definition: {}", e))?;

            let add_trend_store = AddTrendStore { trend_store };

            let mut tx = client.transaction().await?;

            add_trend_store.apply(&mut tx).await?;

            let trend_store: TrendStore = serde_yaml::from_str(TREND_STORE_DEFINITION_1D)
                .map_err(|e| format!("Could not read trend store definition: {}", e))?;

            let add_trend_store = AddTrendStore { trend_store };

            add_trend_store.apply(&mut tx).await?;

            tx.commit().await?;
        }

        let service_address = Ipv4Addr::new(127, 0, 0, 1);
        let service_port = get_available_port(service_address).unwrap();

        let mut cmd = Command::cargo_bin("minerva-service")?;
        cmd.env("PGDATABASE", &database_name)
            .env("SERVICE_ADDRESS", service_address.to_string())
            .env("SERVICE_PORT", service_port.to_string());

        let mut proc_handle = cmd.spawn().expect("Process started");

        println!("Started service");

        let address = format!("{service_address}:{service_port}");

        let timeout = Duration::from_millis(1000);

        let ipv4_addr: SocketAddr = address.parse().unwrap();

        loop {
            let result = TcpStream::connect_timeout(&ipv4_addr, timeout);

            match result {
                Ok(_) => break,
                Err(_) => tokio::time::sleep(timeout).await,
            }
        }

        let client = reqwest::Client::new();

        let url = format!("http://{address}/kpis");
        let request_body = r#"{
  "tsp_name": "test-kpi",
  "kpi_name": "test-kpi-name",
  "entity_type": "node",
  "data_type": "numeric",
  "enabled": true,
  "source_trends": ["inside_temp"],
  "definition": "inside_temp - outside_temp",
  "description": {
      "factors": [
          [
            {
                "type": "trend",
                "value": "inside_temp"
            },
            {
                "type": "operator",
                "value": "-"
            },
            {
                "type": "trend",
                "value": "outside_temp"
            }
          ]
      ],
      "numberdenominator": 1,
      "numbernumerator": 1,
      "type": "Sum"
  }
}"#;

        let response = client.post(url).body(request_body).send().await?;

        let body = response.text().await?;

        match proc_handle.kill() {
            Err(e) => println!("Could not stop web service: {e}"),
            Ok(_) => println!("Stopped web service"),
        }

        let (language, src): (String, String) = {
            let mut client = connect_to_db(&db_config.clone().dbname(&database_name)).await?;

            get_function_def(&mut client, "kpi-test-kpi_node_15m").await.unwrap()
        };

        assert_eq!(body, "{\"code\":200,\"message\":\"Successfully created KPI\"}");

        assert_eq!(language, "plpgsql");

        let expected_src = concat!(
            "\nBEGIN\n",
            "RETURN QUERY EXECUTE $query$\n",
            "SELECT\n",
            "  t1.entity_id,\n",
            "  $1 AS timestamp,\n",
            "  inside_temp - outside_temp AS \"test-kpi-name\"\n",
            "FROM trend.\"hub_node_main_15m\" t1\n",
            "WHERE t1.timestamp = $1\n",
            "GROUP BY t1.entity_id\n",
            "$query$ USING $1;\n",
            "END;\n\n"
        );

        assert_eq!(src, expected_src);

        let mut client = connect_to_db(&db_config).await?;

        drop_database(&mut client, &database_name).await?;

        println!("Dropped database '{database_name}'");

        Ok(())
    }

    fn get_available_port(ip_addr: Ipv4Addr) -> Option<u16> {
        (1000..50000).find(|port| port_available(SocketAddr::V4(SocketAddrV4::new(ip_addr, *port))))
    }

    fn port_available(addr: SocketAddr) -> bool {
        match TcpListener::bind(addr) {
            Ok(_) => true,
            Err(_) => false,
        }
    }
}
