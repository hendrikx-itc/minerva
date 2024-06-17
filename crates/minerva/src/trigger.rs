use std::fmt;
use std::path::PathBuf;
use std::str::FromStr;
use std::time::Duration;

use postgres_types::ToSql;
use serde::{Deserialize, Serialize};

use chrono::{DateTime, TimeZone, Timelike};
use postgres_protocol::escape::{escape_identifier, escape_literal};
use tokio_postgres::{Client, GenericClient, Row, Transaction};

use async_trait::async_trait;

use crate::interval::parse_interval;

use super::change::{Change, ChangeResult};
use super::error::{ConfigurationError, DatabaseError, Error, RuntimeError};
use super::notification_store::notification_store_exists;

type PostgresName = String;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct KPIDataColumn {
    pub name: String,
    pub data_type: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Threshold {
    pub name: String,
    pub data_type: String,
    pub value: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TrendStoreLink {
    pub part_name: String,
    pub mapping_function: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MappingFunction {
    pub name: String,
    pub source: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Trigger {
    pub name: PostgresName,
    pub kpi_data: Vec<KPIDataColumn>,
    pub kpi_function: String,
    pub thresholds: Vec<Threshold>,
    pub condition: String,
    pub weight: String,
    pub notification: String,
    pub tags: Vec<String>,
    pub fingerprint: String,
    pub notification_store: String,
    pub data: String,
    pub trend_store_links: Vec<TrendStoreLink>,
    pub mapping_functions: Vec<MappingFunction>,
    pub description: String,
    #[serde(with = "humantime_serde")]
    pub granularity: Duration,
}

impl fmt::Display for Trigger {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Trigger({})", &self.name,)
    }
}

pub async fn list_triggers(
    conn: &mut Client,
) -> Result<Vec<(String, String, String, String, String, bool)>, String> {
    let query = concat!(
        "SELECT name, ns::text, granularity::text, default_interval::text, description, enabled ",
        "FROM trigger.rule ",
        "LEFT JOIN notification_directory.notification_store ns ON ns.id = notification_store_id",
    );

    let result = conn.query(query, &[]).await.unwrap();

    let triggers: Result<Vec<(String, String, String, String, String, bool)>, String> = result
        .into_iter()
        .map(|row: Row| {
            let name: String = row
                .try_get(0)
                .map_err(|e| format!("could not retrieve name: {e}"))?;
            let notification_store: Option<String> = row
                .try_get(1)
                .map_err(|e| format!("could not retrieve notification store name: {e}"))?;
            let granularity: Option<String> = row
                .try_get(2)
                .map_err(|e| format!("could not retrieve granularity: {e}"))?;
            let default_interval: Option<String> = row
                .try_get(3)
                .map_err(|e| format!("could not retrieve default interval: {e}"))?;
            let description: Option<String> = row
                .try_get(4)
                .map_err(|e| format!("could not retrieve description: {e}"))?;
            let enabled: bool = row
                .try_get(5)
                .map_err(|e| format!("could not retrieve enabled: {e}"))?;

            let trigger_row = (
                name,
                notification_store.unwrap_or("UNDEFINED".into()),
                granularity.unwrap_or("UNDEFINED".into()),
                default_interval.unwrap_or("UNDEFINED".into()),
                description.unwrap_or("".to_string()),
                enabled,
            );
            Ok(trigger_row)
        })
        .collect();

    triggers
}

pub struct AddTrigger {
    pub trigger: Trigger,
    pub verify: bool,
    pub enable: bool,
}

impl fmt::Display for AddTrigger {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "AddTrigger({})", &self.trigger)
    }
}

const MAX_TRIGGER_NAME_LENGTH: usize = 45;

#[async_trait]
impl Change for AddTrigger {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        if self.trigger.name.len() > MAX_TRIGGER_NAME_LENGTH {
            return Err(Error::Configuration(ConfigurationError::from_msg(format!(
                "Trigger name too long ({} > {})",
                self.trigger.name.len(),
                MAX_TRIGGER_NAME_LENGTH
            ))));
        }

        let mut transaction = client.transaction().await?;

        create_type(&self.trigger, &mut transaction).await?;

        create_kpi_function(&self.trigger, &mut transaction).await?;

        create_rule(&self.trigger, &mut transaction).await?;

        set_weight(&self.trigger, &mut transaction).await?;

        set_thresholds(&self.trigger, &mut transaction).await?;

        set_condition(&self.trigger, &mut transaction).await?;

        define_notification_message(&self.trigger, &mut transaction).await?;

        define_notification_data(&self.trigger, &mut transaction).await?;

        create_mapping_functions(&self.trigger, &mut transaction).await?;

        link_trend_stores(&self.trigger, &mut transaction).await?;

        set_description(&self.trigger, &mut transaction).await?;

        set_enabled(&mut transaction, &self.trigger.name, self.enable).await?;

        let mut check_result: String = "No check has run".to_string();

        if self.verify {
            check_result = run_checks(&self.trigger.name, &mut transaction).await?;
        }

        transaction.commit().await?;

        let message = match self.verify {
            false => format!("Created trigger '{}'", &self.trigger.name),
            true => format!("Created trigger '{}': {}", &self.trigger.name, check_result),
        };

        Ok(message)
    }
}

