const CITUS_IMAGE: &str = "citusdata/citus";
const CITUS_TAG: &str = "12.0";

use std::net::IpAddr;
use std::net::{Ipv4Addr, SocketAddr, SocketAddrV4, TcpListener};

use log::{error, debug};

use rand::distributions::{Alphanumeric, DistString};

use tokio_postgres::config::Config;
use tokio_postgres::{Client, NoTls};
use tokio::io::AsyncBufReadExt;
use tokio::time::{sleep, Duration};

use testcontainers::core::{ContainerPort, ContainerRequest, Mount, WaitFor};
use testcontainers::{GenericImage, ImageExt};

use minerva::database::{connect_to_db, drop_database};


pub fn generate_name(len: usize) -> String {
    Alphanumeric.sample_string(&mut rand::thread_rng(), len)
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
    TcpListener::bind(addr).is_ok()
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

    debug!("Connecting to database host '{}' port '{}'", host, port);

    let (client, connection) = loop {
        let conn_result = config.connect(NoTls).await;

        match conn_result {
            Ok(ok_result) => break ok_result,
            Err(e) => {
                debug!("Error connecting: {e}, retrying");
            }
        }

        sleep(Duration::from_millis(100)).await;
    };

    tokio::spawn(async move {
        if let Err(e) = connection.await {
            error!("Connection error {e}");
        }
    });

    debug!("Connected to database host '{}' port '{}'", host, port);

    client
}

pub struct TestDatabase {
    pub name: String,
    connect_config: Config,
}

impl TestDatabase {
    pub async fn drop_database(&self, client: &mut Client) {
        drop_database(client, &self.name).await.unwrap()
    }

    pub async fn connect(&self) -> Result<Client, minerva::error::Error> {
        connect_to_db(&self.connect_config).await
    }
}

