use std::{env, process::exit};

use log::info;

use actix_cors::Cors;
use actix_web::{middleware::Logger, web, App, HttpServer};

use deadpool_postgres::{Manager, ManagerConfig, Pool, RecyclingMethod};
use rustls::ClientConfig as RustlsClientConfig;
use tokio_postgres::{config::SslMode, Config};
use tokio_postgres_rustls::MakeRustlsConnect;

use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

use minerva::error::{ConfigurationError, DatabaseError, Error};

mod trendmaterialization;
use trendmaterialization::{
    delete_trend_function_materialization, delete_trend_view_materialization,
    get_trend_function_materialization, get_trend_function_materializations,
    get_trend_materializations, get_trend_view_materialization, get_trend_view_materializations,
    post_trend_function_materialization, post_trend_view_materialization,
    update_trend_function_materialization, update_trend_view_materialization,
    TrendFunctionMaterializationData, TrendFunctionMaterializationFull, TrendMaterializationDef,
    TrendMaterializationSourceData, TrendViewMaterializationData, TrendViewMaterializationFull,
};

mod trendstore;
use trendstore::{
    find_trend_store_part, get_trend_store, get_trend_store_part, get_trend_store_parts,
    get_trend_stores, get_trends, get_trends_by_entity_type, post_trend_store_part,
    GeneratedTrendFull, TrendFull, TrendStoreFull, TrendStorePartFull,
};

mod datasource;
use datasource::{get_data_source, get_data_sources, DataSource};

mod entitytype;
use entitytype::{get_entity_type, get_entity_types, EntityType};

mod kpi;
use kpi::{delete_kpi, get_kpi, get_kpis, post_kpi, update_kpi, KpiImplementedData, KpiRawData};

mod trigger;
use trigger::{change_thresholds, get_triggers, TriggerData};

mod entityset;
use entityset::{get_entity_sets, change_entity_set, create_entity_set, EntitySetData};

mod header;
use header::get_header;

mod error;
mod serviceerror;

