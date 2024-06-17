use std::net::IpAddr;
use std::path::PathBuf;
use std::{env, u8};

use async_trait::async_trait;
use clap::Parser;

use testcontainers::core::{ContainerRequest, WaitFor};
use testcontainers::{GenericImage, ImageExt};
use testcontainers_modules::testcontainers::runners::AsyncRunner;
use tokio::signal;
use tokio::time::{sleep, Duration};
use tokio_postgres::config::Config;
use tokio_postgres::{Client, NoTls};

use minerva::error::Error;
use minerva::instance::MinervaInstance;
use minerva::schema::create_schema;
use minerva::trend_store::create_partitions;

use super::common::{Cmd, CmdResult, ENV_MINERVA_INSTANCE_ROOT};

const CITUS_IMAGE: &str = "citusdata/citus";
const CITUS_TAG: &str = "12.0";

#[derive(Debug, Parser, PartialEq)]
pub struct StartOpt {
    #[arg(long = "create-partitions", help = "create partitions")]
    create_partitions: bool,
    #[arg(long = "node-count", help = "number of worker nodes")]
    node_count: Option<u8>,
    #[arg(
        long = "with-definition",
        help = "Minerva instance definition root directory"
    )]
    instance_root: Option<PathBuf>,
}

#[async_trait]
impl Cmd for StartOpt {
    async fn run(&self) -> CmdResult {
        println!("Starting containers");
        let network = "test".to_string();
        let controller_container = create_citus_controller()
            .with_network(network.clone())
            .start()
            .await
            .unwrap();

        let controller_host = controller_container.get_host().await.unwrap();
        let controller_port = controller_container.get_host_port_ipv4(5432).await.unwrap();

        println!("Connecting to controller");
        let mut client = connect_db(controller_host.clone(), controller_port).await?;
        println!("Creating Minerva schema");
        create_schema(&mut client).await.unwrap();

        let minerva_instance_root_option: Option<PathBuf> = match &self.instance_root {
            Some(root) => Some(root.clone()),
            None => match env::var(ENV_MINERVA_INSTANCE_ROOT) {
                Ok(v) => Some(PathBuf::from(v)),
                Err(_) => None,
            },
        };

        if let Some(minerva_instance_root) = minerva_instance_root_option {
            println!(
                "Initializing from '{}'",
                minerva_instance_root.to_string_lossy()
            );

            let minerva_instance = MinervaInstance::load_from(&minerva_instance_root);
            minerva_instance.initialize(&mut client).await;

            if self.create_partitions {
                create_partitions(&mut client, None).await?;
            }

            println!("Initialized");
        }

        let node1_container = create_citus_node(1)
            .with_network(network.clone())
            .start()
            .await
            .unwrap();
        let node2_container = create_citus_node(2)
            .with_network(network.clone())
            .start()
            .await
            .unwrap();
        let node3_container = create_citus_node(3)
            .with_network(network.clone())
            .start()
            .await
            .unwrap();

        println!("Connecting nodes");

        let coordinator_host = controller_container.get_bridge_ip_address().await.unwrap();
        let coordinator_port = 5432;

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

        println!("Minerva cluster is running (press CTRL-C to stop)");
        println!("Connect to the cluster on port {}", controller_port);
        println!("");
        println!("  psql -h localhost -p {controller_port} -U postgres");

        signal::ctrl_c().await.map_err(|e| {
            Error::Runtime(format!("Could not start waiting for Ctrl-C: {e}").into())
        })?;

        Ok(())
    }
}

fn create_citus_controller() -> ContainerRequest<GenericImage> {
    let image = GenericImage::new(CITUS_IMAGE, CITUS_TAG)
        .with_exposed_port(testcontainers::core::ContainerPort::Tcp(5432))
        .with_wait_for(WaitFor::message_on_stdout(
            "PostgreSQL init process complete; ready for start up.",
        ));

    let request = ContainerRequest::from(image);

    request
        .with_env_var("POSTGRES_HOST_AUTH_METHOD", "trust")
        .with_container_name("coordinator")
}

fn create_citus_node(index: u8) -> ContainerRequest<GenericImage> {
    let image = GenericImage::new(CITUS_IMAGE, CITUS_TAG)
        .with_exposed_port(testcontainers::core::ContainerPort::Tcp(5432))
        .with_wait_for(WaitFor::message_on_stdout(
            "PostgreSQL init process complete; ready for start up.",
        ));

    let request = ContainerRequest::from(image);

    request
        .with_env_var("POSTGRES_HOST_AUTH_METHOD", "trust")
        .with_container_name(format!("worker_{index}"))
}

async fn add_worker(client: &mut Client, host: IpAddr, port: u16) -> Result<(), String> {
    client
        .execute(
            "SELECT citus_add_node($1, $2)",
            &[&(&host.to_string()), &(port as i32)],
        )
        .await
        .map_err(|e| format!("Could not connect node {host:?}: {e}"))?;

    println!("Connected node: {host:?}");

    Ok(())
}

async fn connect_db(host: url::Host, port: u16) -> Result<Client, Error> {
    let mut config = Config::new();

    let config = config
        .host(host.to_string().as_str())
        .port(port)
        .user("postgres")
        .password("password");

    println!("Connecting to database host '{}' port '{}'", host, port);

    let mut connect_attempt = 1;

    let (client, connection) = loop {
        let conn_result = config.connect(NoTls).await;

        match conn_result {
            Ok(ok_result) => break ok_result,
            Err(e) => {
                if connect_attempt > 5 {
                    return Err(Error::Runtime(
                        format!("Error connecting: {e}, retrying").into(),
                    ));
                }
            }
        }

        sleep(Duration::from_millis(100)).await;
        connect_attempt += 1;
    };

    tokio::spawn(async move {
        if let Err(e) = connection.await {
            println!("Connection error {e}");
        }
    });

    println!("Connected to database host '{}' port '{}'", host, port);

    Ok(client)
}