async fn create_type<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    let type_name = format!("{}_kpi", &trigger.name);

    let query = format!(
        "DROP TYPE IF EXISTS trigger_rule.{} CASCADE",
        escape_identifier(&type_name),
    );

    client.execute(&query, &[]).await.map_err(|e| {
        DatabaseError::from_msg(format!("Error removing KPI type before re-creating: {e}"))
    })?;

    let mut cols: Vec<(String, String)> = vec![
        (String::from("entity_id"), String::from("integer")),
        (
            String::from("timestamp"),
            String::from("timestamp with time zone"),
        ),
    ];

    for data_column in trigger.kpi_data.iter() {
        cols.push((data_column.name.clone(), data_column.data_type.clone()))
    }

    let column_spec = cols
        .iter()
        .map(|(name, data_type)| format!("{} {}", escape_identifier(name), &data_type))
        .collect::<Vec<String>>()
        .join(", ");

    let query = format!(
        "CREATE TYPE trigger_rule.{} AS ({})",
        escape_identifier(&type_name),
        &column_spec,
    );

    client
        .execute(&query, &[])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error creating KPI type: {e}")))?;

    Ok(format!("Added KPI type for trigger '{}'", &trigger.name))
}

async fn cleanup_rule<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    let query = "SELECT trigger.cleanup_rule(rule) FROM trigger.rule WHERE name = $1";

    client
        .execute(query, &[&trigger.name])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error cleaning up rule: {e}")))?;

    Ok(format!("Cleaned up rule for trigger '{}'", &trigger.name))
}

async fn rename_trigger<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    old_name: &str,
    client: &mut T,
) -> ChangeResult {
    let query = "UPDATE trigger.rule SET name = $1 WHERE name = $2";

    client
        .execute(query, &[&trigger.name, &old_name])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error renaming trigger: {e}")))?;

    Ok(format!(
        "Renamed trigger '{}' to '{}'",
        &old_name, &trigger.name
    ))
}

async fn create_kpi_function<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    let function_name = format!("{}_kpi", &trigger.name);
    let type_name = format!("{}_kpi", &trigger.name);

    let query = format!(
        "CREATE FUNCTION trigger_rule.{}(timestamp with time zone) RETURNS SETOF trigger_rule.{} AS $trigger${}$trigger$ LANGUAGE plpgsql STABLE;",
        &escape_identifier(&function_name),
        &escape_identifier(&type_name),
        &trigger.kpi_function,
    );

    client
        .execute(&query, &[])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error creating KPI function: {e}")))?;

    Ok(format!(
        "Added KPI function for trigger '{}'",
        &trigger.name
    ))
}

async fn create_rule<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    let query = format!(
        "SELECT * FROM trigger.create_rule($1, array[{}]::trigger.threshold_def[])",
        trigger
            .thresholds
            .iter()
            .map(|threshold| {
                format!(
                    "({}, {})",
                    escape_literal(&threshold.name),
                    escape_literal(&threshold.data_type)
                )
            })
            .collect::<Vec<String>>()
            .join(",")
    );

    client
        .execute(&query, &[&trigger.name])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error creating rule: {e}")))?;

    if !notification_store_exists(client, &trigger.notification_store).await? {
        return Err(Error::Configuration(ConfigurationError::from_msg(format!(
            "Error creating rule: No notification store found named '{}'",
            &trigger.notification_store
        ))));
    }

    let query = concat!(
        "UPDATE trigger.rule ",
        "SET notification_store_id = notification_store.id, ",
        "granularity = $1::text::interval ",
        "FROM notification_directory.notification_store ",
        "JOIN directory.data_source ",
        "ON data_source.id = notification_store.data_source_id ",
        "WHERE rule.name = $2 AND data_source.name = $3",
    );

    client
        .execute(
            query,
            &[
                &humantime::format_duration(trigger.granularity).to_string(),
                &trigger.name,
                &trigger.notification_store,
            ],
        )
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error creating rule: {e}")))?;

    Ok(format!("Added rule for trigger '{}'", &trigger.name))
}