static ENV_DB_CONN: &str = "MINERVA_DB_CONN";
static ENV_PORT: &str = "SERVICE_PORT";
static ENV_ADDRESS: &str = "SERVICE_ADDRESS";

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    rustls::crypto::ring::default_provider().install_default().expect("Failed to install rustls crypto provider");
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    #[derive(OpenApi)]
    #[openapi(
        paths(
            trendmaterialization::get_trend_view_materializations,
            trendmaterialization::get_trend_view_materialization,
            trendmaterialization::get_trend_function_materializations,
            trendmaterialization::get_trend_function_materialization,
            trendmaterialization::get_trend_materializations,
            trendmaterialization::post_trend_view_materialization,
            trendmaterialization::post_trend_function_materialization,
            trendmaterialization::delete_trend_view_materialization,
            trendmaterialization::delete_trend_function_materialization,
            trendmaterialization::update_trend_function_materialization,
            trendmaterialization::update_trend_view_materialization,
            trendstore::get_trend_store_parts,
            trendstore::get_trend_store_part,
            trendstore::find_trend_store_part,
            trendstore::get_trend_stores,
            trendstore::get_trend_store,
            trendstore::post_trend_store_part,
            trendstore::get_trends,
            trendstore::get_trends_by_entity_type,
            datasource::get_data_sources,
            datasource::get_data_source,
            entitytype::get_entity_types,
            entitytype::get_entity_type,
            kpi::get_kpis,
            kpi::post_kpi,
            kpi::update_kpi,
            kpi::get_kpi,
            kpi::delete_kpi,
            trigger::get_triggers,
            trigger::change_thresholds,
            entityset::get_entity_sets,
            entityset::change_entity_set,
            entityset::create_entity_set,
            header::get_header
        ),
        components(
            schemas(
                TrendMaterializationSourceData, TrendMaterializationDef,
                TrendViewMaterializationFull, TrendFunctionMaterializationFull,
                TrendViewMaterializationData, TrendFunctionMaterializationData,
                TrendFull, GeneratedTrendFull, TrendStorePartFull, TrendStoreFull,
                DataSource, EntityType, KpiRawData, KpiImplementedData,
                TriggerData, EntitySetData,
            )
        ),
        tags(
            (name = "Trend Materialization", description = "Trend materialization management endpoints.")
        ),
    )]
    struct ApiDoc;

    let service_address: String = env::var(ENV_ADDRESS).unwrap_or("0.0.0.0".to_string());

    let service_port: u16 = match env::var(ENV_PORT).unwrap_or("8000".to_string()).parse() {
        Err(e) => {
            println!("Could not parse service port value '{ENV_PORT}': {e}");
            exit(-1);
        }
        Ok(value) => value,
    };

    let pool = connect_db().await.unwrap();

    let openapi = ApiDoc::openapi();

    info!("Listening on {service_address}:{service_port}");

    HttpServer::new(move || {
        let cors = Cors::permissive()
            .allowed_methods(vec!["GET", "POST", "PUT", "DELETE"])
            .max_age(3600);
        App::new()
            .wrap(cors)
            .wrap(Logger::default())
            .app_data(web::Data::new(pool.clone()))
            .service(
                SwaggerUi::new("/swagger-ui/{_:.*}").url("/api-doc/openapi.json", openapi.clone()),
            )
            .service(get_trend_view_materializations)
            .service(get_trend_view_materialization)
            .service(get_trend_function_materializations)
            .service(get_trend_function_materialization)
            .service(get_trend_materializations)
            .service(post_trend_view_materialization)
            .service(post_trend_function_materialization)
            .service(delete_trend_view_materialization)
            .service(delete_trend_function_materialization)
            .service(update_trend_function_materialization)
            .service(update_trend_view_materialization)
            .service(get_trend_store_parts)
            .service(get_trend_store_part)
            .service(find_trend_store_part)
            .service(post_trend_store_part)
            .service(get_trend_stores)
            .service(get_trend_store)
            .service(get_trends)
            .service(get_trends_by_entity_type)
            .service(get_data_sources)
            .service(get_data_source)
            .service(get_entity_types)
            .service(get_entity_type)
            .service(get_kpis)
            .service(post_kpi)
            .service(update_kpi)
            .service(get_kpi)
            .service(delete_kpi)
            .service(get_triggers)
            .service(change_thresholds)
            .service(get_entity_sets)
            .service(change_entity_set)
            .service(create_entity_set)
            .service(get_header)
    })
    .bind((service_address, service_port))?
    .run()
    .await
}

fn get_db_config() -> Result<Config, Error> {
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

fn show_config(config: &Config) -> String {
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

async fn connect_db() -> Result<Pool, Error> {
    let config = get_db_config()?;

    let config_repr = show_config(&config);

    info!("Connecting to database: {}", &config_repr);

    make_db_pool(&config).await
}

//async fn connect_to_db(
//    config: &Config,
//) -> Result<bb8::Pool<PostgresConnectionManager<MakeRustlsConnect>>, Error> {
//    let mut roots = rustls::RootCertStore::empty();
//
//    for cert in rustls_native_certs::load_native_certs().expect("could not load platform certs")
//    {
//        roots.add(&rustls::Certificate(cert.0)).unwrap();
//    }
//
//    let tls_config = RustlsClientConfig::builder()
//        .with_safe_defaults()
//        .with_root_certificates(roots)
//        .with_no_client_auth();
//    let tls = MakeRustlsConnect::new(tls_config);
//    let manager = PostgresConnectionManager::new(config.clone(), tls);
//
//    let pool = bb8::Pool::builder().build(manager).await.unwrap();
//
//    Ok(pool)
//}

async fn make_db_pool(config: &Config) -> Result<Pool, Error> {
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
        .map_err(|_| Error::Database(DatabaseError::from_msg("test".to_string())))
}
