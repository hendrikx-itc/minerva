const CITUS_IMAGE: &str = "citusdata/citus";
const CITUS_TAG: &str = "12.0";

use std::net::IpAddr;
use std::net::{Ipv4Addr, SocketAddr, SocketAddrV4, TcpListener};

use rand::distributions::{Alphanumeric, DistString};

use tokio_postgres::config::Config;
use tokio_postgres::{Client, NoTls};
use tokio::io::AsyncBufReadExt;
use tokio::time::{sleep, Duration};

use testcontainers::core::{ContainerPort, ContainerRequest, WaitFor, Mount};
use testcontainers::{GenericImage, ImageExt, ContainerAsync};
use testcontainers_modules::testcontainers::runners::AsyncRunner;

use minerva::database::connect_to_db;


pub fn generate_name() -> String {
    Alphanumeric.sample_string(&mut rand::thread_rng(), 16)
}


pub fn create_citus_container(name: &str, exposed_port: Option<u16>) -> ContainerRequest<GenericImage> {
    let image = GenericImage::new(CITUS_IMAGE, CITUS_TAG)
        .with_wait_for(WaitFor::message_on_stdout(
            "PostgreSQL init process complete; ready for start up.",
        ));

    let image = match exposed_port {
        Some(port) => image.with_exposed_port(ContainerPort::Tcp(port)),
        None => image
    };

    let request = ContainerRequest::from(image);

    let conf_file_path = concat!(env!("CARGO_MANIFEST_DIR"), "/postgresql.conf");

    request
        .with_env_var("POSTGRES_HOST_AUTH_METHOD", "trust")
        .with_container_name(name)
        .with_mount(Mount::bind_mount(conf_file_path, "/etc/postgresql/postgresql.conf"))
        .with_cmd(vec!["-c", "config-file=/etc/postgresql/postgresql.conf"])
}

pub fn get_available_port(ip_addr: Ipv4Addr) -> Option<u16> {
    (1000..50000).find(|port| port_available(SocketAddr::V4(SocketAddrV4::new(ip_addr, *port))))
}

fn port_available(addr: SocketAddr) -> bool {
    match TcpListener::bind(addr) {
        Ok(_) => true,
        Err(_) => false,
    }
}

pub async fn add_worker(client: &mut Client, host: IpAddr, port: u16) -> Result<(), String> {
    let _count = client
        .execute(
            "SELECT citus_add_node($1, $2)",
            &[&(&host.to_string()), &(port as i32)],
        )
        .await
        .map_err(|e| format!("Could not add worker node: {e}"))?;

    Ok(())
}

pub fn print_stdout<I: tokio::io::AsyncBufRead + std::marker::Unpin + std::marker::Send + 'static>(prefix: String, mut reader: I) {
    tokio::spawn(async move {
        let mut buffer = String::new();
        loop {
            let result = reader.read_line(&mut buffer).await;

            if let Ok(0) = result { break };

            print!("{prefix} - {buffer}");

            buffer.clear();
        }
    });
}

pub async fn connect_db(host: url::Host, port: u16) -> Client {
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

pub struct MinervaCluster {
    controller_container: ContainerAsync<GenericImage>,
    worker_containers: Vec<std::pin::Pin<Box<ContainerAsync<GenericImage>>>>,
    pub controller_host: url::Host,
    pub controller_port: u16,
}

impl MinervaCluster {
    pub async fn start(worker_count: u8) -> MinervaCluster {
        let network = generate_name();

        let controller_container = create_citus_container("coordinator", Some(5432))
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

        let coordinator_host = controller_container
            .get_bridge_ip_address()
            .await
            .expect("Controller IP address");
        let coordinator_port: i32 = 5432;
        println!(
            "Setting Citus coordinator host address: {}:{}",
            &coordinator_host, &coordinator_port
        );

        client
            .execute(
                "SELECT citus_set_coordinator_host($1, $2)",
                &[&coordinator_host.to_string(), &coordinator_port],
            )
            .await
            .unwrap();

        let mut node_containers = Vec::new();

        for i in 1..(worker_count + 1) {
            let name = format!("node{i}");
            let container = create_citus_container(&name, None)
                .with_network(network.clone())
                .start()
                .await
                .unwrap();

            print_stdout(name, container.stdout(true));

            let container_address = container.get_bridge_ip_address().await.unwrap();

            println!("Adding worker {container_address}");

            sleep(Duration::from_secs(1)).await;

            add_worker(
                &mut client,
                container_address,
                5432,
            )
            .await
            .expect("Could not connect worker");

            node_containers.push(Box::pin(container));
        }
        
        MinervaCluster {
            controller_container,
            worker_containers: node_containers,
            controller_host,
            controller_port,
        }
    }

    pub fn size(&self) -> usize {
        self.worker_containers.len()
    }

    pub async fn connect_to_coordinator(&self) -> Client {
        let controller_host = self.controller_container
            .get_host()
            .await
            .expect("Controller host");
        let controller_port = self.controller_container
            .get_host_port_ipv4(5432)
            .await
            .expect("Controller port");

        connect_db(controller_host, controller_port).await
    }

    pub async fn connect_to_db(&self, database_name: &str) -> Result<Client, minerva::error::Error> {
        let mut config = Config::new();

        let config = config
            .host(&self.controller_host.to_string())
            .port(self.controller_port)
            .user("postgres")
            .dbname(database_name)
            .ssl_mode(tokio_postgres::config::SslMode::Disable);

        connect_to_db(config).await
    }
}
