use lazy_static::lazy_static;
use std::collections::HashMap;
use std::ops::DerefMut;
use std::time::Duration;

use deadpool_postgres::Pool;
use tokio_postgres::{GenericClient, Transaction};

use actix_web::{get, post, web::Data, web::Path, web::Query, HttpResponse};

use serde::{Deserialize, Serialize};
use utoipa::{IntoParams, ToSchema};

use minerva::change::Change;
use minerva::changes::trend_store::{AddTrendStore, AddTrendStorePart, AddTrends};
use minerva::interval::parse_interval;
use minerva::trend_store::{load_trend_store, GeneratedTrend, Trend, TrendStore, TrendStorePart};

use minerva::meas_value::DataType;

use super::error::Error;
use super::serviceerror::{ServiceError, ServiceErrorKind};

lazy_static! {
    static ref PARTITION_SIZE: HashMap<Duration, Duration> = HashMap::from([
        (
            parse_interval("15m").unwrap(),
            parse_interval("1d").unwrap()
        ),
        (parse_interval("1h").unwrap(), parse_interval("4d").unwrap()),
        (
            parse_interval("1d").unwrap(),
            parse_interval("3mons").unwrap()
        ),
        (parse_interval("1w").unwrap(), parse_interval("1y").unwrap()),
        (
            parse_interval("1mon").unwrap(),
            parse_interval("5y").unwrap()
        ),
    ]);
    static ref DEFAULT_GRANULARITY: String = "1 day".to_string();
}

