use std::net::{Ipv4Addr, SocketAddr, SocketAddrV4, TcpListener, TcpStream};
use std::process::Command;
use std::time::Duration;

use log::{debug, error};
use assert_cmd::prelude::*;
use minerva::error::{Error, RuntimeError};
use rand::distributions::{Alphanumeric, DistString};

use tokio::io::AsyncBufReadExt;


pub fn generate_name(len: usize) -> String {
    Alphanumeric.sample_string(&mut rand::thread_rng(), len)
}

pub fn get_available_port(ip_addr: Ipv4Addr) -> Option<u16> {
    (1000..50000).find(|port| port_available(SocketAddr::V4(SocketAddrV4::new(ip_addr, *port))))
}

fn port_available(addr: SocketAddr) -> bool {
    TcpListener::bind(addr).is_ok()
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

pub struct MinervaServiceConfig {
    pub pg_host: String,
    pub pg_port: String,
    pub pg_sslmode: String,
    pub pg_database: String,
    pub service_address: String,
    pub service_port: u16,
}

pub struct MinervaService {
    conf: MinervaServiceConfig,
    pub proc_handle: std::process::Child,
}

impl MinervaService {
    pub fn start(conf: MinervaServiceConfig) -> Result<MinervaService, Box<dyn std::error::Error>> {
        let mut cmd = Command::cargo_bin("minerva-service")?;

        cmd.env("PGHOST", &conf.pg_host)
            .env("PGPORT", &conf.pg_port)
            .env("PGSSLMODE", &conf.pg_sslmode)
            .env("PGDATABASE", &conf.pg_database)
            .env("SERVICE_ADDRESS", &conf.service_address)
            .env("SERVICE_PORT", conf.service_port.to_string());

        let proc_handle = cmd.spawn()?;

        Ok(MinervaService {
            conf,
            proc_handle,
        })
    }

    pub async fn wait_for(&mut self) -> Result<(), Error> {
        let service_address = format!("{}:{}", self.conf.service_address, self.conf.service_port);

        let timeout = Duration::from_millis(1000);

        let ipv4_addr: SocketAddr = service_address.parse().unwrap();

        loop {
            let result = TcpStream::connect_timeout(&ipv4_addr, timeout);

            debug!("Trying to connect to service at {}", ipv4_addr);

            match result {
                Ok(_) => return Ok(()),
                Err(_) => {
                    // Check if process is still running
                    let wait_result = self.proc_handle
                        .try_wait()
                        .map_err(|e| RuntimeError::from_msg(format!("Could not wait for service exit: {e}")))?;

                    if let Some(status) = wait_result {
                        panic!("Service prematurely exited with code: {status}");
                    }

                    tokio::time::sleep(timeout).await
                },
            }
        }
    }

    pub fn base_url(&self) -> String {
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