async fn setup_rule<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    let query = format!(
        "SELECT trigger.setup_rule(rule, array[{}]::trigger.threshold_def[]) FROM trigger.rule WHERE name = $1",
        trigger.thresholds.iter().map(|threshold| { format!("({}, {})", escape_literal(&threshold.name), escape_literal(&threshold.data_type)) }).collect::<Vec<String>>().join(",")
    );

    client
        .execute(&query, &[&trigger.name])
        .await
        .map_err(|e| {
            DatabaseError::from_msg(format!("Error setting up rule: {e}\nStatement: {query}"))
        })?;

    let query = concat!(
        "UPDATE trigger.rule ",
        "SET notification_store_id = notification_store.id, ",
        "granularity = $1::text::interval ",
        "FROM notification_directory.notification_store ",
        "JOIN directory.data_source ",
        "ON data_source.id = notification_store.data_source_id ",
        "WHERE rule.name = $2 AND data_source.name = $3",
    );

    client
        .execute(
            query,
            &[
                &humantime::format_duration(trigger.granularity).to_string(),
                &trigger.name,
                &trigger.notification_store,
            ],
        )
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error creating rule: {e}")))?;

    Ok(format!("Added rule for trigger '{}'", &trigger.name))
}

async fn set_weight<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    let query = "SELECT trigger.set_weight($1::name, $2::text)";

    client
        .execute(query, &[&trigger.name, &trigger.weight])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error setting weight: {e}")))?;

    Ok(format!("Set weight for trigger '{}'", &trigger.name))
}

pub async fn set_thresholds<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    let function_name = format!("{}_set_thresholds", &trigger.name);
    let function_args = trigger
        .thresholds
        .iter()
        .map(|threshold| threshold.value.clone())
        .collect::<Vec<String>>()
        .join(",");

    let query = format!(
        "SELECT trigger_rule.{}({})",
        &escape_identifier(&function_name),
        function_args,
    );

    client
        .execute(&query, &[])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error setting thresholds: {e}")))?;

    Ok(format!("Set thresholds for trigger '{}'", &trigger.name))
}

async fn set_condition<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    let query = "SELECT trigger.set_condition(rule, $1) FROM trigger.rule WHERE name = $2";

    client
        .execute(query, &[&trigger.condition, &trigger.name])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error setting condition: {e}")))?;

    Ok(format!("Set condition for trigger '{}'", &trigger.name))
}

async fn define_notification_message<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    let query = "SELECT trigger.define_notification_message($1, $2)";

    client
        .execute(query, &[&trigger.name, &trigger.notification])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error setting message: {e}")))?;

    Ok(format!("Set message for trigger '{}'", &trigger.name))
}

async fn define_notification_data<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    let query = "SELECT trigger.define_notification_data($1, $2)";

    client
        .execute(query, &[&trigger.name, &trigger.data])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error setting data: {e}")))?;

    Ok(format!("Set data for trigger '{}'", &trigger.name))
}

async fn drop_notification_data_function<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    let function_name = format!("{}_notification_data", &trigger.name);

    let query = format!(
        "DROP FUNCTION IF EXISTS trigger_rule.{}(timestamp with time zone);",
        &escape_identifier(&function_name),
    );

    client
        .execute(&query, &[])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error dropping data function: {e}")))?;

    Ok(format!(
        "Dropped data function for trigger '{}'",
        &trigger.name
    ))
}

async fn create_mapping_functions<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    for mapping_function in trigger.mapping_functions.iter() {
        let query = format!(
            "CREATE FUNCTION trend.{}(timestamp with time zone) RETURNS SETOF timestamp with time zone AS $${}$$ LANGUAGE sql STABLE",
            escape_identifier(&mapping_function.name),
            &mapping_function.source,
        );

        client.execute(&query, &[]).await.map_err(|e| {
            DatabaseError::from_msg(format!("Error creating mapping function: {e}"))
        })?;
    }

    Ok(format!(
        "Created mapping functions for trigger '{}'",
        &trigger.name
    ))
}

async fn link_trend_stores<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    for trend_store_link in trigger.trend_store_links.iter() {
        let mapping_function = format!(
            "trend.{}(timestamp with time zone)",
            escape_identifier(&trend_store_link.mapping_function),
        );

        let query = concat!(
            "INSERT INTO trigger.rule_trend_store_link(",
            "rule_id, trend_store_part_id, timestamp_mapping_func",
            ") ",
            "SELECT rule.id, trend_store_part.id, $1::text::regprocedure ",
            "FROM trigger.rule, trend_directory.trend_store_part ",
            "WHERE rule.name = $2 AND trend_store_part.name = $3",
        );

        client
            .execute(
                query,
                &[
                    &mapping_function,
                    &trigger.name,
                    &trend_store_link.part_name,
                ],
            )
            .await
            .map_err(|e| DatabaseError::from_msg(format!("Error linking trend store: {e}")))?;
    }

    Ok(format!(
        "Linked trend stores for trigger '{}'",
        &trigger.name
    ))
}

async fn set_description<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    let query = "UPDATE trigger.rule SET description = $1 WHERE name = $2";

    client
        .execute(query, &[&trigger.description, &trigger.name])
        .await
        .map_err(|e| {
            DatabaseError::from_msg(format!(
                "Error setting description of trigger '{}': {}",
                trigger.name, e
            ))
        })?;

    Ok(format!(
        "Set description of trigger '{}' to '{}'",
        trigger.name, trigger.description,
    ))
}

