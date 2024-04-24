use std::path::PathBuf;
use std::time::Duration;

use chrono::DateTime;
use chrono::FixedOffset;

use async_trait::async_trait;
use dialoguer::Confirm;
use chrono::Utc;
use clap::Parser;

use clap::Subcommand;
use comfy_table;

use term_table::{
    row::Row,
    table_cell::{Alignment, TableCell},
    Table, TableStyle,
};

use minerva::change::Change;
use minerva::changes::trend_store::AddTrendStore;
use minerva::error::{Error, RuntimeError};
use minerva::trend_store::{
    analyze_trend_store_part, create_partitions, create_partitions_for_timestamp,
    delete_trend_store, list_trend_stores, load_trend_store, load_trend_store_from_file,
};

use super::common::{connect_db, Cmd, CmdResult};

#[derive(Debug, Parser, PartialEq)]
pub struct DeleteOpt {
    id: i32,
}

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStoreCreate {
    #[arg(help = "trend store definition file")]
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

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStoreDiff {
    #[arg(help = "trend store definition file")]
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
                msg: format!("Error loading trend store: {e}"),
            })),
        }
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStoreUpdate {
    #[arg(help = "trend store definition file")]
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
                        println!("* {change}");

                        if Confirm::new()
                                .with_prompt("Apply change?")
                                .interact()
                                .map_err(|e| {
                                    Error::Runtime(RuntimeError {
                                        msg: format!("Could not process input: {e}"),
                                    })
                                })?
                        {
                            let apply_result = change.apply(&mut client).await;

                            match apply_result {
                                Ok(_) => {
                                    println!("{}", &change);
                                }
                                Err(e) => {
                                    println!("Error applying update: {e}");
                                }
                            }
                        }
                    }
                } else {
                    println!("Trend store already up-to-date")
                }

                Ok(())
            }
            Err(e) => Err(Error::Runtime(RuntimeError {
                msg: format!("Error loading trend store: {e}"),
            })),
        }
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStorePartitionCreate {
    #[arg(
        help="period for which to create partitions",
        long="ahead-interval",
        value_parser=humantime::parse_duration
    )]
    ahead_interval: Option<Duration>,
    #[arg(
        help="timestamp for which to create partitions",
        long="for-timestamp",
        value_parser=DateTime::parse_from_rfc3339
    )]
    for_timestamp: Option<DateTime<FixedOffset>>,
}

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStorePartitionRemove {
    #[arg(help = "do not really remove the partitions", short, long)]
    pretend: bool,
}

