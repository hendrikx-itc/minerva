use async_trait::async_trait;
use clap::Parser;

use minerva::instance::dump;

use super::common::{connect_db, Cmd, CmdResult};

#[derive(Debug, Parser, PartialEq)]
pub struct DumpOpt {}

#[async_trait]
impl Cmd for DumpOpt {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        dump(&mut client).await;

        Ok(())
    }
}