async fn set_enabled<T: GenericClient + Sync + Send>(
    client: &mut T,
    trigger_name: &str,
    enabled: bool,
) -> ChangeResult {
    let query = "UPDATE trigger.rule SET enabled = $1 WHERE name = $2";

    client
        .execute(query, &[&enabled, &trigger_name])
        .await
        .map_err(|e| {
            DatabaseError::from_msg(format!(
                "Error setting enabled state of trigger '{trigger_name}': {e}"
            ))
        })?;

    Ok(format!(
        "Set enabled state of trigger '{trigger_name}' to '{enabled}'"
    ))
}

/// Truncate a reference timestamp to the nearest timestamp for a specified granularity.
fn truncate_timestamp_for_granularity<Tz>(
    granularity: Duration,
    ref_timestamp: &DateTime<Tz>,
) -> Result<DateTime<Tz>, Error>
where
    Tz: chrono::TimeZone,
{
    let granularity_text: String = humantime::format_duration(granularity).to_string();

    match granularity_text.as_str() {
        "15m" => {
            let date = ref_timestamp.date_naive();

            let gran_minutes: u32 = 15;

            let time = ref_timestamp.time();

            let remainder = time.minute() % gran_minutes;

            let minutes = time.minute() - remainder;

            let timestamp = date
                .and_hms_opt(ref_timestamp.time().hour(), minutes, 0)
                .unwrap()
                .and_local_timezone(ref_timestamp.timezone())
                .unwrap();

            Ok(timestamp)
        }
        "1h" => {
            let date = ref_timestamp.date_naive();

            let timestamp = date
                .and_hms_opt(ref_timestamp.time().hour(), 0, 0)
                .unwrap()
                .and_local_timezone(ref_timestamp.timezone())
                .unwrap();

            Ok(timestamp)
        }
        "1day" => {
            let date = ref_timestamp.date_naive();

            let timestamp = date
                .and_hms_opt(0, 0, 0)
                .unwrap()
                .and_local_timezone(ref_timestamp.timezone())
                .unwrap();

            Ok(timestamp)
        }
        "7days" => {
            let date = ref_timestamp.date_naive();

            let timestamp = date
                .and_hms_opt(0, 0, 0)
                .unwrap()
                .and_local_timezone(ref_timestamp.timezone())
                .unwrap();

            Ok(timestamp)
        }
        _ => Err(Error::Runtime(RuntimeError::from_msg(format!(
            "Unsupported granularity: {}",
            &granularity_text
        )))),
    }
}

async fn trigger_exists<T: GenericClient + Sync + Send>(
    trigger_name: &str,
    client: &mut T,
) -> Result<bool, Error> {
    let query = "SELECT EXISTS (SELECT * FROM trigger.rule WHERE name = $1)";
    let row = client
        .query_one(query, &[&trigger_name])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error running check: {e}")))?;

    let result: bool = row.get(0);

    Ok(result)
}

async fn run_checks<T: GenericClient + Sync + Send>(
    trigger_name: &str,
    client: &mut T,
) -> ChangeResult {
    let trigger = load_trigger(client, trigger_name).await?;

    let query = format!(
        "SELECT * FROM trigger_rule.{}($1::timestamptz)",
        escape_identifier(trigger_name)
    );

    let reference_timestamp = chrono::offset::Local::now();

    let check_timestamp =
        truncate_timestamp_for_granularity(trigger.granularity, &reference_timestamp)?;

    client
        .execute(&query, &[&check_timestamp])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error running check: {e}")))?;

    Ok(format!(
        "Checks run successfully for '{}': '{}'",
        trigger_name, &check_timestamp
    ))
}
async fn unlink_trend_stores<T: GenericClient + Sync + Send>(
    trigger: &Trigger,
    client: &mut T,
) -> ChangeResult {
    let query = "DELETE FROM trigger.rule_trend_store_link USING trigger.rule WHERE rule_id = rule.id AND rule.name = $1";

    client
        .execute(query, &[&trigger.name])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error unlinking trend stores: {e}")))?;

    Ok(format!(
        "Unlinked trend stores for trigger '{}'",
        &trigger.name
    ))
}

pub struct DeleteTrigger {
    pub trigger_name: String,
}

impl fmt::Display for DeleteTrigger {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "DeleteTrigger({})", &self.trigger_name)
    }
}

#[async_trait]
impl Change for DeleteTrigger {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let row = client
            .query_one(
                "SELECT count(*) FROM trigger.rule WHERE name = $1",
                &[&self.trigger_name],
            )
            .await
            .map_err(|e| {
                DatabaseError::from_msg(format!("Error checking for rule existance: {e}"))
            })?;

        let count: i64 = row.get(0);

        if count == 0 {
            return Err(Error::Runtime(RuntimeError::from_msg(format!(
                "No trigger found matching name '{}'",
                &self.trigger_name
            ))));
        }

