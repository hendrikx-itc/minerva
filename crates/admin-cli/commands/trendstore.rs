use std::path::PathBuf;
use std::time::Duration;

use chrono::DateTime;
use chrono::FixedOffset;

use async_trait::async_trait;
use structopt::StructOpt;

use term_table::{
    row::Row,
    table_cell::{Alignment, TableCell},
    Table, TableStyle,
};

use minerva::change::Change;
use minerva::error::{Error, RuntimeError};
use minerva::trend_store::{
    analyze_trend_store_part, create_partitions, create_partitions_for_timestamp,
    delete_trend_store, list_trend_stores, load_trend_store, load_trend_store_from_file,
    AddTrendStore,
};

use super::common::{connect_db, Cmd, CmdResult};

#[derive(Debug, StructOpt)]
pub struct DeleteOpt {
    id: i32,
}

#[derive(Debug, StructOpt)]
pub struct TrendStoreCreate {
    #[structopt(help = "trend store definition file")]
    definition: PathBuf,
}

#[async_trait]
impl Cmd for TrendStoreCreate {
    async fn run(&self) -> CmdResult {
        let trend_store = load_trend_store_from_file(&self.definition)?;

        println!("Loaded definition, creating trend store");

        let mut client = connect_db().await?;

        let change = AddTrendStore { trend_store };

        change.apply(&mut client).await?;

        println!("Created trend store");

        Ok(())
    }
}

#[derive(Debug, StructOpt)]
pub struct TrendStoreDiff {
    #[structopt(help = "trend store definition file")]
    definition: PathBuf,
}

#[async_trait]
impl Cmd for TrendStoreDiff {
    async fn run(&self) -> CmdResult {
        let trend_store = load_trend_store_from_file(&self.definition)?;

        let mut client = connect_db().await?;

        let result = load_trend_store(
            &mut client,
            &trend_store.data_source,
            &trend_store.entity_type,
            &trend_store.granularity,
        )
        .await;

        match result {
            Ok(trend_store_db) => {
                let changes = trend_store_db.diff(&trend_store);

                if !changes.is_empty() {
                    println!("Differences with the database");

                    for change in changes {
                        println!("{}", &change);
                    }
                } else {
                    println!("Trend store already up-to-date")
                }

                Ok(())
            }
            Err(e) => Err(Error::Runtime(RuntimeError {
                msg: format!("Error loading trend store: {}", e),
            })),
        }
    }
}

#[derive(Debug, StructOpt)]
pub struct TrendStoreUpdate {
    #[structopt(help = "trend store definition file")]
    definition: PathBuf,
}

#[async_trait]
impl Cmd for TrendStoreUpdate {
    async fn run(&self) -> CmdResult {
        let trend_store = load_trend_store_from_file(&self.definition)?;

        let mut client = connect_db().await?;

        let result = load_trend_store(
            &mut client,
            &trend_store.data_source,
            &trend_store.entity_type,
            &trend_store.granularity,
        )
        .await;

        match result {
            Ok(trend_store_db) => {
                let changes = trend_store_db.diff(&trend_store);

                if !changes.is_empty() {
                    println!("Updating trend store");

                    for change in changes {
                        let apply_result = change.apply(&mut client).await;

                        match apply_result {
                            Ok(_) => {
                                println!("{}", &change);
                            }
                            Err(e) => {
                                println!("Error applying update: {}", e);
                            }
                        }
                    }
                } else {
                    println!("Trend store already up-to-date")
                }

                Ok(())
            }
            Err(e) => Err(Error::Runtime(RuntimeError {
                msg: format!("Error loading trend store: {}", e),
            })),
        }
    }
}

#[derive(Debug, StructOpt)]
pub struct TrendStorePartitionCreate {
    #[structopt(
        help="period for which to create partitions",
        long="--ahead-interval",
        parse(try_from_str = humantime::parse_duration)
    )]
    ahead_interval: Option<Duration>,
    #[structopt(
        help="timestamp for which to create partitions",
        long="--for-timestamp",
        parse(try_from_str = DateTime::parse_from_rfc3339)
    )]
    for_timestamp: Option<DateTime<FixedOffset>>,
}

#[derive(Debug, StructOpt)]
pub enum TrendStorePartition {
    #[structopt(about = "create partitions")]
    Create(TrendStorePartitionCreate),
}

#[derive(Debug, StructOpt)]
pub struct TrendStoreCheck {
    #[structopt(help = "trend store definition file")]
    definition: PathBuf,
}

