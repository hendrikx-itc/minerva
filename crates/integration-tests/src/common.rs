use std::net::{Ipv4Addr, SocketAddr, SocketAddrV4, TcpListener};

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

