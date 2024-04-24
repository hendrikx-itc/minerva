use std::env;
use std::path::PathBuf;

use async_trait::async_trait;
use clap::Parser;

use minerva::error::{ConfigurationError, Error};
use minerva::instance::MinervaInstance;

use super::common::{connect_to_db, get_db_config, Cmd, CmdResult, ENV_MINERVA_INSTANCE_ROOT};

#[derive(Debug, Parser, PartialEq)]
pub struct DiffOpt {
    #[structopt(
        long = "with-dir",
        help = "compare with other Minerva instance directory"
    )]
    with_dir: Option<PathBuf>,
}

#[async_trait]
impl Cmd for DiffOpt {
    async fn run(&self) -> CmdResult {
        let minerva_instance_root = match env::var(ENV_MINERVA_INSTANCE_ROOT) {
            Ok(v) => PathBuf::from(v),
            Err(e) => {
                return Err(Error::Configuration(ConfigurationError {
                    msg: format!(
                        "Environment variable '{}' could not be read: {}",
                        &ENV_MINERVA_INSTANCE_ROOT, e
                    ),
                }));
            }
        };

        let from_instance_descr = format!("dir('{}')", minerva_instance_root.to_string_lossy());
        let to_instance_descr: String;

        let instance_def = MinervaInstance::load_from(&minerva_instance_root);

        let other_instance = match &self.with_dir {
            Some(with_dir) => {
                to_instance_descr = format!("dir('{}')", with_dir.to_string_lossy());
                MinervaInstance::load_from(with_dir)
            }
            None => {
                let db_config = get_db_config()?;

                to_instance_descr = format!("database('{db_config:?}')");

                let mut client = connect_to_db(&db_config).await?;

                MinervaInstance::load_from_db(&mut client).await?
            }
        };

        let changes = other_instance.diff(&instance_def);

        if !changes.is_empty() {
            println!("Differences {from_instance_descr} -> {to_instance_descr}");

            for change in changes {
                println!("* {}", &change);
            }
        } else {
            println!("Database is up-to-date");
        }

        Ok(())
    }
}
