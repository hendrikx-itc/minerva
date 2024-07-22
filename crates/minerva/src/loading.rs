use std::fs::File;
use std::io::BufReader;
use std::path::Path;

use log::debug;
use chrono::DateTime;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use tokio_postgres::Client;

use crate::error::{Error, RuntimeError};
use crate::interval::parse_interval;
use crate::job::{end_job, start_job};
use crate::trend_store::get_trend_store_id;
use crate::trend_store::{
    create_partitions_for_trend_store_and_timestamp, load_trend_store, RawMeasurementStore,
    TrendStore,
};

#[derive(Serialize, Deserialize)]
pub struct TrendsFromHeader {
    pub entity_column: String,
    pub timestamp_column: String,
}

#[derive(Serialize, Deserialize)]
pub enum TrendsFrom {
    List(Vec<String>),
    Header(TrendsFromHeader),
}

#[derive(Serialize, Deserialize)]
pub struct ParserConfig {
    pub entity_type: String,
    pub granularity: String,
    pub trends: TrendsFrom,
    pub extra: Option<Value>,
    pub null_value: String,
}

pub async fn load_data<P: AsRef<Path>>(
    client: &mut Client,
    data_source: &str,
    parser_config: &ParserConfig,
    file_path: P,
    create_partitions: bool,
) -> Result<(), Error> {
    let description = json!({"csv-load": file_path.as_ref().to_string_lossy()});

    let f = File::open(file_path).map_err(|e| format!("{}", e))?;

    let reader = BufReader::new(f);

    let mut csv_reader = csv::Reader::from_reader(reader);

    let (trends, entity_column, timestamp_column) = match &parser_config.trends {
        TrendsFrom::Header(from_header) => {
            let trends = match csv_reader.headers() {
                Ok(headers) => headers.iter().map(String::from).collect(),
                Err(_) => Vec::new(),
            };

            (
                trends,
                from_header.entity_column.clone(),
                from_header.timestamp_column.clone(),
            )
        }
        TrendsFrom::List(list) => (
            list.clone(),
            String::from("entity"),
            String::from("timestamp"),
        ),
    };

    let entity_column_index = match trends.iter().position(|t| t.eq(&entity_column)) {
        Some(index) => index,
        None => {
            return Err(Error::Runtime(RuntimeError::from_msg(format!(
                "No column matching entity column '{entity_column}'"
            ))))
        }
    };

    let timestamp_column_index = match trends.iter().position(|t| t.eq(&timestamp_column)) {
        Some(index) => index,
        None => {
            return Err(Error::Runtime(RuntimeError::from_msg(format!(
                "No column matching timestamp column '{timestamp_column}'"
            ))))
        }
    };

    let job_id = start_job(client, &description).await?;

    debug!("Started job with Id {job_id}");

    let raw_data_package: Vec<(String, DateTime<chrono::Utc>, Vec<String>)> = csv_reader
        .records()
        .map(|record| {
            let record = record.unwrap();

            let entity: String = String::from(record.get(entity_column_index).unwrap());
            let timestamp_txt: &str = record.get(timestamp_column_index).unwrap();

            let timestamp: DateTime<chrono::Utc> = DateTime::parse_from_rfc3339(timestamp_txt)
                .unwrap()
                .with_timezone(&chrono::offset::Utc);

            let values: Vec<String> = record.iter().map(String::from).collect();

            let record: (String, DateTime<chrono::Utc>, Vec<String>) = (entity, timestamp, values);

            record
        })
        .collect();

    let granularity = parse_interval(&parser_config.granularity).unwrap();

    let trend_store: TrendStore = load_trend_store(client, data_source, &parser_config.entity_type, &granularity)
        .await
        .map_err(|e| format!("Error loading trend store for data source '{data_source}', entity type '{}' and granularity '{}': {e}", parser_config.entity_type, parser_config.granularity))?;

    let trend_store_id: i32 = get_trend_store_id(client, &trend_store)
        .await
        .map_err(|e| format!("Error loading trend store Id from database: {e}"))?;

    if create_partitions {
        for record in &raw_data_package {
            create_partitions_for_trend_store_and_timestamp(
                client,
                trend_store_id,
                record.1,
            )
            .await
            .map_err(|e| format!("Error creating partition for timestamp: {e}"))?;
        }
    }

    trend_store
        .store_raw(
            client,
            job_id,
            &trends,
            &raw_data_package,
            parser_config.null_value.clone(),
        )
        .await?;

    end_job(client, job_id).await?;

    debug!("Finished job with Id {job_id}");

    Ok(())
}