        client
            .execute("SELECT trigger.delete_rule($1)", &[&self.trigger_name])
            .await
            .map_err(|e| DatabaseError::from_msg(format!("Error deleting rule: {e}")))?;

        Ok(format!("Removed trigger '{}'", &self.trigger_name))
    }
}

pub fn load_trigger_from_file(path: &PathBuf) -> Result<Trigger, Error> {
    let f = std::fs::File::open(path).map_err(|e| {
        ConfigurationError::from_msg(format!(
            "Could not open trigger definition file '{}': {}",
            path.display(),
            e
        ))
    })?;

    if path.extension() == Some(std::ffi::OsStr::new("yaml")) {
        let trigger: Trigger = serde_yaml::from_reader(f).map_err(|e| {
            RuntimeError::from_msg(format!(
                "Could not read trigger definition from file '{}': {}",
                path.display(),
                e
            ))
        })?;

        Ok(trigger)
    } else if path.extension() == Some(std::ffi::OsStr::new("json")) {
        let trigger: Trigger = serde_json::from_reader(f).map_err(|e| {
            RuntimeError::from_msg(format!(
                "Could not read trigger definition from file '{}': {}",
                path.display(),
                e
            ))
        })?;

        Ok(trigger)
    } else {
        return Err(ConfigurationError::from_msg(format!(
            "Unsupported trigger definition format '{}'",
            path.extension().unwrap().to_string_lossy()
        ))
        .into());
    }
}

pub struct UpdateTrigger {
    pub trigger: Trigger,
    pub verify: bool,
}

impl fmt::Display for UpdateTrigger {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "UpdateTrigger({})", &self.trigger)
    }
}

#[async_trait]
impl Change for UpdateTrigger {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let mut transaction = client.transaction().await?;

        // Tear down
        drop_notification_data_function(&self.trigger, &mut transaction).await?;

        unlink_trend_stores(&self.trigger, &mut transaction).await?;

        cleanup_rule(&self.trigger, &mut transaction).await?;

        // Build up

        create_type(&self.trigger, &mut transaction).await?;

        create_kpi_function(&self.trigger, &mut transaction).await?;

        setup_rule(&self.trigger, &mut transaction).await?;

        set_weight(&self.trigger, &mut transaction).await?;

        set_thresholds(&self.trigger, &mut transaction).await?;

        set_condition(&self.trigger, &mut transaction).await?;

        define_notification_message(&self.trigger, &mut transaction).await?;

        define_notification_data(&self.trigger, &mut transaction).await?;

        create_mapping_functions(&self.trigger, &mut transaction).await?;

        link_trend_stores(&self.trigger, &mut transaction).await?;

        set_description(&self.trigger, &mut transaction).await?;

        let mut check_result: String = "No check has run".to_string();

        if self.verify {
            check_result = run_checks(&self.trigger.name, &mut transaction).await?;
        }

        transaction.commit().await?;

        let message = match self.verify {
            false => format!("Updated trigger '{}'", &self.trigger.name),
            true => format!("Updated trigger '{}': {}", &self.trigger.name, check_result),
        };

        Ok(message)
    }
}

pub struct RenameTrigger {
    pub trigger: Trigger,
    pub verify: bool,
    pub old_name: String,
}

impl fmt::Display for RenameTrigger {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "UpdateTrigger({})", &self.trigger)
    }
}

#[async_trait]
impl Change for RenameTrigger {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        if self.trigger.name.len() > MAX_TRIGGER_NAME_LENGTH {
            return Err(Error::Configuration(ConfigurationError::from_msg(format!(
                "Trigger name too long ({} > {})",
                self.trigger.name.len(),
                MAX_TRIGGER_NAME_LENGTH
            ))));
        }

        let mut transaction = client.transaction().await?;

        if !trigger_exists(&self.old_name, &mut transaction).await? {
            return Err(Error::Runtime(RuntimeError::from_msg(format!(
                "No trigger with name '{}'",
                &self.old_name
            ))));
        }

        let mut old_trigger = self.trigger.clone();

        old_trigger.name = self.old_name.clone();

        // Tear down
        drop_notification_data_function(&old_trigger, &mut transaction).await?;

        unlink_trend_stores(&old_trigger, &mut transaction).await?;

        cleanup_rule(&old_trigger, &mut transaction).await?;

        // The actual rename

        rename_trigger(&self.trigger, &self.old_name, &mut transaction).await?;

        // Build up

        create_type(&self.trigger, &mut transaction).await?;

        create_kpi_function(&self.trigger, &mut transaction).await?;

        setup_rule(&self.trigger, &mut transaction).await?;

        set_weight(&self.trigger, &mut transaction).await?;

        set_thresholds(&self.trigger, &mut transaction).await?;

        set_condition(&self.trigger, &mut transaction).await?;

        define_notification_message(&self.trigger, &mut transaction).await?;

        define_notification_data(&self.trigger, &mut transaction).await?;

        create_mapping_functions(&self.trigger, &mut transaction).await?;