#[derive(Debug, Serialize, Deserialize, IntoParams)]
pub struct QueryData {
    pub name: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendFull {
    pub id: i32,
    pub trend_store_part: i32,
    pub name: String,
    pub data_type: String,
    pub time_aggregation: String,
    pub entity_aggregation: String,
    pub extra_data: serde_json::Value,
    pub description: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendData {
    pub name: String,
    pub data_type: String,
    pub time_aggregation: String,
    pub entity_aggregation: String,
    pub extra_data: serde_json::Value,
    pub description: String,
}

impl TrendData {
    fn as_minerva(&self) -> Trend {
        Trend {
            name: self.name.clone(),
            data_type: serde_json::from_str(&self.data_type).unwrap_or(DataType::Numeric),
            description: self.description.clone(),
            time_aggregation: self.time_aggregation.clone(),
            entity_aggregation: self.entity_aggregation.clone(),
            extra_data: self.extra_data.clone(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct GeneratedTrendFull {
    pub id: i32,
    pub trend_store_part: i32,
    pub name: String,
    pub data_type: String,
    pub expression: String,
    pub extra_data: serde_json::Value,
    pub description: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct GeneratedTrendData {
    pub name: String,
    pub data_type: String,
    pub expression: String,
    pub extra_data: serde_json::Value,
    pub description: String,
}

impl GeneratedTrendData {
    fn as_minerva(&self) -> GeneratedTrend {
        GeneratedTrend {
            name: self.name.clone(),
            data_type: self.data_type.clone(),
            description: self.description.clone(),
            expression: self.expression.clone(),
            extra_data: self.extra_data.clone(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendDataWithTrendStorePart {
    pub id: i32,
    pub is_generated: bool,
    pub name: String,
    pub trend_store_part: String,
    pub entity_type: String,
    pub data_source: String,
    #[serde(with = "humantime_serde")]
    pub granularity: Duration,
    pub data_type: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendStorePartFull {
    pub id: i32,
    pub name: String,
    pub trend_store: i32,
    pub trends: Vec<TrendFull>,
    pub generated_trends: Vec<GeneratedTrendFull>,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendStorePartData {
    pub name: String,
    pub trends: Vec<TrendData>,
    pub generated_trends: Vec<GeneratedTrendData>,
}

impl TrendStorePartData {
    fn as_minerva(&self) -> TrendStorePart {
        let trends: Vec<Trend> = self.trends.iter().map(|trend| trend.as_minerva()).collect();

        let generated_trends: Vec<GeneratedTrend> = self
            .generated_trends
            .iter()
            .map(|generated_trend| generated_trend.as_minerva())
            .collect();

        TrendStorePart {
            name: self.name.clone(),
            trends,
            generated_trends,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendStoreFull {
    pub id: i32,
    pub entity_type: String,
    pub data_source: String,
    #[serde(with = "humantime_serde")]
    pub granularity: Duration,
    #[serde(with = "humantime_serde")]
    pub partition_size: Duration,
    #[serde(with = "humantime_serde")]
    pub retention_period: Duration,
    pub trend_store_parts: Vec<TrendStorePartFull>,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendStoreBasicData {
    pub entity_type: String,
    pub data_source: String,
    #[serde(with = "humantime_serde")]
    pub granularity: Duration,
}

impl TrendStoreBasicData {
    async fn as_minerva(&self, transaction: &mut Transaction<'_>) -> Result<TrendStore, String> {
        let result = load_trend_store(
            transaction,
            &self.data_source,
            &self.entity_type,
            &self.granularity,
        )
        .await;

        match result {
            Ok(trendstore) => Ok(trendstore),
            Err(_) => {
                let new_trend_store = TrendStore {
                    data_source: self.data_source.clone(),
                    entity_type: self.entity_type.clone(),
                    granularity: self.granularity,
                    partition_size: *PARTITION_SIZE.get(&self.granularity.clone()).unwrap(),
                    parts: vec![],
                };
                let result = AddTrendStore {
                    trend_store: new_trend_store.clone(),
                }
                .apply(transaction)
                .await;
                match result {
                    Ok(_) => Ok(new_trend_store),
                    Err(e) => Err(format!("Unable to find or create trend store: {e}")),
                }
            }
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendStorePartCompleteData {
    pub name: String,
    pub entity_type: String,
    pub data_source: String,
    #[serde(with = "humantime_serde")]
    pub granularity: Duration,
    #[serde(with = "humantime_serde")]
    pub partition_size: Duration,
    pub trends: Vec<TrendData>,
    pub generated_trends: Vec<GeneratedTrendData>,
}

impl TrendStorePartCompleteData {
    fn trend_store(&self) -> TrendStoreBasicData {
        TrendStoreBasicData {
            entity_type: self.entity_type.clone(),
            data_source: self.data_source.clone(),
            granularity: self.granularity,
        }
    }

    fn trend_store_part(&self) -> TrendStorePartData {
        TrendStorePartData {
            name: self.name.clone(),
            trends: self.trends.clone(),
            generated_trends: self.generated_trends.clone(),
        }
    }

    pub async fn create<T: GenericClient + Send + Sync>(
        &self,
        client: &mut T,
    ) -> Result<TrendStorePartFull, Error> {
        let mut tx = client.transaction().await.map_err(|_| Error {
            code: 500,
            message: "Could not create trend store".to_string(),
        })?;

        // first ensure the data source exists
        _ = tx
            .execute(
                "SELECT directory.name_to_data_source($1)",
                &[&self.data_source],
            )
            .await;

        let trendstore = self
            .trend_store()
            .as_minerva(&mut tx)
            .await
            .map_err(|e| Error {
                code: 409,
                message: e,
            })?;

        let action = AddTrendStorePart {
            trend_store: trendstore,
            trend_store_part: self.trend_store_part().as_minerva(),
        };

        action.apply(&mut tx).await.map_err(|e| Error {
            code: 409,
            message: format!("Creation of trendstorepart failed: {e}"),
        })?;

        let action = AddTrends {
            trend_store_part: self.trend_store_part().as_minerva(),
            trends: self.trend_store_part().as_minerva().trends,
        };

        action.apply(&mut tx).await.map_err(|e| Error {
            code: 409,
            message: format!(
                "Creation of trendstorepart succeeded, but inserting trends failed: {e}"
            ),
        })?;

        let (trend_store_part_id, trend_store_id): (i32, i32) = tx
            .query_one(
                "SELECT id, trend_store_id FROM trend_directory.trend_store_part WHERE name = $1",
                &[&self.name],
            )
            .await
            .map_err(|_| Error {
                code: 404,
                message: "Trend store part created, but could not be found after creation"
                    .to_string(),
            })
            .map(|row| (row.get(0), row.get(1)))?;

        let trends: Vec<TrendFull> = tx
            .query(
                concat!(
                    "SELECT id, trend_store_part_id, name, data_type, time_aggregation, entity_aggregation, extra_data, description ",
                    "FROM trend_directory.table_trend ",
                    "WHERE trend_store_part_id = $1"
                ),
                &[&trend_store_part_id]
            ).await
            .map_err(|e| Error { code: 500, message: e.to_string() })
            .map(|rows| rows
                .iter()
                .map(|row| TrendFull {
                    id: row.get(0),
                    trend_store_part: row.get(1),
                    name: row.get(2),
                    data_type: row.get(3),
                    time_aggregation: row.get(4),
                    entity_aggregation: row.get(5),
                    extra_data: row.get(6),
                    description: row.get(7),
                })
                .collect()
            )?;

        let generated_trends: Vec<GeneratedTrendFull> = tx
            .query(
                concat!(
                    "SELECT id, trend_store_part_id, name, data_type, expression, extra_data, description ",
                    "FROM trend_directory.generated_table_trend ",
                    "WHERE trend_store_part_id = $1",
                ),
                &[&trend_store_part_id]
            ).await
            .map_err(|e| Error { code: 500, message: e.to_string() } )
            .map(|rows| rows
                .iter()
                .map(|row| GeneratedTrendFull {
                    id: row.get(0),
                    trend_store_part: row.get(1),
                    name: row.get(2),
                    data_type: row.get(3),
                    expression: row.get(4),
                    extra_data: row.get(5),
                    description: row.get(6),
                })
                .collect()
            )?;

        tx.commit().await.map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })?;

        let trendstorepart = TrendStorePartFull {
            id: trend_store_part_id,
            name: self.name.to_string(),
            trend_store: trend_store_id,
            trends,
            generated_trends,
        };

        Ok(trendstorepart)
    }
}

#[utoipa::path(
    get,
    path="/trend-store-parts",
    responses(
    (status = 200, description = "List all trend store parts", body = [TrendStorePartFull]),
    (status = 500, description = "Problem interacting with database", body = Error),
    )
)]
#[get("/trend-store-parts")]
pub(super) async fn get_trend_store_parts(pool: Data<Pool>) -> Result<HttpResponse, ServiceError> {
    let client = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let trends: Vec<TrendFull> = client
        .query(
            concat!(
                "SELECT id, trend_store_part_id, name, data_type, time_aggregation, entity_aggregation, extra_data, description ",
                "FROM trend_directory.table_trend"
            ),
            &[]
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| rows
            .iter()
            .map(|row| TrendFull {
                id: row.get(0),
                trend_store_part: row.get(1),
                name: row.get(2),
                data_type: row.get(3),
                time_aggregation: row.get(4),
                entity_aggregation: row.get(5),
                extra_data: row.get(6),
                description: row.get(7),
            })
            .collect()
        )?;

    let generated_trends: Vec<GeneratedTrendFull> = client
        .query(
            concat!(
                "SELECT id, trend_store_part_id, name, data_type, expression, extra_data, description ",
                "FROM trend_directory.generated_table_trend"
            ),
            &[],
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| rows
            .iter()
            .map(|row| GeneratedTrendFull {
                id: row.get(0),
                trend_store_part: row.get(1),
                name: row.get(2),
                data_type: row.get(3),
                expression: row.get(4),
                extra_data: row.get(5),
                description: row.get(6),
            })
            .collect()
        )?;

    let trend_store_parts: Vec<TrendStorePartFull> = client
        .query(
            "SELECT id, name, trend_store_id FROM trend_directory.trend_store_part",
            &[],
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| {
            rows.iter()
                .map(|row| {
                    let tspid: i32 = row.get(0);

                    let my_trends: Vec<TrendFull> = trends
                        .iter()
                        .filter(|trend| trend.trend_store_part == tspid)
                        .cloned()
                        .collect();

                    let my_generated_trends: Vec<GeneratedTrendFull> = generated_trends
                        .iter()
                        .filter(|generated_trend| generated_trend.trend_store_part == tspid)
                        .cloned()
                        .collect();

                    TrendStorePartFull {
                        id: tspid,
                        name: row.get(1),
                        trend_store: row.get(2),
                        trends: my_trends,
                        generated_trends: my_generated_trends,
                    }
                })
                .collect()
        })?;

    Ok(HttpResponse::Ok().json(trend_store_parts))
}

#[utoipa::path(
    get,
    path="/trend-store-part/{id}",
    responses(
    (status = 200, description = "Get a specific trend store part", body = TrendStorePartFull),
    (status = 404, description = "Trend store part not found", body = Error),
    (status = 500, description = "Failure to interact with database", body = Error)
    )
)]
#[get("/trend-store-part/{id}")]
pub(super) async fn get_trend_store_part(
    pool: Data<Pool>,
    id: Path<i32>,
) -> Result<HttpResponse, ServiceError> {
    let tsp_id = id.into_inner();

    let client = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let trends: Vec<TrendFull> = client
        .query(
            concat!(
                "SELECT id, trend_store_part_id, name, data_type, time_aggregation, entity_aggregation, extra_data, description ",
                "FROM trend_directory.table_trend ",
                "WHERE trend_store_part_id=$1"
            ),
            &[&tsp_id]
        ).await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows|rows
            .iter()
            .map(|row| TrendFull {
                id: row.get(0),
                trend_store_part: row.get(1),
                name: row.get(2),
                data_type: row.get(3),
                time_aggregation: row.get(4),
                entity_aggregation: row.get(5),
                extra_data: row.get(6),
                description: row.get(7),
            })
            .collect()
        )?;

    let generated_trends: Vec<GeneratedTrendFull> = client
        .query(
            concat!(
            "SELECT id, trend_store_part_id, name, data_type, expression, extra_data, description ",
            "FROM trend_directory.generated_table_trend ",
            "WHERE trend_store_part_id = $1"
        ),
            &[&tsp_id],
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| {
            rows.iter()
                .map(|row| GeneratedTrendFull {
                    id: row.get(0),
                    trend_store_part: row.get(1),
                    name: row.get(2),
                    data_type: row.get(3),
                    expression: row.get(4),
                    extra_data: row.get(5),
                    description: row.get(6),
                })
                .collect()
        })?;

    let trendstorepart = client
        .query_one(
            "SELECT name, trend_store_id FROM trend_directory.trend_store_part WHERE id = $1",
            &[&tsp_id],
        )
        .await
        .map_err(|_| Error {
            code: 404,
            message: format!("Trend store part with id {} not found", &tsp_id),
        })
        .map(|row| TrendStorePartFull {
            id: tsp_id,
            name: row.get(0),
            trend_store: row.get(1),
            trends,
            generated_trends,
        })?;

    Ok(HttpResponse::Ok().json(trendstorepart))
}

#[utoipa::path(
    get,
    path="/trend-store-parts/find",
    responses(
    (status = 200, description = "Get a specific trend store part", body = TrendStorePartFull),
    (status = 404, description = "Trend store part not found", body = Error),
    (status = 500, description = "Unable to interact with database", body = Error),
    )
)]
#[get("/trend-store-parts/find")]
pub(super) async fn find_trend_store_part(
    pool: Data<Pool>,
    info: Query<QueryData>,
) -> Result<HttpResponse, ServiceError> {
    let name = &info.name;

    let client = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let (trend_store_part_id, trend_store_id): (i32, i32) = client
        .query_one(
            "SELECT id, trend_store_id FROM trend_directory.trend_store_part WHERE name = $1",
            &[&name],
        )
        .await
        .map_err(|_| Error {
            code: 404,
            message: format!("Trend store part with name {} not found", &name),
        })
        .map(|row| (row.get(0), row.get(1)))?;

    let trends: Vec<TrendFull> = client
        .query(
            concat!(
                "SELECT id, trend_store_part_id, name, data_type, time_aggregation, entity_aggregation, extra_data, description ",
                "FROM trend_directory.table_trend ",
                "WHERE trend_store_part_id = $1"
            ),
            &[&trend_store_part_id]
        ).await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| rows
            .iter()
            .map(|row| TrendFull {
                id: row.get(0),
                trend_store_part: row.get(1),
                name: row.get(2),
                data_type: row.get(3),
                time_aggregation: row.get(4),
                entity_aggregation: row.get(5),
                extra_data: row.get(6),
                description: row.get(7),
            })
            .collect()
        )?;

    let generated_trends: Vec<GeneratedTrendFull> = client
        .query(
            concat!(
                "SELECT id, trend_store_part_id, name, data_type, expression, extra_data, description ",
                "FROM trend_directory.generated_table_trend ",
                "WHERE trend_store_part_id=$1"
            ),
            &[&trend_store_part_id],
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| rows
            .iter()
            .map(|row| GeneratedTrendFull {
                id: row.get(0),
                trend_store_part: row.get(1),
                name: row.get(2),
                data_type: row.get(3),
                expression: row.get(4),
                extra_data: row.get(5),
                description: row.get(6),
            })
            .collect()
        )?;

    let trendstorepart = TrendStorePartFull {
        id: trend_store_part_id,
        name: name.to_string(),
        trend_store: trend_store_id,
        trends,
        generated_trends,
    };

    Ok(HttpResponse::Ok().json(trendstorepart))
}

#[utoipa::path(
    get,
    path="/trend-stores",
    responses(
    (status = 200, description = "List all trend store parts", body = [TrendStorePartFull]),
    (status = 500, description = "Problems interacting with database", body = Error),
    )
)]
#[get("/trend-stores")]
pub(super) async fn get_trend_stores(pool: Data<Pool>) -> Result<HttpResponse, ServiceError> {
    let client = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let trends: Vec<TrendFull> = client
        .query(
            concat!(
                "SELECT id, trend_store_part_id, name, data_type, time_aggregation, entity_aggregation, extra_data, description ",
                "FROM trend_directory.table_trend"
            ),
            &[]
        ).await.map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        }).map(|rows| rows
            .iter()
            .map(|row| TrendFull {
                id: row.get(0),
                trend_store_part: row.get(1),
                name: row.get(2),
                data_type: row.get(3),
                time_aggregation: row.get(4),
                entity_aggregation: row.get(5),
                extra_data: row.get(6),
                description: row.get(7),
            })
            .collect()
        )?;

    let generated_trends: Vec<GeneratedTrendFull> = client
        .query(
            concat!(
                "SELECT id, trend_store_part_id, name, data_type, expression, extra_data, description ",
                "FROM trend_directory.generated_table_trend"
            ),
            &[],
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| rows
            .iter()
            .map(|row| GeneratedTrendFull {
                id: row.get(0),
                trend_store_part: row.get(1),
                name: row.get(2),
                data_type: row.get(3),
                expression: row.get(4),
                extra_data: row.get(5),
                description: row.get(6),
            })
            .collect()
        )?;

    let parts: Vec<TrendStorePartFull> = client
        .query(
            "SELECT id, name, trend_store_id FROM trend_directory.trend_store_part",
            &[],
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| {
            rows.iter()
                .map(|row| {
                    let tspid: i32 = row.get(0);
                    let my_trends: Vec<TrendFull> = trends
                        .iter()
                        .filter(|trend| trend.trend_store_part == tspid)
                        .cloned()
                        .collect();

                    let my_generated_trends: Vec<GeneratedTrendFull> = generated_trends
                        .iter()
                        .filter(|generated_trend| generated_trend.trend_store_part == tspid)
                        .cloned()
                        .collect();

                    TrendStorePartFull {
                        id: tspid,
                        name: row.get(1),
                        trend_store: row.get(2),
                        trends: my_trends,
                        generated_trends: my_generated_trends,
                    }
                })
                .collect()
        })?;

    let trend_stores: Vec<TrendStoreFull> = client
        .query(
            concat!(
                "SELECT ts.id, entity_type.name, data_source.name, granularity::text, partition_size::text, retention_period::text ",
                "FROM trend_directory.trend_store ts ",
                "JOIN directory.entity_type ON ts.entity_type_id = entity_type.id ",
                "JOIN directory.data_source ON ts.data_source_id = data_source.id"
            ),
            &[]
        ).await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| rows
            .iter()
            .map(|row| {
                let tsid: i32 = row.get(0);
                let my_parts = parts
                    .iter()
                    .filter(|p| p.trend_store == tsid)
                    .cloned()
                    .collect();

                TrendStoreFull {
                    id: tsid,
                    entity_type: row.get(1),
                    data_source: row.get(2),
                    granularity: parse_interval(row.get(3)).unwrap(),
                    partition_size: parse_interval(row.get(4)).unwrap(),
                    retention_period: parse_interval(row.get(5)).unwrap(),
                    trend_store_parts: my_parts,
                }
            })
            .collect()
        )?;

    Ok(HttpResponse::Ok().json(trend_stores))
}

#[utoipa::path(
    get,
    path="/trend-stores/{id}",
    responses(
    (status = 200, description = "Get a specific trend store", body = TrendStorePartFull),
    (status = 404, description = "Trend store not found", body = Error),
    (status = 500, description = "Unable to interact with database", body = Error),
    )
)]
#[get("/trend-stores/{id}")]
pub(super) async fn get_trend_store(
    pool: Data<Pool>,
    id: Path<i32>,
) -> Result<HttpResponse, ServiceError> {
    let tsid = id.into_inner();

    let client = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let trends: Vec<TrendFull> = client
        .query(
            concat!(
                "SELECT t.id, t.trend_store_part_id, t.name, t.data_type, t.time_aggregation, t.entity_aggregation, t.extra_data, t.description ",
                "FROM trend_directory.table_trend t ",
                "JOIN trend_directory.trend_store_part tsp ON t.trend_store_part_id = tsp.id ",
                "WHERE tsp.trend_store_id = $1"
            ),
            &[&tsid]
        ).await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| rows
            .iter()
            .map(|row| TrendFull {
                id: row.get(0),
                trend_store_part: row.get(1),
                name: row.get(2),
                data_type: row.get(3),
                time_aggregation: row.get(4),
                entity_aggregation: row.get(5),
                extra_data: row.get(6),
                description: row.get(7),
            })
            .collect()
        )?;

    let generated_trends: Vec<GeneratedTrendFull> = client
        .query(
            concat!(
                "SELECT t.id, t.trend_store_part_id, t.name, t.data_type, t.expression, t.extra_data, t.description ",
                "FROM trend_directory.generated_table_trend t ",
                "JOIN trend_directory.trend_store_part tsp ON t.trend_store_part_id = tsp.id ",
                "WHERE tsp.trend_store_id = $1"
            ),
            &[&tsid]
        ).await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| rows
            .iter()
            .map(|row| GeneratedTrendFull {
                id: row.get(0),
                trend_store_part: row.get(1),
                name: row.get(2),
                data_type: row.get(3),
                expression: row.get(4),
                extra_data: row.get(5),
                description: row.get(6),
            })
            .collect()
        )?;

    let parts: Vec<TrendStorePartFull> = client
        .query(
            concat!(
                "SELECT id, name, trend_store_id ",
                "FROM trend_directory.trend_store_part ",
                "WHERE trend_store_id = $1"
            ),
            &[&tsid],
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| {
            rows.iter()
                .map(|row| {
                    let tspid: i32 = row.get(0);
                    let my_trends: Vec<TrendFull> = trends
                        .iter()
                        .filter(|t| t.trend_store_part == tspid)
                        .cloned()
                        .collect();

                    let my_generated_trends: Vec<GeneratedTrendFull> = generated_trends
                        .iter()
                        .filter(|t| t.trend_store_part == tspid)
                        .cloned()
                        .collect();

                    TrendStorePartFull {
                        id: tspid,
                        name: row.get(1),
                        trend_store: row.get(2),
                        trends: my_trends,
                        generated_trends: my_generated_trends,
                    }
                })
                .collect()
        })?;

    let trendstore = client
        .query_one(
            concat!(
                "SELECT ts.id, entity_type.name, data_source.name, granularity::text, partition_size::text, retention_period::text ",
                "FROM trend_directory.trend_store ts ",
                "JOIN directory.entity_type ON ts.entity_type_id = entity_type.id ",
                "JOIN directory.data_source ON ts.data_source_id = data_source.id ",
                "WHERE ts.id = $1",
            ),
            &[&tsid],
        ).await.map_err(|_| Error {
            code: 404,
            message: format!("Trend store with id {} not found", &tsid),
        }).map(|row| TrendStoreFull {
            id: tsid,
            entity_type: row.get(1),
            data_source: row.get(2),
            granularity: parse_interval(row.get(3)).unwrap(),
            partition_size: parse_interval(row.get(4)).unwrap(),
            retention_period: parse_interval(row.get(5)).unwrap(),
            trend_store_parts: parts,
        })?;

    Ok(HttpResponse::Ok().json(trendstore))
}

// curl -H "Content-Type: application/json" -X POST -d '{"name":"kpi-test_One_15m","entity_type":"test","data_source":"kpi","granularity":"15m","partition_size":"1d","trends":[{"name":"downtime","data_type":"numeric","time_aggregation":"SUM","entity_aggregation":"SUM","extra_data":{},"description":""}],"generated_trends":[]}' localhost:8000/trend-store-parts/new
// curl -H "Content-Type: application/json" -X POST -d '{"name":"kpi-test_Two_15m","entity_type":"test","data_source":"kpi","granularity":"15m","partition_size":"1d","trends":[{"name":"downtime","data_type":"numeric","time_aggregation":"SUM","entity_aggregation":"SUM","extra_data":{},"description":""}],"generated_trends":[]}' localhost:8000/trend-store-parts/new

#[utoipa::path(
    post,
    path="/trend-store-parts/new",
    responses(
    (status = 200, description = "Create a new trend store part", body = TrendStorePartData),
    (status = 400, description = "Incorrect data format", body = Error),
    (status = 404, description = "Trend store part cannot be found after creation", body = Error),
    (status = 409, description = "Trend store part cannot be created with these data", body = Error),
    (status = 500, description = "Problems interacting with database", body = Error),
    )
)]
#[post("/trend-store-parts/new")]
pub(super) async fn post_trend_store_part(
    pool: Data<Pool>,
    post: String,
) -> Result<HttpResponse, ServiceError> {
    let data: TrendStorePartCompleteData =
        serde_json::from_str(&post).map_err(|e| ServiceError {
            kind: ServiceErrorKind::BadRequest,
            message: format!("{e}"),
        })?;

    let mut manager = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let client: &mut tokio_postgres::Client = manager.deref_mut().deref_mut();

    let mut transaction = client.transaction().await?;

    let tsp = data.create(&mut transaction).await?;

    transaction.commit().await?;

    Ok(HttpResponse::Ok().json(tsp))
}

