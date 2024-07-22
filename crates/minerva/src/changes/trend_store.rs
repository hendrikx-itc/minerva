use serde_json::Value;
use std::fmt;
use tokio_postgres::Transaction;

use async_trait::async_trait;

use crate::change::{Change, ChangeResult};
use crate::error::DatabaseError;
use crate::meas_value::DataType;
use crate::trend_store::{Trend, TrendStore, TrendStorePart};

pub struct RemoveTrends {
    pub trend_store_part: TrendStorePart,
    pub trends: Vec<String>,
}

impl fmt::Display for RemoveTrends {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "RemoveTrends({}, {})",
            &self.trend_store_part,
            self.trends.len()
        )
    }
}

impl fmt::Debug for RemoveTrends {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "RemoveTrends({}, {})",
            &self.trend_store_part,
            &self
                .trends
                .iter()
                .map(|t| format!("'{}'", &t))
                .collect::<Vec<String>>()
                .join(", ")
        )
    }
}

#[async_trait]
impl Change for RemoveTrends {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let query = concat!(
            "SELECT trend_directory.remove_table_trend(table_trend) ",
            "FROM trend_directory.table_trend ",
            "JOIN trend_directory.trend_store_part ON trend_store_part.id = table_trend.trend_store_part_id ",
            "WHERE trend_store_part.name = $1 AND table_trend.name = $2",
        );

        for trend_name in &self.trends {
            client
                .query_one(query, &[&self.trend_store_part.name, &trend_name])
                .await
                .map_err(|e| {
                    DatabaseError::from_msg(format!(
                        "Error removing trend '{}' from trend store part: {}",
                        &trend_name, e
                    ))
                })?;
        }

        Ok(format!(
            "Removed {} trends from trend store part '{}'",
            &self.trends.len(),
            &self.trend_store_part.name
        ))
    }
}

////////////
// AddTrends
////////////

pub struct AddTrends {
    pub trend_store_part: TrendStorePart,
    pub trends: Vec<Trend>,
}

impl fmt::Display for AddTrends {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "AddTrends({}, {})",
            &self.trend_store_part,
            self.trends.len()
        )
    }
}

impl fmt::Debug for AddTrends {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "AddTrends({}, {})",
            &self.trend_store_part,
            &self
                .trends
                .iter()
                .map(|t| format!("{}", &t))
                .collect::<Vec<String>>()
                .join(", ")
        )
    }
}

#[async_trait]
impl Change for AddTrends {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let query = concat!(
            "SELECT trend_directory.create_table_trends(trend_store_part, $1) ",
            "FROM trend_directory.trend_store_part WHERE name = $2",
        );

        client
            .query_one(query, &[&self.trends, &self.trend_store_part.name])
            .await
            .map_err(|e| {
                DatabaseError::from_msg(format!("Error adding trends to trend store part: {e}"))
            })?;

        Ok(format!(
            "Added {} trends to trend store part '{}'",
            &self.trends.len(),
            &self.trend_store_part.name
        ))
    }
}

pub struct ModifyTrendDataType {
    pub trend_name: String,
    pub from_type: DataType,
    pub to_type: DataType,
}

impl fmt::Display for ModifyTrendDataType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "Trend({}, {}->{})",
            &self.trend_name, &self.from_type, &self.to_type
        )
    }
}

/// A set of trends of a trend store part for which the data type needs to
/// change.
///
/// The change of data types for multiple trends in a trend store part is
/// grouped into one operation for efficiency purposes.
pub struct ModifyTrendDataTypes {
    pub trend_store_part: TrendStorePart,
    pub modifications: Vec<ModifyTrendDataType>,
}

impl fmt::Display for ModifyTrendDataTypes {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "ModifyTrendDataTypes({}, {})",
            &self.trend_store_part,
            self.modifications.len(),
        )
    }
}

impl fmt::Debug for ModifyTrendDataTypes {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let modifications: Vec<String> =
            self.modifications.iter().map(|m| format!("{m}")).collect();

        write!(
            f,
            "ModifyTrendDataTypes({}, {})",
            &self.trend_store_part,
            &modifications.join(", "),
        )
    }
}

#[async_trait]
impl Change for ModifyTrendDataTypes {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let transaction = client
            .transaction()
            .await
            .map_err(|e| DatabaseError::from_msg(format!("could not start transaction: {e}")))?;

        let timeout_query = "SET SESSION statement_timeout = 0";

        let result = transaction.execute(timeout_query, &[]).await;

        if let Err(e) = result {
            return Err(
                DatabaseError::from_msg(format!("Error setting session timeout: {e}")).into(),
            );
        }

        let timeout_query = "SET SESSION lock_timeout = '10min'";

        let result = transaction.execute(timeout_query, &[]).await;

        if let Err(e) = result {
            return Err(DatabaseError::from_msg(format!("Error setting lock timeout: {e}")).into());
        }

        let query = concat!(
            "UPDATE trend_directory.table_trend tt ",
            "SET data_type = $1 ",
            "FROM trend_directory.trend_store_part tsp ",
            "WHERE tsp.id = tt.trend_store_part_id AND tsp.name = $2 AND tt.name = $3"
        );

        for modification in &self.modifications {
            let result = transaction
                .execute(
                    query,
                    &[
                        &modification.to_type,
                        &self.trend_store_part.name,
                        &modification.trend_name,
                    ],
                )
                .await;

            if let Err(e) = result {
                transaction.rollback().await.unwrap();

                return Err(
                    DatabaseError::from_msg(format!("Error changing data types: {e}")).into(),
                );
            }
        }