        link_trend_stores(&self.trigger, &mut transaction).await?;

        let mut check_result: String = "No check has run".to_string();

        if self.verify {
            check_result = run_checks(&self.trigger.name, &mut transaction).await?;
        }

        transaction.commit().await?;

        let message = match self.verify {
            false => format!(
                "Renamed trigger '{}' to '{}'",
                &self.old_name, &self.trigger.name
            ),
            true => format!(
                "Renamed trigger '{}' to '{}': {}",
                &self.old_name, &self.trigger.name, check_result
            ),
        };

        Ok(message)
    }
}

pub struct VerifyTrigger {
    pub trigger_name: String,
}

impl fmt::Display for VerifyTrigger {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "VerifyTrigger({})", &self.trigger_name)
    }
}

#[async_trait]
impl Change for VerifyTrigger {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let mut transaction = client.transaction().await?;

        let message = run_checks(&self.trigger_name, &mut transaction).await?;

        Ok(message)
    }
}


pub struct EnableTrigger {
    pub trigger_name: String,
}

impl fmt::Display for EnableTrigger {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "EnableTrigger({})", &self.trigger_name)
    }
}

#[async_trait]
impl Change for EnableTrigger {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let mut transaction = client.transaction().await?;

        let message = set_enabled(&mut transaction, &self.trigger_name, true).await?;

        transaction.commit().await?;

        Ok(message)
    }
}

pub struct DisableTrigger {
    pub trigger_name: String,
}

impl fmt::Display for DisableTrigger {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "DisableTrigger({})", &self.trigger_name)
    }
}

#[async_trait]
impl Change for DisableTrigger {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let mut transaction = client.transaction().await?;

        let message = set_enabled(&mut transaction, &self.trigger_name, false).await?;

        transaction.commit().await?;

        Ok(message)
    }
}

fn extract_rule_from_src(src: &str) -> Result<String, Error> {
    let condition_regex = regex::Regex::from_str(r".*\(\$1\) WHERE ((?s).*);[ ]*$").unwrap();

    let captures = condition_regex.captures(src);

    let condition = match captures {
        Some(c) => c.get(1).unwrap().as_str(),
        None => {
            return Err(Error::Runtime(RuntimeError {
                msg: format!("Could not extract condition from SQL: '{src}'"),
            }))
        }
    };

    Ok(condition.into())
}

#[cfg(test)]
mod tests {
    use super::extract_rule_from_src;