#[utoipa::path(
    get,
    path="/trends",
    responses(
    (status = 200, description = "List all trend store parts", body = [TrendDataWithTrendStorePart]),
    (status = 500, description = "Problem interacting with database", body = Error),
    )
)]
#[get("/trends")]
pub(super) async fn get_trends(pool: Data<Pool>) -> Result<HttpResponse, ServiceError> {
    let client = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let table_trends: Vec<TrendDataWithTrendStorePart> = client
        .query(
            concat!(
                "SELECT t.id, t.name, tsp.name, et.name, ds.name, ts.granularity::text, t.data_type ",
                "FROM trend_directory.table_trend t ",
                "JOIN trend_directory.trend_store_part tsp ON t.trend_store_part_id = tsp.id ",
                "JOIN trend_directory.trend_store ts ON tsp.trend_store_id = ts.id ",
                "JOIN directory.entity_type et ON ts.entity_type_id = et.id ",
                "JOIN directory.data_source ds ON ts.data_source_id = ds.id"
            ),
            &[],
        )
        .await
        .map(|rows| rows
            .iter()
            .map(|row| TrendDataWithTrendStorePart {
                id: row.get(0),
                is_generated: false,
                name: row.get(1),
                trend_store_part: row.get(2),
                entity_type: row.get(3),
                data_source: row.get(4),
                granularity: parse_interval(row.get(5)).unwrap(),
                data_type: row.get(6),
            })
            .collect()
        )?;

    let generated_table_trends: Vec<TrendDataWithTrendStorePart> = client
        .query(
            concat!(
                "SELECT t.id, t.name, tsp.name, et.name, ds.name, ts.granularity::text, t.data_type ",
                "FROM trend_directory.generated_table_trend t ",
                "JOIN trend_directory.trend_store_part tsp ON t.trend_store_part_id = tsp.id ",
                "JOIN trend_directory.trend_store ts ON tsp.trend_store_id = ts.id ",
                "JOIN directory.entity_type et ON ts.entity_type_id = et.id ",
                "JOIN directory.data_source ds ON ts.data_source_id = ds.id"
            ),
            &[],
        )
        .await
        .map(|rows| rows
            .iter()
            .map(|row| TrendDataWithTrendStorePart {
                id: row.get(0),
                is_generated: true,
                name: row.get(1),
                trend_store_part: row.get(2),
                entity_type: row.get(3),
                data_source: row.get(4),
                granularity: parse_interval(row.get(5)).unwrap(),
                data_type: row.get(6),
            })
            .collect()
        )?;

    let trends: Vec<&TrendDataWithTrendStorePart> =
        table_trends.iter().chain(&generated_table_trends).collect();

    Ok(HttpResponse::Ok().json(trends))
}