        let alter_type_parts: Vec<String> = self
            .modifications
            .iter()
            .map(|m| {
                format!(
                    "ALTER \"{}\" TYPE {} USING CAST(\"{}\" AS {})",
                    &m.trend_name, &m.to_type, &m.trend_name, &m.to_type
                )
            })
            .collect();

        let alter_type_parts_str = alter_type_parts.join(", ");

        let alter_query = format!(
            "ALTER TABLE trend.\"{}\" {}",
            &self.trend_store_part.name, &alter_type_parts_str
        );

        let alter_query_slice: &str = &alter_query;

        if let Err(e) = transaction.execute(alter_query_slice, &[]).await {
            transaction.rollback().await.unwrap();

            return Err(match e.code() {
                Some(code) => DatabaseError::from_msg(format!(
                    "Error changing data types: {} - {}",
                    code.code(),
                    e
                ))
                .into(),
                None => DatabaseError::from_msg(format!("Error changing data types: {e}")).into(),
            });
        }

        if let Err(e) = transaction.commit().await {
            return Err(DatabaseError::from_msg(format!("Error committing changes: {e}")).into());
        }

        Ok(format!(
            "Altered trend data types for trend store part '{}'",
            &self.trend_store_part.name
        ))
    }
}

pub struct ModifyTrendExtraData {
    pub trend_name: String,
    pub trend_store_part_name: String,
    pub from_extra_data: Value,
    pub to_extra_data: Value,
}

impl fmt::Display for ModifyTrendExtraData {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "Trend({}.{}, {}->{})",
            &self.trend_store_part_name,
            &self.trend_name,
            &self.from_extra_data,
            &self.to_extra_data
        )
    }
}

#[async_trait]
impl Change for ModifyTrendExtraData {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let query = concat!(
            "UPDATE trend_directory.table_trend tt ",
            "SET extra_data = $1 ",
            "FROM trend_directory.trend_store_part tsp ",
            "WHERE tsp.id = tt.trend_store_part_id AND tsp.name = $2 AND tt.name = $3"
        );

        let result = client
            .execute(
                query,
                &[
                    &self.to_extra_data,
                    &self.trend_store_part_name,
                    &self.trend_name,
                ],
            )
            .await;

        if let Err(e) = result {
            return Err(DatabaseError::from_msg(format!("Error changing extra_data: {e}")).into());
        }

        Ok(format!(
            "Altered extra_data for trend '{}'.'{}'",
            &self.trend_store_part_name, &self.trend_name,
        ))
    }
}

pub struct AddTrendStorePart {
    pub trend_store: TrendStore,
    pub trend_store_part: TrendStorePart,
}

#[async_trait]
impl Change for AddTrendStorePart {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let query = concat!(
            "SELECT trend_directory.create_trend_store_part(trend_store.id, $1) ",
            "FROM trend_directory.trend_store ",
            "JOIN directory.data_source ON data_source.id = trend_store.data_source_id ",
            "JOIN directory.entity_type ON entity_type.id = trend_store.entity_type_id ",
            "WHERE data_source.name = $2 AND entity_type.name = $3 AND granularity = $4::integer * interval '1 sec'",
        );

        let mut granularity_seconds: i32 = self.trend_store.granularity.as_secs() as i32;
        if (granularity_seconds > 2500000) & (granularity_seconds < 3000000) {
            granularity_seconds = 2592000 // rust and postgres disagree on the number of seconds in a month
        }

        client
            .query_one(
                query,
                &[
                    &self.trend_store_part.name,
                    &self.trend_store.data_source,
                    &self.trend_store.entity_type,
                    &granularity_seconds,
                ],
            )
            .await
            .map_err(|e| {
                DatabaseError::from_msg(format!(
                    "Error creating trend store part '{}': {}",
                    &self.trend_store_part.name, e
                ))
            })?;

        Ok(format!(
            "Added trend store part '{}' to trend store '{}'",
            &self.trend_store_part.name, &self.trend_store
        ))
    }
}

impl fmt::Display for AddTrendStorePart {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "AddTrendStorePart({}, {})",
            &self.trend_store, &self.trend_store_part
        )
    }
}

pub struct AddTrendStore {
    pub trend_store: TrendStore,
}

impl fmt::Display for AddTrendStore {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "AddTrendStore({})", &self.trend_store)
    }
}

#[async_trait]
impl Change for AddTrendStore {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let query = concat!(
            "SELECT id ",
            "FROM trend_directory.create_trend_store(",
            "$1, $2, $3::text::interval, $4::text::interval, ",
            "$5::trend_directory.trend_store_part_descr[]",
            ")"
        );

        let granularity_text = humantime::format_duration(self.trend_store.granularity).to_string();
        let partition_size_text =
            humantime::format_duration(self.trend_store.partition_size).to_string();

        client
            .query_one(
                query,
                &[
                    &self.trend_store.data_source,
                    &self.trend_store.entity_type,
                    &granularity_text,
                    &partition_size_text,
                    &self.trend_store.parts,
                ],
            )
            .await
            .map_err(|e| DatabaseError::from_msg(format!("Error creating trend store: {e}")))?;

        Ok(format!("Added trend store {}", &self.trend_store))
    }
}