#[derive(Debug, StructOpt)]
pub struct TrendStorePartAnalyze {
    #[structopt(help = "name of trend store part")]
    name: String,
}

#[async_trait]
impl Cmd for TrendStorePartAnalyze {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let result = analyze_trend_store_part(&mut client, &self.name).await?;

        println!("Analyzed '{}'", self.name);

        let mut table = Table::new();
        table.style = TableStyle::thin();
        table.separate_rows = false;

        table.add_row(Row::new(vec![
            TableCell::new("Name"),
            TableCell::new("Min"),
            TableCell::new("Max"),
        ]));

        for stat in result.trend_stats {
            table.add_row(Row::new(vec![
                TableCell::new(&stat.name),
                TableCell::new_with_alignment(
                    &stat.min_value.unwrap_or("N/A".into()),
                    1,
                    Alignment::Right,
                ),
                TableCell::new_with_alignment(
                    &stat.max_value.unwrap_or("N/A".into()),
                    1,
                    Alignment::Right,
                ),
            ]));
        }

        println!("{}", table.render());

        Ok(())
    }
}

#[derive(Debug, StructOpt)]
pub enum TrendStorePartOpt {
    #[structopt(about = "analyze range of values for trends in a trend store part")]
    Analyze(TrendStorePartAnalyze),
}

#[derive(Debug, StructOpt)]
pub enum TrendStoreOpt {
    #[structopt(about = "list existing trend stores")]
    List,
    #[structopt(about = "create a trend store")]
    Create(TrendStoreCreate),
    #[structopt(about = "show differences for a trend store")]
    Diff(TrendStoreDiff),
    #[structopt(about = "update a trend store")]
    Update(TrendStoreUpdate),
    #[structopt(about = "delete a trend store")]
    Delete(DeleteOpt),
    #[structopt(about = "partition management commands")]
    Partition(TrendStorePartition),
    #[structopt(about = "run sanity checks for trend store")]
    Check(TrendStoreCheck),
    #[structopt(about = "part management commands")]
    Part(TrendStorePartOpt),
}

impl TrendStoreOpt {
    pub async fn run(&self) -> CmdResult {
        match self {
            TrendStoreOpt::List => run_trend_store_list_cmd().await,
            TrendStoreOpt::Create(create) => create.run().await,
            TrendStoreOpt::Diff(diff) => diff.run().await,
            TrendStoreOpt::Update(update) => update.run().await,
            TrendStoreOpt::Delete(delete) => run_trend_store_delete_cmd(&delete).await,
            TrendStoreOpt::Partition(partition) => match partition {
                TrendStorePartition::Create(create) => {
                    run_trend_store_partition_create_cmd(&create).await
                }
            },
            TrendStoreOpt::Check(check) => run_trend_store_check_cmd(&check),
            TrendStoreOpt::Part(part) => match part {
                TrendStorePartOpt::Analyze(analyze) => analyze.run().await,
            },
        }
    }
}

fn run_trend_store_check_cmd(args: &TrendStoreCheck) -> CmdResult {
    let trend_store = load_trend_store_from_file(&args.definition)?;

    for trend_store_part in &trend_store.parts {
        let count = trend_store
            .parts
            .iter()
            .filter(|&p| p.name == trend_store_part.name)
            .count();

        if count > 1 {
            println!(
                "Error: {} trend store parts with name '{}'",
                count, &trend_store_part.name
            );
        }
    }

    Ok(())
}

async fn run_trend_store_partition_create_cmd(args: &TrendStorePartitionCreate) -> CmdResult {
    let mut client = connect_db().await?;

    if let Some(for_timestamp) = args.for_timestamp {
        create_partitions_for_timestamp(&mut client, for_timestamp).await?;
    } else {
        create_partitions(&mut client, args.ahead_interval).await?;
    }

    println!("Created partitions");
    Ok(())
}

async fn run_trend_store_list_cmd() -> CmdResult {
    let mut client = connect_db().await?;

    let trend_stores = list_trend_stores(&mut client).await.unwrap();

    for trend_store in trend_stores {
        println!("{}", &trend_store);
    }

    Ok(())
}

async fn run_trend_store_delete_cmd(args: &DeleteOpt) -> CmdResult {
    println!("Deleting trend store {}", args.id);

    let mut client = connect_db().await?;

    let result = delete_trend_store(&mut client, args.id).await;

    match result {
        Ok(_) => Ok(()),
        Err(e) => Err(Error::Runtime(RuntimeError {
            msg: format!("Error deleting trend store: {}", e),
        })),
    }
}