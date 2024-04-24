use async_trait::async_trait;
use clap::Parser;

use minerva::schema::schema;

use super::common::{Cmd, CmdResult};

#[derive(Debug, Parser, PartialEq)]
pub struct SchemaOpt {}

#[async_trait]
impl Cmd for SchemaOpt {
    async fn run(&self) -> CmdResult {
        print!("{}", schema());

        Ok(())
    }
}
