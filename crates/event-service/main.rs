use log::{debug, error, info};
use reqwest::{
    header::{ACCEPT, CONTENT_TYPE},
    Client, Method,
};
use std::env;
use std::fmt;
use std::thread::sleep;
use std::time::{Duration, SystemTime};

use chrono::{DateTime, Local, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;

use deadpool_postgres::{Manager, ManagerConfig, Pool, RecyclingMethod};
use rustls::ClientConfig as RustlsClientConfig;
use tokio_postgres::{config::SslMode, Config as TokioConfig, Row};
use tokio_postgres_rustls::MakeRustlsConnect;

static ENV_DB_CONN: &str = "MINERVA_DB_CONN";

#[derive(Debug, Serialize, Deserialize, Clone)]
struct NotificationData {
    id: i32,
    timestamp: String,
    rule: String,
    entity: String,
    details: String,
    data: Value,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Notification {
    id: i32,
    #[serde(with = "humantime_serde")]
    timestamp: SystemTime,
    rule: String,
    entity: String,
    details: String,
    data: Value,
}

#[derive(Clone)]
pub struct Config {
    identity: String,
    notification_store: String,
    sleeptime: Duration,
    max_notifications: i32,
    http_endpoint: String,
    method: Method,
}

fn get_config() -> Config {
    let sleep_seconds = env::var("SLEEP")
        .unwrap_or("10".to_string())
        .parse::<u64>()
        .unwrap();

    Config {
        identity: env::var("IDENTITY").unwrap_or("customer".to_string()),
        notification_store: env::var("NOTIFICATIONSTORE")
            .unwrap_or("trigger-notification".to_string()),
        sleeptime: Duration::new(sleep_seconds, 0),
        max_notifications: env::var("MAXNOTIFICATIONS")
            .unwrap_or("100".to_string())
            .parse::<i32>()
            .unwrap(),
        http_endpoint: env::var("ENDPOINT")
            .unwrap_or("http://localhost:8000/notifications".to_string()),
        method: Method::from_bytes(
            &env::var("METHOD")
                .unwrap_or("POST".to_string())
                .into_bytes(),
        )
        .unwrap(),
    }
}

fn notification_from_data(data: NotificationData) -> Notification {
    Notification {
        id: data.id,
        timestamp: DateTime::parse_from_str(&data.timestamp, "%Y-%m-%d %H:%M:%S%.6f%#z")
            .unwrap()
            .into(),
        rule: data.rule,
        entity: data.entity,
        details: data.details,
        data: data.data,
    }
}

impl fmt::Display for Notification {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let date: DateTime<Utc> = self.timestamp.into();
        write!(
            f,
            "Notification: rule {} for entity {} at {}",
            &self.rule, &self.entity, date,
        )
    }
}

fn get_db_config() -> Result<TokioConfig, String> {
    let config = match env::var(ENV_DB_CONN) {
        Ok(value) => TokioConfig::new().options(&value).clone(),
        Err(_) => {
            // No single environment variable set, let's check for psql settings
            let port: u16 = env::var("PGPORT").unwrap_or("5432".into()).parse().unwrap();
            let mut config = TokioConfig::new();

            let env_sslmode = env::var("PGSSLMODE").unwrap_or("prefer".into());

            let sslmode = match env_sslmode.to_lowercase().as_str() {
                "disable" => SslMode::Disable,
                "prefer" => SslMode::Prefer,
                "require" => SslMode::Require,
                _ => return Err(format!("Unsupported SSL mode '{}'", &env_sslmode)),
            };

            let config = config
                .host(&env::var("PGHOST").unwrap_or("localhost".into()))
                .port(port)
                .user(&env::var("PGUSER").unwrap_or("postgres".into()))
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

fn show_config(config: &TokioConfig) -> String {
    let hosts = config.get_hosts();

    let host = match &hosts[0] {
        tokio_postgres::config::Host::Tcp(tcp_host) => tcp_host.clone(),
        tokio_postgres::config::Host::Unix(socket_path) => {
            socket_path.to_string_lossy().to_string()
        }
    };

    let port = config.get_ports()[0];

    let dbname = config.get_dbname().unwrap_or("");

    let sslmode = match config.get_ssl_mode() {
        SslMode::Prefer => "prefer".to_string(),
        SslMode::Disable => "disable".to_string(),
        SslMode::Require => "require".to_string(),
        _ => "<UNSUPPORTED MODE>".to_string(),
    };

    format!(
        "host={} port={} user={} dbname={} sslmode={}",
        &host,
        &port,
        config.get_user().unwrap_or(""),
        dbname,
        sslmode
    )
}

async fn connect_db() -> Result<Pool, String> {
    let config = get_db_config()?;

    let config_repr = show_config(&config);

    info!("Connecting to database: {}", &config_repr);

    make_db_pool(&config).await
}

async fn make_db_pool(config: &TokioConfig) -> Result<Pool, String> {
    let mut roots = rustls::RootCertStore::empty();

    for cert in rustls_native_certs::load_native_certs().expect("could not load platform certs") {
        roots.add(cert).unwrap();
    }

    let tls_config = RustlsClientConfig::builder()
        .with_root_certificates(roots)
        .with_no_client_auth();
    let tls = MakeRustlsConnect::new(tls_config);
    let mgr_config = ManagerConfig {
        recycling_method: RecyclingMethod::Fast,
    };
    let mgr = Manager::from_config(config.clone(), tls, mgr_config);

    Pool::builder(mgr)
        .max_size(16)
        .build()
        .map_err(|e| format!("Pool Error: {e}"))
}

async fn post_message(client: &Client, data: &Notification) -> Result<String, String> {
    let config = get_config();
    let result = client
        .request(config.method, config.http_endpoint)
        .header(CONTENT_TYPE, "application/json")
        .header(ACCEPT, "text/plain")
        .json(&data)
        .send()
        .await;
    match result {
        Ok(res) => {
            let finalres = res.text().await;
            match finalres {
                Ok(res) => Ok(res),
                Err(e) => Err(e.to_string()),
            }
        }
        Err(e) => Err(e.to_string()),
    }
}

#[tokio::main]
async fn main() {
    env_logger::init();

    rustls::crypto::ring::default_provider()
        .install_default()
        .expect("Failed to install rustls crypto provider");
    let config = get_config();
    let pool = connect_db().await.unwrap();
    let mut client = pool.get().await.unwrap();
    let httpclient = Client::new();
    let transaction = client.transaction().await.unwrap();
    let result = transaction
        .query_one(
            "SELECT notification_directory.get_last_notification($1, $2)",
            &[&config.identity, &config.notification_store],
        )
        .await
        .unwrap();
    let mut last_notification: i32 = result.get(0);
    transaction.commit().await.unwrap();

    loop {
        let transaction = client.transaction().await.unwrap();
        let result: Vec<Row> = match last_notification {
            -1 => transaction.query(
                "SELECT id, timestamp::text, rule, entity, details, data FROM notification_directory.get_last_notifications($1, $2)",
                &[&config.notification_store, &config.max_notifications]
            )
            .await
            .unwrap(),
            _ => transaction.query(
                "SELECT id, timestamp::text, rule, entity, details, data FROM notification_directory.get_next_notifications($1, $2, $3)",
                &[&config.notification_store, &last_notification, &config.max_notifications]
            )
            .await
            .unwrap()
        };

        let mut missed_notification = -1;

        if !result.is_empty() {
            info!(
                "{}: {} notifications received.",
                Local::now().format("%Y-%m-%d %H:%M:%S"),
                result.len()
            );

            for row in result {
                let notification_data = NotificationData {
                    id: row.get(0),
                    timestamp: row.get(1),
                    rule: row.get(2),
                    entity: row.get(3),
                    details: row.get(4),
                    data: row.get(5),
                };
                let notification = notification_from_data(notification_data);

                debug!(
                    "{}: received notification {}",
                    Local::now().format("%Y-%m-%d %H:%M:%S"),
                    notification
                );

                let httpresult = post_message(&httpclient, &notification);
                match httpresult.await {
                    Ok(_) => {
                        debug!("Notification sent on.");

                        if notification.id > last_notification {
                            last_notification = notification.id;
                        }
                    }
                    Err(e) => {
                        error!(
                            "{}: Sending of notification {} failed: {}",
                            Local::now().format("%Y-%m-%d %H:%M:%S"),
                            notification,
                            e
                        );

                        if missed_notification == -1 || notification.id < missed_notification {
                            missed_notification = notification.id;
                        }
                    }
                }
            }
        } else {
            info!(
                "{}: no new notifications received.",
                Local::now().format("%Y-%m-%d %H:%M:%S")
            )
        }
        if missed_notification > -1 && missed_notification <= last_notification {
            last_notification = missed_notification - 1;
        }
        if last_notification > -1 {
            transaction
                .execute(
                    "SELECT notification_directory.set_last_notification($1, $2, $3)",
                    &[
                        &config.identity,
                        &config.notification_store,
                        &last_notification,
                    ],
                )
                .await
                .unwrap();
        }
        transaction.commit().await.unwrap();
        debug!("Sleeping for {} seconds", config.sleeptime.as_secs());
        sleep(config.sleeptime);
    }
}
