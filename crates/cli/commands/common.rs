use std::env;

use async_trait::async_trait;

use rustls::ClientConfig as RustlsClientConfig;
use tokio;
use tokio_postgres::{config::SslMode, Config};
use tokio_postgres::{Client, NoTls};
use tokio_postgres_rustls::MakeRustlsConnect;

use minerva::error::{ConfigurationError, Error};

pub type CmdResult = Result<(), Error>;

pub static ENV_MINERVA_INSTANCE_ROOT: &str = "MINERVA_INSTANCE_ROOT";
static ENV_DB_CONN: &str = "MINERVA_DB_CONN";

/// Defines the interface for CLI commands
#[async_trait]
pub trait Cmd {
    async fn run(&self) -> CmdResult;
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
        let mut roots = rustls::RootCertStore::empty();

        for cert in rustls_native_certs::load_native_certs().expect("could not load platform certs")
        {
            roots.add(&rustls::Certificate(cert.0)).unwrap();
        }

        let tls_config = RustlsClientConfig::builder()
            .with_safe_defaults()
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