#[async_trait]
impl Cmd for TrendStorePartitionRemove {
    async fn run(&self) -> CmdResult {
        let client = connect_db().await?;

        let total_partition_count_query = "SELECT count(*) FROM trend_directory.partition";

        let row = client.query_one(total_partition_count_query, &[]).await?;

        let total_partition_count: i64 = row.try_get(0)?;

        let old_partitions_query = concat!(
            "SELECT p.id, p.name, p.from, p.to ",
            "FROM trend_directory.partition p ",
            "JOIN trend_directory.trend_store_part tsp ON tsp.id = p.trend_store_part_id ",
            "JOIN trend_directory.trend_store ts ON ts.id = tsp.trend_store_id ",
            "WHERE p.from < (now() - retention_period - partition_size - partition_size) ",
            "ORDER BY p.name"
        );

        let rows = client.query(old_partitions_query, &[]).await?;

        println!(
            "Found {} of {} partitions to be removed",
            rows.len(),
            total_partition_count
        );

        for row in rows {
            let partition_id: i32 = row.try_get(0)?;
            let partition_name: &str = row.try_get(1)?;
            let data_from: DateTime<Utc> = row.try_get(2)?;
            let data_to: DateTime<Utc> = row.try_get(3)?;

            if self.pretend {
                println!(
                    "Would have removed partition '{}' ({} - {})",
                    partition_name, data_from, data_to
                );
            } else {
                let drop_query = format!("DROP TABLE trend_partition.\"{}\"", partition_name);
                client.execute(&drop_query, &[]).await?;

                let remove_entry_query = "DELETE FROM trend_directory.partition WHERE id = $1";
                client.execute(remove_entry_query, &[&partition_id]).await?;

                println!(
                    "Removed partition '{}' ({} - {})",
                    partition_name, data_from, data_to
                );
            }
        }

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStorePartition {
    #[command(subcommand)]
    command: TrendStorePartitionCommands
}

#[derive(Debug, Subcommand, PartialEq)]
pub enum TrendStorePartitionCommands {
    #[command(about = "create partitions")]
    Create(TrendStorePartitionCreate),
    #[command(about = "remove partitions")]
    Remove(TrendStorePartitionRemove),
}

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStoreCheck {
    #[arg(help = "trend store definition file")]
    definition: PathBuf,
}

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStoreRenameTrend {
    #[arg(help = "name of trend store part")]
    trend_store_part: String,
    #[arg(help = "current name")]
    from: String,
    #[arg(help = "new name")]
    to: String,
}

#[async_trait]
impl Cmd for TrendStoreRenameTrend {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let transaction = client.transaction().await?;

        let query = concat!(
            "UPDATE trend_directory.table_trend ",
            "SET name = $3 ",
            "FROM trend_directory.trend_store_part tsp ",
            "WHERE tsp.id = trend_store_part_id AND tsp.name = $1 AND table_trend.name = $2"
        );

        let update_count = transaction
            .execute(query, &[&self.trend_store_part, &self.from, &self.to])
            .await
            .map_err(|e| {
                Error::Runtime(RuntimeError {
                    msg: format!(
                        "Error renaming trend '{}' of trend store part '{}': {e}",
                        &self.from, &self.trend_store_part
                    ),
                })
            })?;

        if update_count == 0 {
            return Err(Error::Runtime(RuntimeError {
                msg: format!(
                    "No trend found matching trend store part name '{}' and name '{}'",
                    &self.trend_store_part, &self.from
                ),
            }));
        }

        transaction.commit().await?;

        println!(
            "Renamed {}.{} -> {}.{}",
            self.trend_store_part, self.from, self.trend_store_part, self.to
        );

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStorePartAnalyze {
    #[arg(help = "name of trend store part")]
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

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStorePartOpt {
    #[command(subcommand)]
    command: TrendStorePartOptCommands
}

#[derive(Debug, Subcommand, PartialEq)]
pub enum TrendStorePartOptCommands {
    #[command(about = "analyze range of values for trends in a trend store part")]
    Analyze(TrendStorePartAnalyze),
}

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStoreList {}

#[async_trait]
impl Cmd for TrendStoreList {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let trend_stores = list_trend_stores(&mut client).await.unwrap();

        let mut table = comfy_table::Table::new();
        let style = "     ═╪ ┆          ";
        table.load_preset(style);
        table.set_header(vec!["Id", "Data Source", "Entity Type", "Granularity"]);

        for trend_store in trend_stores {
            table.add_row(vec![
                trend_store.0.to_string(),
                trend_store.1,
                trend_store.2,
                trend_store.3,
            ]);
        }

        println!("{table}");

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStoreDeleteTimestamp {
    #[arg(
        help = "granularity for which to delete all data",
        long = "granularity"
    )]
    granularity: String,
    #[arg(
        help="timestamp for which to delete all data",
        value_parser=DateTime::parse_from_rfc3339
    )]
    timestamp: DateTime<FixedOffset>,
}

#[async_trait]
impl Cmd for TrendStoreDeleteTimestamp {
    async fn run(&self) -> CmdResult {
        let client = connect_db().await?;

        for row in client.query("SELECT name FROM trend_directory.trend_store_part tsp JOIN trend_directory.trend_store ts ON ts.id = tsp.trend_store_id WHERE ts.granularity = $1::text::interval", &[&self.granularity]).await? {
            let table_name: &str = row.get(0);
            let query = format!("DELETE FROM trend.\"{}\" WHERE timestamp = $1", table_name);
            client.query(&query, &[&self.timestamp]).await?;

            println!("Delete data in: '{}'", table_name);
        }

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStoreDump {
    #[arg(help="data source of trend store to dump")]
    data_source: String,
    #[arg(help="entity type of trend store to dump")]
    entity_type: String,
    #[arg(
        help="granularity of trend store to dump",
        value_parser=humantime::parse_duration
    )]
    granularity: Duration,
}

#[async_trait]
impl Cmd for TrendStoreDump {
    async fn run(&self) -> CmdResult {
        let mut client = connect_db().await?;

        let trend_store = load_trend_store(&mut client, &self.data_source, &self.entity_type, &self.granularity).await?;

        let trend_store_definition = trend_store.dump()?;

        println!("{}", trend_store_definition);

        Ok(())
    }
}

#[derive(Debug, Parser, PartialEq)]
pub struct TrendStoreOpt {
    #[command(subcommand)]
    command: TrendStoreOptCommands
}

#[derive(Debug, Subcommand, PartialEq)]
pub enum TrendStoreOptCommands {
    #[command(about = "list existing trend stores")]
    List(TrendStoreList),
    #[command(about = "create a trend store")]
    Create(TrendStoreCreate),
    #[command(about = "show differences for a trend store")]
    Diff(TrendStoreDiff),
    #[command(about = "update a trend store")]
    Update(TrendStoreUpdate),
    #[command(about = "delete a trend store")]
    Delete(DeleteOpt),
    #[command(about = "partition management commands")]
    Partition(TrendStorePartition),
    #[command(about = "run sanity checks for trend store")]
    Check(TrendStoreCheck),
    #[command(about = "part management commands")]
    Part(TrendStorePartOpt),
    #[command(about = "rename a trend")]
    RenameTrend(TrendStoreRenameTrend),
    #[command(about = "delete all data for a specific timestamp")]
    DeleteTimestamp(TrendStoreDeleteTimestamp),
    #[command(about = "dump the definition of a trend store")]
    Dump(TrendStoreDump),
}

impl TrendStoreOpt {
    pub async fn run(&self) -> CmdResult {
        match &self.command {
            TrendStoreOptCommands::List(list) => list.run().await,
            TrendStoreOptCommands::Create(create) => create.run().await,
            TrendStoreOptCommands::Diff(diff) => diff.run().await,
            TrendStoreOptCommands::Update(update) => update.run().await,
            TrendStoreOptCommands::Delete(delete) => run_trend_store_delete_cmd(delete).await,
            TrendStoreOptCommands::Partition(partition) => match &partition.command {
                TrendStorePartitionCommands::Create(create) => {
                    run_trend_store_partition_create_cmd(create).await
                }
                TrendStorePartitionCommands::Remove(remove) => remove.run().await,
            },
            TrendStoreOptCommands::Check(check) => run_trend_store_check_cmd(check),
            TrendStoreOptCommands::Part(part) => match &part.command {
                TrendStorePartOptCommands::Analyze(analyze) => analyze.run().await,
            },
            TrendStoreOptCommands::RenameTrend(rename_trend) => rename_trend.run().await,
            TrendStoreOptCommands::DeleteTimestamp(delete_timestamp) => delete_timestamp.run().await,
            TrendStoreOptCommands::Dump(dump) => dump.run().await,
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
        create_partitions_for_timestamp(&mut client, for_timestamp.into()).await?;
    } else {
        create_partitions(&mut client, args.ahead_interval).await?;
    }

    println!("Created partitions");
    Ok(())
}

async fn run_trend_store_delete_cmd(args: &DeleteOpt) -> CmdResult {
    println!("Deleting trend store {}", args.id);

    let mut client = connect_db().await?;

    let result = delete_trend_store(&mut client, args.id).await;

    match result {
        Ok(_) => Ok(()),
        Err(e) => Err(Error::Runtime(RuntimeError {
            msg: format!("Error deleting trend store: {e}"),
        })),
    }
}
