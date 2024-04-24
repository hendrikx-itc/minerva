use std::env;
use std::fs::File;
use std::io::BufReader;
use std::path::PathBuf;

use async_trait::async_trait;
use clap::Parser;

use minerva::database::{create_database, ClusterConfig};
use minerva::error::{ConfigurationError, Error};
use minerva::instance::MinervaInstance;
use minerva::schema::create_schema;
use minerva::trend_store::create_partitions;

use super::common::{
    connect_db, connect_to_db, get_db_config, Cmd, CmdResult, ENV_MINERVA_INSTANCE_ROOT,
};

#[derive(Debug, Parser, PartialEq)]
pub struct InitializeOpt {
    #[arg(long = "create-schema", help = "create Minerva schema")]
    create_schema: bool,
    #[arg(long = "create-database", help = "create Minerva database")]
    database_name: Option<String>,
    #[arg(long = "create-partitions", help = "create partitions")]
    create_partitions: bool,
    #[arg(
        long = "with-definition",
        help = "Minerva instance definition root directory"
    )]
    instance_root: Option<PathBuf>,
}

#[async_trait]
impl Cmd for InitializeOpt {
    async fn run(&self) -> CmdResult {
        let minerva_instance_root: Option<PathBuf> = match &self.instance_root {
            Some(root) => Some(root.clone()),
            None => match env::var(ENV_MINERVA_INSTANCE_ROOT) {
                Ok(v) => Some(PathBuf::from(v)),
                Err(_) => None,
            },
        };

        let mut client = connect_db().await?;

        if let Some(database_name) = &self.database_name {
            // A new database must be created
            create_database(&mut client, &database_name)
                .await
                .map_err(|e| {
                    Error::Database(minerva::error::DatabaseError::from_msg(format!(
                        "Could not create database '{}': {e}",
                        &database_name
                    )))
                })?;

            // Let connection use newly created database, because the current connection is to a
            // different database.
            let mut config = get_db_config()?;
            config.dbname(database_name);
            client = connect_to_db(&config).await?;

            std::env::set_var("PGDATABASE", &database_name);
        }

        if self.create_schema {
            create_schema(&mut client).await.map_err(|e| {
                Error::Database(minerva::error::DatabaseError::from_msg(format!(
                    "Could not create schema: {e}"
                )))
            })?;
        }

        let mut cluster_config_path = PathBuf::from(minerva_instance_root.clone().unwrap());
        cluster_config_path.push("cluster_config.yaml");
        let cluster_config = match File::open(&cluster_config_path) {
            Ok(cluster_config_file) => {
                let reader = BufReader::new(cluster_config_file);
                let cluster_config: ClusterConfig = serde_yaml::from_reader(reader).unwrap();

                Some(cluster_config)
            }
            Err(e) => {
                println!(
                    "Could not open cluster config file'{}': {e}",
                    cluster_config_path.display()
                );
                None
            }
        };

        if let Some(c) = cluster_config {
            let query = format!("SELECT * FROM citus_add_node($1, $2)");

            for node in c.nodes {
                client
                    .execute(&query, &[&node.address, &(node.port as i32)])
                    .await
                    .map_err(|e| format!("Error adding node to cluster: {e}"))?;
            }
        }

        if let Some(root) = minerva_instance_root {
            if !root.is_dir() {
                return Err(Error::Configuration(ConfigurationError::from_msg(format!(
                    "Not a valid directory: '{}'",
                    &root.to_string_lossy()
                ))));
            }

            println!(
                "Initializing Minerva instance from {}",
                root.to_string_lossy()
            );

            // We need to set the environment variable for any child processes that might be
            // started during initialization.
            std::env::set_var(&ENV_MINERVA_INSTANCE_ROOT, &root);

            MinervaInstance::load_from(&root)
                .initialize(&mut client)
                .await;
        }

        if self.create_partitions {
            create_partitions(&mut client, None).await?;
        }

        Ok(())
    }
}
