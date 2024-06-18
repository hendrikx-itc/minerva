use std::env;

use rustls::ClientConfig as RustlsClientConfig;

use tokio_postgres::{config::SslMode, Config};
use tokio_postgres::{Client, NoTls};
use tokio_postgres_rustls::MakeRustlsConnect;

use serde::{Deserialize, Serialize};

use super::error::{ConfigurationError, Error};

static ENV_DB_CONN: &str = "MINERVA_DB_CONN";

#[derive(Serialize, Deserialize, Debug)]
pub struct Node {
    pub address: String,
    pub port: u16,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct ClusterConfig {
    pub nodes: Vec<Node>,
}

pub fn get_db_config() -> Result<Config, Error> {
    let config = match env::var(ENV_DB_CONN) {
        Ok(value) => Config::new().options(&value).clone(),
        Err(_) => {
            // No single environment variable set, let's check for psql settings
            let port: u16 = env::var("PGPORT").unwrap_or("5432".into()).parse().unwrap();
            let mut config = Config::new();

            let env_sslmode = env::var("PGSSLMODE").unwrap_or("prefer".into());

            let sslmode = match env_sslmode.to_lowercase().as_str() {
                "disable" => SslMode::Disable,
                "prefer" => SslMode::Prefer,
                "require" => SslMode::Require,
                _ => {
                    return Err(Error::Configuration(ConfigurationError {
                        msg: format!("Unsupported SSL mode '{}'", &env_sslmode),
                    }))
                }
            };

            let default_user_name = env::var("USER").unwrap_or("postgres".into());

            let config = config
                .host(&env::var("PGHOST").unwrap_or("/var/run/postgresql".into()))
                .port(port)
                .user(&env::var("PGUSER").unwrap_or(default_user_name))
                .dbname(&env::var("PGDATABASE").unwrap_or("postgres".into()))
                .ssl_mode(sslmode);

            let pg_password = env::var("PGPASSWORD");

            match pg_password {
                Ok(password) => config.password(password).clone(),
                Err(_) => config.clone(),
            }
        }
    };

    Ok(config)
}

pub async fn connect_db() -> Result<Client, Error> {
    connect_to_db(&get_db_config()?).await
}

pub async fn connect_to_db(config: &Config) -> Result<Client, Error> {
    let client = if config.get_ssl_mode() != SslMode::Disable {
        let roots = rustls::RootCertStore::empty();

        // Todo: Add certificate loading

        let tls_config = RustlsClientConfig::builder()
            .with_root_certificates(roots)
            .with_no_client_auth();
        let tls = MakeRustlsConnect::new(tls_config);

        let (client, connection) = config.connect(tls).await.map_err(|e| {
            ConfigurationError::from_msg(format!(
                "Could not setup TLS database connection to {:?}: {}",
                &config, e
            ))
        })?;

        tokio::spawn(async move {
            if let Err(e) = connection.await {
                eprintln!("connection error: {e}");
            }
        });

        client
    } else {
        let (client, connection) = config.connect(NoTls).await?;

        tokio::spawn(async move {
            if let Err(e) = connection.await {
                eprintln!("connection error: {e}");
            }
        });

        client
    };

    Ok(client)
}

pub async fn create_database<'a>(
    client: &'a mut Client,
    database_name: &str,
) -> Result<(), String> {
    let query = format!("CREATE DATABASE \"{database_name}\"");

    client
        .execute(&query, &[])
        .await
        .map_err(|e| format!("Error creating database '{database_name}': {e}"))?;

    Ok(())
}

pub async fn drop_database<'a>(client: &'a mut Client, database_name: &str) -> Result<(), String> {
    let query = format!("DROP DATABASE IF EXISTS \"{database_name}\"");

    client
        .execute(&query, &[])
        .await
        .map_err(|e| format!("Error dropping database '{database_name}': {e}"))?;

    Ok(())
}