    #[test]
    fn test_rule_extraction_single_line() {
        let condition_function_source = r#" SELECT * FROM trigger_rule."4G/hourly/PacketDropRate_with_threshold"($1) WHERE "packet_drop_rate" > "packet_drop_rate_max"; "#;

        let rule = extract_rule_from_src(&condition_function_source).unwrap();

        assert_eq!(rule, r#""packet_drop_rate" > "packet_drop_rate_max""#);
    }

    #[test]
    fn test_rule_extraction_multi_line() {
        let condition_function_source = r#" SELECT * FROM trigger_rule."4G/hourly/PacketDropRate_with_threshold"($1) WHERE "packet_drop_rate" > "packet_drop_rate_max" AND
        "packet_drop_amount" > "packet_drop_amount_min"; "#;

        let rule = extract_rule_from_src(&condition_function_source).unwrap();

        assert_eq!(
            rule,
            r#""packet_drop_rate" > "packet_drop_rate_max" AND
        "packet_drop_amount" > "packet_drop_amount_min""#
        );
    }
}

pub async fn load_trigger<T: GenericClient + Send + Sync>(
    conn: &mut T,
    name: &str,
) -> Result<Trigger, Error> {
    let query = concat!(
        "SELECT name, granularity::text, ns::text, rule.description ",
        "FROM trigger.rule ",
        "LEFT JOIN notification_directory.notification_store ns ON ns.id = notification_store_id ",
        "WHERE name = $1"
    );

    let row = conn
        .query_one(query, &[&String::from(name)])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Could not load trigger: {e}")))?;

    let granularity_str: String = row.try_get(1)?;

    let granularity = parse_interval(&granularity_str).map_err(|e| {
        Error::Runtime(RuntimeError::from_msg(format!(
            "Could not parse granularity '{granularity_str}': {e}"
        )))
    })?;

    let notification_store: Option<String> = row.try_get(2)?;

    let description: Option<String> = row.try_get(3)?;

    let kpi_data_columns = load_kpi_data_columns(conn, name).await?;

    let kpi_function_source =
        load_function_src(conn, "trigger_rule", &format!("{}_kpi", &name)).await?;

    let notification_function_source = load_function_src(
        conn,
        "trigger_rule",
        &format!("{}_notification_message", &name),
    )
    .await?;

    let data_function_source = load_function_src(
        conn,
        "trigger_rule",
        &format!("{}_notification_data", &name),
    )
    .await?;

    let condition_function_source = load_function_src(conn, "trigger_rule", name).await?;

    let condition = extract_rule_from_src(&condition_function_source)?;

    let weight_function_source =
        load_function_src(conn, "trigger_rule", &format!("{}_weight", &name)).await?;

    let thresholds = load_thresholds(conn, name).await?;

    let tags = load_tags(conn, name).await?;

    let fingerprint_function_source =
        load_function_src(conn, "trigger_rule", &format!("{}_fingerprint", &name)).await?;

    let trend_store_links = load_trend_store_links(conn, name).await?;

    Ok(Trigger {
        name: String::from(name),
        condition,
        data: data_function_source,
        fingerprint: fingerprint_function_source,
        granularity,
        kpi_data: kpi_data_columns,
        kpi_function: kpi_function_source,
        mapping_functions: Vec::<MappingFunction>::new(),
        notification: notification_function_source,
        notification_store: notification_store.unwrap_or("UNDEFINED".into()),
        tags,
        thresholds,
        trend_store_links,
        weight: weight_function_source,
        description: description.unwrap_or("".to_string()),
    })
}

pub async fn load_triggers<T: GenericClient + Send + Sync>(
    conn: &mut T,
) -> Result<Vec<Trigger>, Error> {
    let mut triggers: Vec<Trigger> = Vec::new();

    let query = "SELECT name FROM trigger.rule";

    let rows = conn.query(query, &[]).await.map_err(|e| {
        DatabaseError::from_msg(format!("Error loading trend materializations: {e}"))
    })?;

    for row in rows {
        let name = row.get(0);

        let trigger = load_trigger(conn, name).await?;

        triggers.push(trigger);
    }

    Ok(triggers)
}

pub async fn get_notifications<T: GenericClient + Send + Sync, Ts: ToSql + Send + Sync>(
    conn: &mut T,
    name: &str,
    timestamp: Ts,
) -> Result<Vec<(i32, String, i32, String, String)>, Error>
where
    Ts: ToSql,
{
    let query = format!("SELECT entity_id, timestamp::text, weight, details, data::text FROM trigger_rule.\"{}_create_notification\"($1::timestamptz)", name);

    let query_args = vec![&timestamp as &(dyn ToSql + Sync)];

    let notifications: Vec<(i32, String, i32, String, String)> = conn
        .query(&query, query_args.iter().as_slice())
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error retrieving notifications: {e}")))?
        .into_iter()
        .map(|row| {
            let n1: i32 = row.get(0);
            let n2: String = row.get(1);
            let n3: i32 = row.get(2);
            let n4: String = row.get(3);
            let n5: String = row.get(4);

            (n1, n2, n3, n4, n5)
        })
        .collect();

    Ok(notifications)
}

pub struct CreateNotifications<Tz: TimeZone> {
    pub trigger_name: String,
    pub timestamp: Option<DateTime<Tz>>,
}

impl<Tz: TimeZone> fmt::Display for CreateNotifications<Tz> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "CreateNotifications({})", &self.trigger_name)
    }
}

#[async_trait]
impl<Tz> Change for CreateNotifications<Tz>
where
    Tz: TimeZone,
    <Tz as TimeZone>::Offset: Sync + Send,
    DateTime<Tz>: ToSql,
{
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let mut transaction = client.transaction().await?;

        let message =
            create_notifications(&mut transaction, &self.trigger_name, self.timestamp.clone())
                .await?;

        transaction.commit().await?;

        Ok(message)
    }
}

pub async fn create_notifications<T: GenericClient + Send + Sync, Ts: ToSql + Send + Sync>(
    conn: &mut T,
    name: &str,
    timestamp: Option<Ts>,
) -> Result<String, Error>
where
    Ts: ToSql,
{
    let outer_t: Ts;

    let (query, query_args) = match timestamp {
        None => {
            let query = String::from("SELECT trigger.create_notifications($1::name)");

            let query_args = vec![&name as &(dyn ToSql + Sync)];

            (query, query_args)
        }
        Some(t) => {
            outer_t = t;
            let query =
                String::from("SELECT trigger.create_notifications($1::name, $2::timestamptz)");

            let query_args = vec![
                &name as &(dyn ToSql + Sync),
                &outer_t as &(dyn ToSql + Sync),
            ];

            (query, query_args)
        }
    };

    let row = conn
        .query_one(&query, query_args.iter().as_slice())
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error checking for rule existance: {e}")))?;

    let notification_count: i32 = row.try_get(0)?;

    Ok(format!(
        "Created {notification_count} notifications for trigger '{name}'"
    ))
}

async fn load_kpi_data_columns<T: GenericClient + Send + Sync>(
    conn: &mut T,
    trigger_name: &str,
) -> Result<Vec<KPIDataColumn>, Error> {
    let type_name = format!("{trigger_name}_kpi");

    let query = concat!(
        "select attname, typname ",
        "from pg_class c join pg_attribute a on attrelid = c.oid ",
        "join pg_type t on t.oid = atttypid ",
        "where relname = $1 and attname not in ('timestamp', 'entity_id')"
    );

    let rows = conn
        .query(query, &[&type_name])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Could not load type columns: {e}")))?;

    let kpi_data_columns = rows
        .iter()
        .map(|row| KPIDataColumn {
            name: row.get(0),
            data_type: row.get(1),
        })
        .collect();

    Ok(kpi_data_columns)
}