#[utoipa::path(
    get,
    path="/trendsentitytype/{et}",
    responses(
    (status = 200, description = "List the name of trend store parts for an entity type", body = [String]),
    (status = 500, description = "Problem interacting with database", body = Error),
    )
)]
#[get("/trendsentitytype/{et}")]
pub(super) async fn get_trends_by_entity_type(
    pool: Data<Pool>,
    et: Path<String>,
) -> Result<HttpResponse, ServiceError> {
    let entity_type = et.into_inner();

    let mut manager = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let client: &mut tokio_postgres::Client = manager.deref_mut().deref_mut();

    let mut transaction = client.transaction().await?;

    let table_trends = get_table_trends_by_entity_type(&mut transaction, &entity_type).await?;
    let view_trends = get_view_trends_by_entity_type(&mut transaction, &entity_type).await?;

    transaction.commit().await?;

    let trends: Vec<&String> = table_trends.iter().chain(&view_trends).collect();

    Ok(HttpResponse::Ok().json(trends))
}

async fn get_table_trends_by_entity_type<T: GenericClient + Send + Sync>(
    client: &mut T,
    entity_type: &str,
) -> Result<Vec<String>, ServiceError> {
    let names: Vec<String> = client
        .query(
            concat!(
                "SELECT t.name ",
                "FROM trend_directory.table_trend t ",
                "JOIN trend_directory.trend_store_part tsp ON t.trend_store_part_id = tsp.id ",
                "JOIN trend_directory.trend_store ts ON tsp.trend_store_id = ts.id ",
                "JOIN directory.entity_type et ON ts.entity_type_id = et.id ",
                "WHERE et.name = $1 AND ts.granularity::text = $2 ",
                "GROUP BY t.name ",
                "ORDER BY t.name",
            ),
            &[&entity_type, &DEFAULT_GRANULARITY.to_string()],
        )
        .await
        .map(|rows| rows.iter().map(|row| row.get(0)).collect())?;

    Ok(names)
}

async fn get_view_trends_by_entity_type<T: GenericClient + Send + Sync>(
    client: &mut T,
    entity_type: &str,
) -> Result<Vec<String>, ServiceError> {
    let names: Vec<String> = client
        .query(
            concat!(
                "SELECT t.name ",
                "FROM trend_directory.view_trend t ",
                "JOIN trend_directory.trend_view_part tvp ON t.trend_view_part_id = tvp.id ",
                "JOIN trend_directory.trend_view tv ON tvp.trend_view_id = tv.id ",
                "JOIN directory.entity_type et ON tv.entity_type_id = et.id ",
                "WHERE et.name = $1 AND tv.granularity::text = $2 ",
                "GROUP BY t.name ",
                "ORDER BY t.name",
            ),
            &[&entity_type, &DEFAULT_GRANULARITY.to_string()],
        )
        .await
        .map(|rows| rows.iter().map(|row| row.get(0)).collect())?;

    Ok(names)
}
