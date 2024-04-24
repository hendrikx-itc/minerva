use async_trait::async_trait;
use std::path::PathBuf;
use clap::Parser;

use minerva::error::ConfigurationError;
use minerva::loading::{load_data, ParserConfig, TrendsFrom, TrendsFromHeader};

use super::common::{connect_db, Cmd, CmdResult};

static NULL_VALUE: &str = "";

#[derive(Debug, Parser, PartialEq)]
pub struct LoadDataOpt {
    #[arg(long, help = "Data source of data")]
    data_source: Option<String>,
    #[arg(long, help = "File with parser configuration")]
    parser_config: Option<PathBuf>,
    #[arg(long, help = "Create partitions for timestamps in data")]
    create_partitions: bool,
    #[arg(help = "File to load")]
    file: PathBuf,
}

#[async_trait]
impl Cmd for LoadDataOpt {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let parser_config: ParserConfig = match &self.parser_config {
            None => ParserConfig {
                entity_type: "node".into(),
                granularity: "15m".into(),
                trends: TrendsFrom::Header(TrendsFromHeader {
                    entity_column: String::from("node"),
                    timestamp_column: String::from("timestamp"),
                }),
                extra: None,
                null_value: NULL_VALUE.to_string(),
            },
            Some(path) => {
                let config_file = std::fs::File::open(path)
                    .map_err(|e| ConfigurationError::from_msg(format!("{}", e)))?;
                serde_json::from_reader(config_file).unwrap()
            }
        };

        let data_source = match &self.data_source {
            None => "minerva-admin".to_string(),
            Some(d) => d.to_string(),
        };

        let result = load_data(
            &mut client,
            &data_source,
            &parser_config,
            &self.file,
            self.create_partitions,
        )
        .await;

        match result {
            Err(e) => {
                println!(
                    "Could not load CSV file '{}': {}",
                    &self.file.as_path().to_string_lossy(),
                    e
                );
            }
            Ok(_) => {
                println!(
                    "Finished processing file '{}'",
                    &self.file.as_path().to_string_lossy()
                )
            }
        }

        Ok(())
    }
}
