use std::env;
use std::io;
use std::io::Write;
use std::path::PathBuf;

use async_trait::async_trait;
use dialoguer::Confirm;
use clap::Parser;

use tokio_postgres::Client;

use minerva::error::{ConfigurationError, Error, RuntimeError};
use minerva::instance::MinervaInstance;

use super::common::{connect_db, Cmd, CmdResult, ENV_MINERVA_INSTANCE_ROOT};

#[derive(Debug, Parser, PartialEq)]
pub struct UpdateOpt {
    #[arg(short, long)]
    non_interactive: bool,
    #[arg(help = "Minerva instance root directory")]
    instance_root: Option<PathBuf>,
}

#[async_trait]
impl Cmd for UpdateOpt {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        print!("Reading Minerva instance from database... ");
        io::stdout().flush().unwrap();
        let instance_db = MinervaInstance::load_from_db(&mut client).await?;
        println!("Ok");

        let minerva_instance_root = match &self.instance_root {
            Some(root) => {
                // Next to passing on the Minerva instance root directory, we need to set the
                // environment variable for any child processes that might be started during
                // initialization.
                std::env::set_var(&ENV_MINERVA_INSTANCE_ROOT, &root);

                root.clone()
            }
            None => match env::var(ENV_MINERVA_INSTANCE_ROOT) {
                Ok(v) => PathBuf::from(v),
                Err(e) => {
                    return Err(Error::Configuration(ConfigurationError {
                        msg: format!(
                            "Environment variable '{}' could not be read: {}",
                            &ENV_MINERVA_INSTANCE_ROOT, e
                        ),
                    }));
                }
            },
        };

        print!(
            "Reading Minerva instance from '{}'... ",
            &minerva_instance_root.to_string_lossy()
        );
        io::stdout().flush().unwrap();
        let instance_def = MinervaInstance::load_from(&minerva_instance_root);
        println!("Ok");

        update(
            &mut client,
            &instance_db,
            &instance_def,
            !self.non_interactive,
        )
        .await
    }
}

async fn update(
    client: &mut Client,
    db_instance: &MinervaInstance,
    other: &MinervaInstance,
    interactive: bool,
) -> CmdResult {
    let changes = db_instance.diff(other);

    println!("Applying changes:");

    for change in changes {
        println!("* {change}");

        if (!interactive)
            || Confirm::new()
                .with_prompt("Apply change?")
                .interact()
                .map_err(|e| {
                    Error::Runtime(RuntimeError {
                        msg: format!("Could not process input: {e}"),
                    })
                })?
        {
            match change.apply(client).await {
                Ok(message) => println!("> {}", &message),
                Err(err) => println!("! Error applying change: {}", &err),
            }
        }
    }

    Ok(())
}