/// Load the tags linked to a trigger
async fn load_tags<T: GenericClient + Send + Sync>(
    conn: &mut T,
    trigger_name: &str,
) -> Result<Vec<String>, Error> {
    let query = concat!(
        "select tag.name ",
        "from trigger.rule ",
        "join trigger.rule_tag_link rtl on rtl.rule_id = rule.id ",
        "join directory.tag on tag.id = rtl.tag_id ",
        "where rule.name = $1"
    );

    let rows = conn
        .query(query, &[&trigger_name])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Could not load type columns: {e}")))?;

    let tags = rows.iter().map(|row| row.get(0)).collect();

    Ok(tags)
}

async fn load_trend_store_links<T: GenericClient + Send + Sync>(
    conn: &mut T,
    trigger_name: &str,
) -> Result<Vec<TrendStoreLink>, Error> {
    let query = concat!(
        "select tsp.name, timestamp_mapping_func::text ",
        "from trigger.rule ",
        "join trigger.rule_trend_store_link rtsl on rtsl.rule_id = rule.id ",
        "join trend_directory.trend_store_part tsp on tsp.id = rtsl.trend_store_part_id ",
        "where rule.name = $1"
    );

    let rows = conn
        .query(query, &[&trigger_name])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Could not load type columns: {e}")))?;

    let trend_store_links = rows
        .iter()
        .map(|row| TrendStoreLink {
            part_name: row.get(0),
            mapping_function: row.get(1),
        })
        .collect();

    Ok(trend_store_links)
}

async fn load_function_src<T: GenericClient + Send + Sync>(
    conn: &mut T,
    namespace: &str,
    function_name: &str,
) -> Result<String, Error> {
    let query = concat!(
        "select prosrc from pg_proc ",
        "join pg_namespace ns on ns.oid = pronamespace ",
        "where nspname = $1 and proname = $2",
    );

    let row = conn
        .query_one(query, &[&namespace, &function_name])
        .await
        .map_err(|e| {
            DatabaseError::from_msg(format!(
                "Could not load function source of function '{function_name}': {e}"
            ))
        })?;

    let function_source = row.get(0);

    Ok(function_source)
}

pub async fn load_thresholds<T: GenericClient + Send + Sync>(
    conn: &mut T,
    trigger_name: &str,
) -> Result<Vec<Threshold>, Error> {
    let view_name = format!("{trigger_name}_threshold");

    let query = concat!(
        "select attname, typname ",
        "from pg_class c join pg_attribute a on attrelid = c.oid ",
        "join pg_type t on t.oid = atttypid ",
        "where relname = $1"
    );

    let rows = conn
        .query(query, &[&view_name])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Could not load threshold columns: {e}")))?;

    let values_query = format!(
        "SELECT {} FROM trigger_rule.{}",
        rows.iter()
            .map(|row| format!("{}::text", escape_identifier(row.get(0))))
            .collect::<Vec<String>>()
            .join(","),
        escape_identifier(&view_name),
    );

    let values_row = conn
        .query_one(&values_query, &[])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Could not load threshold columns: {e}")))?;

    let thresholds = rows
        .iter()
        .enumerate()
        .map(|(index, row)| Threshold {
            name: row.get(0),
            data_type: row.get(1),
            value: values_row.get(index),
        })
        .collect();

    Ok(thresholds)
}

pub async fn load_thresholds_with_client(
    conn: &mut Client,
    trigger_name: &str,
) -> Result<Vec<Threshold>, Error> {
    let view_name = format!("{trigger_name}_threshold");

    let query = concat!(
        "select attname, typname ",
        "from pg_class c join pg_attribute a on attrelid = c.oid ",
        "join pg_type t on t.oid = atttypid ",
        "where relname = $1"
    );

    let rows = conn
        .query(query, &[&view_name])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Could not load threshold columns: {e}")))?;

    let values_query = format!(
        "SELECT {} FROM trigger_rule.{}",
        rows.iter()
            .map(|row| format!("{}::text", escape_identifier(row.get(0))))
            .collect::<Vec<String>>()
            .join(","),
        escape_identifier(&view_name),
    );

    let values_row = conn
        .query_one(&values_query, &[])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Could not load threshold columns: {e}")))?;

    let thresholds = rows
        .iter()
        .enumerate()
        .map(|(index, row)| Threshold {
            name: row.get(0),
            data_type: row.get(1),
            value: values_row.get(index),
        })
        .collect();

    Ok(thresholds)
}

pub fn dump_trigger(trigger: &Trigger) -> String {
    serde_json::to_string_pretty(trigger).unwrap()
}
