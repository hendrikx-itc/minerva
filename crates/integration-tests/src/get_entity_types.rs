#[cfg(test)]
mod tests {
    const CITUS_IMAGE: &str = "citusdata/citus";
    const CITUS_TAG: &str = "12.0";

    use assert_cmd::prelude::*;
    use std::path::Path;
    use std::net::IpAddr;
    use std::net::{Ipv4Addr, SocketAddr, SocketAddrV4, TcpListener, TcpStream};
    use std::process::Command;
    use chrono::DateTime;
    use std::str::FromStr;

    use rand::distributions::{Alphanumeric, DistString};

    use tokio_postgres::config::Config;
    use tokio_postgres::{Client, NoTls};
    use tokio::time::{sleep, Duration};

    use testcontainers::core::{ContainerPort, ContainerRequest, WaitFor};
    use testcontainers::{GenericImage, ImageExt};
    use testcontainers_modules::testcontainers::runners::AsyncRunner;

    use minerva::change::Change;
    use minerva::database::{connect_to_db, create_database, drop_database, get_db_config};
    use minerva::instance::MinervaInstance;
    use minerva::changes::trend_store::AddTrendStore;
    use minerva::schema::create_schema;
    use minerva::trend_store::{create_partitions_for_timestamp, TrendStore};

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

    fn generate_name() -> String {
        Alphanumeric.sample_string(&mut rand::thread_rng(), 16)
    }

    fn create_citus_controller() -> ContainerRequest<GenericImage> {
        let image = GenericImage::new(CITUS_IMAGE, CITUS_TAG)
            .with_exposed_port(ContainerPort::Tcp(5432))
            .with_wait_for(WaitFor::message_on_stdout(
                "PostgreSQL init process complete; ready for start up.",
            ));

        let request = ContainerRequest::from(image);

        request.with_env_var("POSTGRES_HOST_AUTH_METHOD", "trust")
    }

    fn create_citus_node() -> ContainerRequest<GenericImage> {
        let image = GenericImage::new(CITUS_IMAGE, CITUS_TAG)
            .with_exposed_port(ContainerPort::Tcp(5432))
            .with_wait_for(WaitFor::message_on_stdout(
                "PostgreSQL init process complete; ready for start up.",
            ));

        let request = ContainerRequest::from(image);

        request.with_env_var("POSTGRES_HOST_AUTH_METHOD", "trust")
    }
    async fn connect_db(host: url::Host, port: u16) -> Client {
        let mut config = Config::new();

        let config = config
            .host(host.to_string().as_str())
            .port(port)
            .user("postgres")
            .password("password");

        println!("Connecting to database host '{}' port '{}'", host, port);

        let (client, connection) = loop {
            let conn_result = config.connect(NoTls).await;

            match conn_result {
                Ok(ok_result) => break ok_result,
                Err(e) => {
                    println!("Error connecting: {e}, retrying");
                }
            }

            sleep(Duration::from_millis(100)).await;
        };

        tokio::spawn(async move {
            if let Err(e) = connection.await {
                println!("Connection error {e}");
            }
        });

        println!("Connected to database host '{}' port '{}'", host, port);

        client
    }

    async fn add_worker(client: &mut Client, host: IpAddr, port: u16) -> Result<(), String> {
        println!("Host: {host:?}");
        let _count = client
            .execute(
                "SELECT citus_add_node($1, $2)",
                &[&(&host.to_string()), &(port as i32)],
            )
            .await
            .map_err(|e| format!("Could not add worker node: {e}"))?;

        Ok(())
    }

    #[cfg(test)]
    #[tokio::test]
    async fn get_entity_types() -> Result<(), Box<dyn std::error::Error>> {
        let network = "test".to_string();
        let controller_container = create_citus_controller()
            .with_network(network.clone())
            .start()
            .await
            .expect("Controller container");

        let controller_host = controller_container
            .get_host()
            .await
            .expect("Controller host");
        let controller_port = controller_container
            .get_host_port_ipv4(5432)
            .await
            .expect("Controller port");

        println!("Connecting to controller");
        let mut client = connect_db(controller_host.clone(), controller_port).await;
        println!("Creating Minerva schema");
        create_schema(&mut client).await.unwrap();
        println!("Initializing");
        let instance_path = Path::new(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/dev-stack/minerva-instance"
        ));
        let minerva_instance = MinervaInstance::load_from(instance_path);
        minerva_instance.initialize(&mut client).await;
        println!("Initialized");

        let node1_container = create_citus_node()
            .with_network(network.clone())
            .start()
            .await
            .unwrap();
        let node2_container = create_citus_node()
            .with_network(network.clone())
            .start()
            .await
            .unwrap();
        let node3_container = create_citus_node()
            .with_network(network.clone())
            .start()
            .await
            .unwrap();

        println!("Containers started");

        println!("Connecting nodes");

        let coordinator_host = controller_container
            .get_bridge_ip_address()
            .await
            .expect("Controller IP address");
        let coordinator_port = 5432;
        println!(
            "Setting Citus coordinator host address: {}:{}",
            &coordinator_host, &coordinator_port
        );

        client
            .execute(
                "SELECT citus_set_coordinator_host($1, $2)",
                &[&coordinator_host.to_string(), &(coordinator_port as i32)],
            )
            .await
            .unwrap();

        add_worker(
            &mut client,
            node1_container.get_bridge_ip_address().await.unwrap(),
            5432,
        )
        .await
        .expect("Could not connect node");
        add_worker(
            &mut client,
            node2_container.get_bridge_ip_address().await.unwrap(),
            5432,
        )
        .await
        .expect("Could not connect node");
        add_worker(
            &mut client,
            node3_container.get_bridge_ip_address().await.unwrap(),
            5432,
        )
        .await
        .expect("Could not connect node");

        println!("Connected nodes");

        println!("Creating partitions");
        let timestamp = DateTime::from_str("2023-09-20T22:15:00+02:00").unwrap();
        create_partitions_for_timestamp(&mut client, timestamp)
            .await
            .unwrap();
        println!("Created partitions");







        let database_name = generate_name();
        let db_config = get_db_config()?;
        let mut client = connect_to_db(&db_config).await?;

        create_database(&mut client, &database_name).await?;
        println!("Created database '{database_name}'");

        {
            let mut client = connect_to_db(&db_config.clone().dbname(&database_name)).await?;
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

        let service_address = Ipv4Addr::new(127, 0, 0, 1);
        let service_port = get_available_port(service_address).unwrap();

        let mut cmd = Command::cargo_bin("minerva-service")?;
        cmd.env("PGDATABASE", &database_name)
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

        let mut client = connect_to_db(&db_config).await?;

        drop_database(&mut client, &database_name).await?;

        println!("Dropped database '{database_name}'");

        assert_eq!(body, "[{\"id\":1,\"name\":\"entity_set\",\"description\":\"\"},{\"id\":2,\"name\":\"node\",\"description\":\"\"}]");

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
