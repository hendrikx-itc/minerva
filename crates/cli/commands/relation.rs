use std::path::PathBuf;

use async_trait::async_trait;

use minerva::relation::{
    AddRelation, load_relation_from_file,
};
use minerva::change::Change;

use clap::{Parser, Subcommand};

use super::common::{connect_db, Cmd, CmdResult};

#[derive(Debug, Parser, PartialEq)]
pub struct RelationCreate {
    #[structopt(help = "trigger definition file")]
    definition: PathBuf,
}

#[async_trait]
impl Cmd for RelationCreate {
    async fn run(&self) -> CmdResult {
        let relation = load_relation_from_file(&self.definition)?;

        println!("Loaded definition, creating trigger");

        let mut client = connect_db().await?;

        let change = AddRelation {
            relation
        };

        let message = change.apply(&mut client).await?;

        println!("{message}");

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct RelationOpt {
    #[command(subcommand)]
    command: RelationOptCommands
}

#[derive(Debug, Subcommand, PartialEq)]
pub enum RelationOptCommands {
    #[command(about = "create a relation")]
    Create(RelationCreate),
}

impl RelationOpt {
    pub async fn run(&self) -> CmdResult {
        match &self.command {
            RelationOptCommands::Create(create) => create.run().await,
        }
    }
}
