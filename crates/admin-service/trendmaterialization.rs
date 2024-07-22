use serde_json::Value;
use std::ops::DerefMut;
use std::time::Duration;

use deadpool_postgres::Pool;

use actix_web::{delete, get, post, put, web::Data, web::Path, HttpResponse, Responder};

use serde::{Deserialize, Serialize};
use utoipa::ToSchema;

use minerva::change::Change;
use minerva::interval::parse_interval;
use minerva::trend_materialization::{
    AddTrendMaterialization, TrendFunctionMaterialization, TrendMaterialization,
    TrendMaterializationFunction, TrendMaterializationSource, TrendViewMaterialization,
    UpdateTrendMaterialization,
};
use tokio_postgres::Transaction;

use log::error;

use super::serviceerror::ServiceError;
use crate::error::{Error, Success};
use crate::serviceerror::ServiceErrorKind;

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendMaterializationSourceData {
    pub trend_store_part: String,
    pub mapping_function: String,
}

impl TrendMaterializationSourceData {
    fn as_minerva(&self) -> TrendMaterializationSource {
        TrendMaterializationSource {
            trend_store_part: self.trend_store_part.to_string(),
            mapping_function: self.mapping_function.to_string(),
        }
    }
}

fn as_minerva(sources: &[TrendMaterializationSourceData]) -> Vec<TrendMaterializationSource> {
    let result: Vec<TrendMaterializationSource> =
        sources.iter().map(|source| source.as_minerva()).collect();

    result
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendMaterializationFunctionFull {
    pub name: String,
    pub return_type: String,
    pub src: String,
    pub language: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendMaterializationFunctionData {
    pub return_type: String,
    pub src: String,
    pub language: String,
}

impl TrendMaterializationFunctionData {
    fn as_minerva(&self) -> TrendMaterializationFunction {
        TrendMaterializationFunction {
            return_type: self.return_type.to_string(),
            src: self.src.to_string(),
            language: self.language.to_string(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendMaterializationSourceIdentifier {
    pub materialization: i32,
    pub source: TrendMaterializationSourceData,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendViewMaterializationFull {
    pub id: i32,
    pub materialization_id: i32,
    pub target_trend_store_part: String,
    pub enabled: bool,
    #[serde(with = "humantime_serde")]
    pub processing_delay: Duration,
    #[serde(with = "humantime_serde")]
    pub stability_delay: Duration,
    #[serde(with = "humantime_serde")]
    pub reprocessing_period: Duration,
    pub sources: Vec<TrendMaterializationSourceData>,
    pub view: String,
    pub description: Value,
    pub fingerprint_function: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendFunctionMaterializationFull {
    pub id: i32,
    pub materialization_id: i32,
    pub target_trend_store_part: String,
    pub enabled: bool,
    #[serde(with = "humantime_serde")]
    pub processing_delay: Duration,
    #[serde(with = "humantime_serde")]
    pub stability_delay: Duration,
    #[serde(with = "humantime_serde")]
    pub reprocessing_period: Duration,
    pub sources: Vec<TrendMaterializationSourceData>,
    pub function: TrendMaterializationFunctionFull,
    pub description: Value,
    pub fingerprint_function: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendViewMaterializationData {
    pub target_trend_store_part: String,
    pub enabled: bool,
    #[serde(with = "humantime_serde")]
    pub processing_delay: Duration,
    #[serde(with = "humantime_serde")]
    pub stability_delay: Duration,
    #[serde(with = "humantime_serde")]
    pub reprocessing_period: Duration,
    pub sources: Vec<TrendMaterializationSourceData>,
    pub view: String,
    pub description: Value,
    pub fingerprint_function: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendFunctionMaterializationData {
    pub enabled: bool,
    pub target_trend_store_part: String,
    #[serde(with = "humantime_serde")]
    pub processing_delay: Duration,
    #[serde(with = "humantime_serde")]
    pub stability_delay: Duration,
    #[serde(with = "humantime_serde")]
    pub reprocessing_period: Duration,
    pub sources: Vec<TrendMaterializationSourceData>,
    pub function: TrendMaterializationFunctionData,
    pub description: Value,
    pub fingerprint_function: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub enum TrendMaterializationDef {
    View(TrendViewMaterializationFull),
    Function(TrendFunctionMaterializationFull),
}

impl TrendViewMaterializationData {
    fn as_minerva(&self) -> TrendMaterialization {
        let sources = as_minerva(&(self.sources));
        TrendMaterialization::View(TrendViewMaterialization {
            target_trend_store_part: self.target_trend_store_part.clone(),
            enabled: self.enabled,
            processing_delay: self.processing_delay,
            stability_delay: self.stability_delay,
            reprocessing_period: self.reprocessing_period,
            sources,
            view: self.view.to_string(),
            description: Some(self.description.clone()),
            fingerprint_function: self.fingerprint_function.to_string(),
        })
    }

    pub async fn create(
        &self,
        transaction: &mut Transaction<'_>,
    ) -> Result<TrendViewMaterializationFull, Error> {
        let action = AddTrendMaterialization {
            trend_materialization: self.as_minerva(),
        };
        action.apply(transaction).await.map_err(|e| Error {
            code: 409,
            message: e.to_string(),
        })?;

        let row = transaction
            .query_one(
                concat!(
                    "SELECT vm.id, m.id, pg_views.definition, tsp.name, processing_delay::text, stability_delay::text, reprocessing_period::text, enabled, pg_proc.prosrc, m.description ",
                    "FROM trend_directory.view_materialization vm ",
                    "JOIN trend_directory.materialization m ON vm.materialization_id = m.id ",
                    "JOIN trend_directory.trend_store_part tsp ON dst_trend_store_part_id = tsp.id ",
                    "JOIN pg_proc ON trend_directory.fingerprint_function_name(m) = proname ",
                    "JOIN pg_views ON schemaname = substring(src_view, '(.*?)\\.') AND viewname = substring(src_view, '\"(.*)\"') ",
                    "WHERE tsp.name = $1"
                ),
                &[&self.target_trend_store_part]
            )
            .await
            .map_err(|e| Error {
                code: 404,
                message: format!("Creation reported as succeeded, but could not find created view materialization afterward: {}", &e)
            })?;

        let id: i32 = row.get(0);
        let sources: Vec<TrendMaterializationSourceData> = transaction
            .query(
                concat!(
                    "SELECT tsp.name, timestamp_mapping_func::text ",
                    "FROM trend_directory.materialization_trend_store_link tsl ",
                    "JOIN trend_directory.view_materialization vm ON tsl.materialization_id = vm.materialization_id ",
                    "JOIN trend_directory.trend_store_part tsp ON trend_store_part_id = tsp.id ",
                    "WHERE vm.id = $1"
                ),
                &[&id]
            )
            .await
            .map_err(|e| Error {
                code: 404,
                message: format!("Creation reported as succeeded, but could not find created view materialization afterward: {}", &e)
            })
            .map(|rows| rows
                .iter()
                .map(|row| TrendMaterializationSourceData {
                    trend_store_part: row.get(0),
                    mapping_function: row.get(1),
                })
                .collect()
            )?;

        let materialization = TrendViewMaterializationFull {
            id,
            materialization_id: row.get(1),
            target_trend_store_part: row.get(3),
            enabled: row.get(7),
            processing_delay: parse_interval(row.get(4)).unwrap(),
            stability_delay: parse_interval(row.get(5)).unwrap(),
            reprocessing_period: parse_interval(row.get(6)).unwrap(),
            sources,
            view: row.get(2),
            description: row.get(9),
            fingerprint_function: row.get(8),
        };

        Ok(materialization)
    }
}

impl TrendFunctionMaterializationData {
    pub fn as_minerva(&self) -> TrendMaterialization {
        let sources = as_minerva(&(self.sources));
        TrendMaterialization::Function(TrendFunctionMaterialization {
            target_trend_store_part: self.target_trend_store_part.clone(),
            enabled: self.enabled,
            processing_delay: self.processing_delay,
            stability_delay: self.stability_delay,
            reprocessing_period: self.reprocessing_period,
            sources,
            function: self.function.as_minerva(),
            description: Some(self.description.clone()),
            fingerprint_function: self.fingerprint_function.to_string(),
        })
    }

    pub async fn create(
        &self,
        client: &mut Transaction<'_>,
    ) -> Result<TrendFunctionMaterializationFull, Error> {
        let action = AddTrendMaterialization {
            trend_materialization: self.as_minerva(),
        };

        action.apply(client).await.map_err(|e| Error {
            code: 409,
            message: e.to_string(),
        })?;

        let query = concat!(
            "SELECT fm.id, m.id, src_function, tsp.name, processing_delay::text, stability_delay::text, reprocessing_period::text, enabled, pg_proc.prosrc, data_type, routine_definition, external_language, m.description ",
            "FROM trend_directory.function_materialization fm ",
            "JOIN trend_directory.materialization m ON fm.materialization_id = m.id ",
            "JOIN trend_directory.trend_store_part tsp ON dst_trend_store_part_id = tsp.id ",
            "JOIN information_schema.routines ON FORMAT('%s.\"%s\"', routine_schema, routine_name) = src_function ",
            "LEFT JOIN pg_proc ON routine_name = proname ",
            "WHERE tsp.name = $1"
        );

        let row = client
            .query_one(
                query,
                &[&self.target_trend_store_part],
            )
            .await
            .map_err(|e| {
                error!("Creation reported as succeeded, but could not find created function materialization afterward: {query}");

                Error {
                    code: 404,
                    message: format!("Creation reported as succeeded, but could not find created function materialization afterward: {}", &e)
                }
            })?;

        let id: i32 = row.get(0);
        let sources: Vec<TrendMaterializationSourceData> = client
            .query(
                concat!(
                    "SELECT tsp.name, timestamp_mapping_func::text ",
                    "FROM trend_directory.materialization_trend_store_link tsl ",
                    "JOIN trend_directory.function_materialization vm ON tsl.materialization_id = vm.materialization_id ",
                    "JOIN trend_directory.trend_store_part tsp ON trend_store_part_id = tsp.id ",
                    "WHERE vm.id = $1"
                ),
                &[&id],
            )
            .await
            .map_err(|e| Error { code: 500, message: e.to_string() })
            .map(|rows| rows
                .iter().map(|inner_row|
                    TrendMaterializationSourceData {
                        trend_store_part: inner_row.get(0),
                        mapping_function: inner_row.get(1),
                    }
                ).collect()
            )?;

        let materialization = TrendFunctionMaterializationFull {
            id,
            materialization_id: row.get(1),
            target_trend_store_part: row.get(3),
            enabled: row.get(7),
            processing_delay: parse_interval(row.get(4)).unwrap(),
            stability_delay: parse_interval(row.get(5)).unwrap(),
            reprocessing_period: parse_interval(row.get(6)).unwrap(),
            sources,
            function: TrendMaterializationFunctionFull {
                name: row.get(2),
                return_type: row.get(9),
                src: row.get(10),
                language: row.get(11),
            },
            description: row.get(12),
            fingerprint_function: row.get(8),
        };

        Ok(materialization)
    }

    pub async fn update(
        &self,
        client: &mut Transaction<'_>,
    ) -> Result<Success, Error> {
        client
            .query_one(
                concat!(
                    "SELECT fm.id, m.id ",
                    "FROM trend_directory.function_materialization fm ",
                    "JOIN trend_directory.materialization m ON fm.materialization_id = m.id ",
                    "JOIN trend_directory.trend_store_part tsp ON dst_trend_store_part_id = tsp.id ",
                    "WHERE tsp.name=$1"
                ),
                &[&self.target_trend_store_part],
            )
            .await
            .map_err(|e| Error {
                code: 404,
                message: format!(
                    "No function materialization targetting '{}' found: {}",
                    self.target_trend_store_part,
                    e
                ),
            })?;

        let action = UpdateTrendMaterialization {
            trend_materialization: self.as_minerva(),
        };

        action
            .apply(client)
            .await
            .map_err(|e| Error {
                code: 500,
                message: format!("Update of materialization failed: {e}"),
            })
            .map(|_| {
                Ok(Success {
                    code: 200,
                    message: "Update of materialization succeeded.".to_string(),
                })
            })?
    }
}

/// Get list of trend view materializations.
///
/// List trend view materializations from Minerva database.
///
/// One could call the api endpoint with following curl command.
/// ```text
/// curl localhost:8000/trend-view-materializations
/// ```
#[utoipa::path(
    get,
    path="/trend-view-materializations",
    responses(
        (status = 200, description = "List current trend view materialization items", body = [TrendViewMaterializationFull]),
    (status = 500, description = "Problem interacting with database", body = Error)
    )
)]
#[get("/trend-view-materializations")]
pub(super) async fn get_trend_view_materializations(
    pool: Data<Pool>,
) -> Result<HttpResponse, ServiceError> {
    let client = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let sources: Vec<TrendMaterializationSourceIdentifier> = client
        .query(
            concat!(
                "SELECT materialization_id, tsp.name, timestamp_mapping_func::text ",
                "FROM trend_directory.materialization_trend_store_link ",
                "JOIN trend_directory.trend_store_part tsp ON trend_store_part_id = tsp.id"
            ),
            &[],
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: format!("Unable to list sources: {e}"),
        })
        .map(|rows| {
            rows.iter()
                .map(|row| TrendMaterializationSourceIdentifier {
                    materialization: row.get(0),
                    source: TrendMaterializationSourceData {
                        trend_store_part: row.get(1),
                        mapping_function: row.get(2),
                    },
                })
                .collect()
        })?;

    let materializations: Vec<TrendViewMaterializationFull> = client
        .query(
            concat!(
                "SELECT vm.id, m.id, pg_views.definition, tsp.name, processing_delay::text, stability_delay::text, reprocessing_period::text, enabled, pg_proc.prosrc, m.description ",
                "FROM trend_directory.view_materialization vm ",
                "JOIN trend_directory.materialization m ON vm.materialization_id = m.id ",
                "JOIN trend_directory.trend_store_part tsp ON dst_trend_store_part_id = tsp.id ",
                "JOIN pg_proc ON trend_directory.fingerprint_function_name(m) = proname ",
                "JOIN pg_views ON schemaname = substring(src_view, '(.*?)\\.') AND viewname = substring(src_view, '\"(.*)\"')"
            ),
            &[],
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: format!("Unable to list materializations: {e}"),
        })
        .map(|rows| rows
            .iter()
            .map(|row| {
                let mat_id: i32 = row.get(1);
                let mut this_sources: Vec<TrendMaterializationSourceData> = vec![];
                for source in &sources {
                    if source.materialization == mat_id {
                        this_sources.push(source.source.clone())
                    }
                }
                TrendViewMaterializationFull {
                    id: row.get(0),
                    materialization_id: row.get(1),
                    target_trend_store_part: row.get(3),
                    enabled: row.get(7),
                    processing_delay: parse_interval(row.get(4)).unwrap(),
                    stability_delay: parse_interval(row.get(5)).unwrap(),
                    reprocessing_period: parse_interval(row.get(6)).unwrap(),
                    sources: this_sources,
                    view: row.get(2),
                    description: row.get(9),
                    fingerprint_function: row.get(8),
                }
            })
            .collect()
        )?;

    Ok(HttpResponse::Ok().json(materializations))
}

#[utoipa::path(
    get,
    path="/trend-view-materializations/{id}",
    responses(
    (status = 200, description = "Get a specific view materialization", body = TrendViewMaterializationFull),
    (status = 404, description = "View materialization not found", body = Error),
    (status = 500, description = "Unable to interact with database", body = Error)
    )
)]
#[get("/trend-view-materializations/{id}")]
pub(super) async fn get_trend_view_materialization(
    pool: Data<Pool>,
    id: Path<i32>,
) -> Result<HttpResponse, ServiceError> {
    let vm_id = id.into_inner();

    let client = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let sources: Vec<TrendMaterializationSourceData> = client
        .query(
            concat!(
                "SELECT tsp.name, timestamp_mapping_func::text ",
                "FROM trend_directory.materialization_trend_store_link tsl ",
                "JOIN trend_directory.trend_store_part tsp ON trend_store_part_id = tsp.id ",
                "JOIN trend_directory.view_materialization vm ON tsl.materialization_id = vm.materialization_id ",
                "WHERE vm.id = $1"
            ),
            &[&vm_id],
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| rows
            .iter()
            .map(|row| TrendMaterializationSourceData {
                trend_store_part: row.get(0),
                mapping_function: row.get(1),
            })
            .collect()
        )?;

    let materialization = client
        .query_one(
            concat!(
                "SELECT vm.id, m.id, pg_views.definition, tsp.id, processing_delay::text, stability_delay::text, reprocessing_period::text, enabled, pg_proc.prosrc, m.description ",
                "FROM trend_directory.view_materialization vm ",
                "JOIN trend_directory.materialization m ON vm.materialization_id = m.id ",
                "JOIN trend_directory.trend_store_part tsp ON dst_trend_store_part_id = tsp.id ",
                "JOIN pg_proc ON trend_directory.fingerprint_function_name(m) = proname ",
                "JOIN pg_views ON schemaname = substring(src_view, '(.*?)\\.') AND viewname = substring(src_view, '\"(.*)\"') ",
                "WHERE vm.id = $1"
            ),
            &[&vm_id],
        )
        .await
        .map_err(|_| Error {
            code: 404,
            message: format!("Trend view materialization with id {} not found", &vm_id),
        })
        .map(|row| TrendViewMaterializationFull {
            id: row.get(0),
            materialization_id: row.get(1),
            target_trend_store_part: row.get(3),
            enabled: row.get(7),
            processing_delay: parse_interval(row.get(4)).unwrap(),
            stability_delay: parse_interval(row.get(5)).unwrap(),
            reprocessing_period: parse_interval(row.get(6)).unwrap(),
            sources,
            view: row.get(2),
            description: row.get(9),
            fingerprint_function: row.get(8),
        })?;

    Ok(HttpResponse::Ok().json(materialization))
}

#[utoipa::path(
    get,
    path="/trend-function-materializations",
    responses(
        (status = 200, description = "List current trend function materialization items", body = [TrendFunctionMaterializationFull])
    )
)]
#[get("/trend-function-materializations")]
pub(super) async fn get_trend_function_materializations(pool: Data<Pool>) -> impl Responder {
    let mut m: Vec<TrendFunctionMaterializationFull> = vec![];
    let client_query = pool.get().await;
    match client_query {
        Err(e) => HttpResponse::InternalServerError().json(Error {
            code: 500,
            message: e.to_string(),
        }),
        Ok(client) => {
            let mut sources: Vec<TrendMaterializationSourceIdentifier> = vec![];
            let query = client.query("SELECT materialization_id, tsp.name, timestamp_mapping_func::text FROM trend_directory.materialization_trend_store_link JOIN trend_directory.trend_store_part tsp ON trend_store_part_id = tsp.id", &[],).await;
            match query {
                Err(e) => HttpResponse::InternalServerError().json(Error {
                    code: 500,
                    message: e.to_string(),
                }),
                Ok(query_result) => {
                    for row in query_result {
                        let source = TrendMaterializationSourceIdentifier {
                            materialization: row.get(0),
                            source: TrendMaterializationSourceData {
                                trend_store_part: row.get(1),
                                mapping_function: row.get(2),
                            },
                        };
                        sources.push(source)
                    }

                    let query = client.query("SELECT fm.id, m.id, src_function, tsp.name, processing_delay::text, stability_delay::text, reprocessing_period::text, enabled, pg_proc.prosrc, data_type, routine_definition, external_language, m.description FROM trend_directory.function_materialization fm JOIN trend_directory.materialization m ON fm.materialization_id = m.id JOIN information_schema.routines ON FORMAT('%s.\"%s\"', routine_schema, routine_name) = src_function  JOIN trend_directory.trend_store_part tsp ON dst_trend_store_part_id = tsp.id LEFT JOIN pg_proc ON trend_directory.fingerprint_function_name(m) = proname", &[],).await;
                    match query {
                        Err(e) => HttpResponse::InternalServerError().json(Error {
                            code: 500,
                            message: e.to_string(),
                        }),
                        Ok(query_result) => {
                            for row in query_result {
                                let mat_id: i32 = row.get(1);

                                let mut this_sources: Vec<TrendMaterializationSourceData> = vec![];
                                for source in &sources {
                                    if source.materialization == mat_id {
                                        this_sources.push(source.source.clone())
                                    }
                                }

                                let materialization = TrendFunctionMaterializationFull {
                                    id: row.get(0),
                                    materialization_id: row.get(1),
                                    target_trend_store_part: row.get(3),
                                    enabled: row.get(7),
                                    processing_delay: parse_interval(row.get(4)).unwrap(),
                                    stability_delay: parse_interval(row.get(5)).unwrap(),
                                    reprocessing_period: parse_interval(row.get(6)).unwrap(),
                                    sources: this_sources,
                                    function: TrendMaterializationFunctionFull {
                                        name: row.get(2),
                                        return_type: row.get(9),
                                        src: row.get(10),
                                        language: row.get(11),
                                    },
                                    description: row.get(12),
                                    fingerprint_function: row.get(8),
                                };

                                m.push(materialization)
                            }
                            HttpResponse::Ok().json(m)
                        }
                    }
                }
            }
        }
    }
}

#[utoipa::path(
    get,
    path="/trend-function-materializations/{id}",
    responses(
    (status = 200, description = "Get a specific function materialization", body = TrendFunctionMaterializationFull),
    (status = 404, description = "View function not found", body = Error),
    (status = 500, description = "Unable to interact with database", body = Error)
    )
)]
#[get("/trend-function-materializations/{id}")]
pub(super) async fn get_trend_function_materialization(
    pool: Data<Pool>,
    id: Path<i32>,
) -> impl Responder {
    let fm_id = id.into_inner();

    let result = pool.get().await;
    match result {
        Err(e) => HttpResponse::InternalServerError().json(Error {
            code: 500,
            message: e.to_string(),
        }),
        Ok(client) => {
            let query_result = client.query_one("SELECT fm.id, m.id, src_function, tsp.name, processing_delay::text, stability_delay::text, reprocessing_period::text, enabled, pg_proc.prosrc, data_type, routine_definition, external_language, m.description FROM trend_directory.function_materialization fm JOIN trend_directory.materialization m ON fm.materialization_id = m.id JOIN trend_directory.trend_store_part tsp ON dst_trend_store_part_id = tsp.id JOIN information_schema.routines ON FORMAT('%s.\"%s\"', routine_schema, routine_name) = src_function LEFT JOIN pg_proc ON routine_name = proname WHERE fm.id = $1", &[&fm_id],).await;

            match query_result {
                Err(e) => HttpResponse::NotFound().json(Error {
                    code: 404,
                    message: e.to_string(),
                }),
                Ok(row) => {
                    let mut sources: Vec<TrendMaterializationSourceData> = vec![];
                    let query = client.query("SELECT tsp.name, timestamp_mapping_func::text FROM trend_directory.materialization_trend_store_link tsl JOIN trend_directory.trend_store_part tsp ON trend_store_part_id = tsp.id JOIN trend_directory.view_materialization vm ON tsl.materialization_id = vm.materialization_id WHERE vm.id = $1", &[&fm_id],).await;
                    match query {
                        Err(e) => HttpResponse::InternalServerError().json(Error {
                            code: 500,
                            message: e.to_string(),
                        }),
                        Ok(query_result) => {
                            for inner_row in query_result {
                                let source = TrendMaterializationSourceData {
                                    trend_store_part: inner_row.get(0),
                                    mapping_function: inner_row.get(1),
                                };
                                sources.push(source)
                            }

                            let materialization = TrendFunctionMaterializationFull {
                                id: row.get(0),
                                materialization_id: row.get(1),
                                target_trend_store_part: row.get(3),
                                enabled: row.get(7),
                                processing_delay: parse_interval(row.get(4)).unwrap(),
                                stability_delay: parse_interval(row.get(5)).unwrap(),
                                reprocessing_period: parse_interval(row.get(6)).unwrap(),
                                sources,
                                function: TrendMaterializationFunctionFull {
                                    name: row.get(2),
                                    return_type: row.get(9),
                                    src: row.get(10),
                                    language: row.get(11),
                                },
                                description: row.get(12),
                                fingerprint_function: row.get(8),
                            };

                            HttpResponse::Ok().json(materialization)
                        }
                    }
                }
            }
        }
    }
}

#[utoipa::path(
    get,
    path="/trend-materializations",
    responses(
        (status = 200, description = "List current trend materializations", body = [TrendFunctionMaterializationFull]),
    (status = 500, description = "Unable to correctly interact with database", body = Error)
    )
)]
#[get("/trend-materializations")]
pub(super) async fn get_trend_materializations(pool: Data<Pool>) -> impl Responder {
    let mut m: Vec<TrendMaterializationDef> = vec![];
    let result = pool.get().await;
    match result {
        Err(e) => HttpResponse::InternalServerError().json(Error {
            code: 500,
            message: e.to_string(),
        }),
        Ok(client) => {
            let mut sources: Vec<TrendMaterializationSourceIdentifier> = vec![];
            let query_result = client
                .query(
                    concat!(
                        "SELECT materialization_id, tsp.name, timestamp_mapping_func::text ",
                        "FROM trend_directory.materialization_trend_store_link ",
                        "JOIN trend_directory.trend_store_part tsp ON trend_store_part_id = tsp.id"
                    ),
                    &[],
                )
                .await;

            match query_result {
                Err(e) => HttpResponse::InternalServerError().json(Error {
                    code: 500,
                    message: e.to_string(),
                }),
                Ok(rows) => {
                    for row in rows {
                        let source = TrendMaterializationSourceIdentifier {
                            materialization: row.get(0),
                            source: TrendMaterializationSourceData {
                                trend_store_part: row.get(1),
                                mapping_function: row.get(2),
                            },
                        };
                        sources.push(source)
                    }

                    let query_result = client.query(
                        concat!(
                            "SELECT vm.id, m.id, pg_views.definition, tsp.name, processing_delay::text, stability_delay::text, reprocessing_period::text, enabled, pg_proc.prosrc, m.description ",
                            "FROM trend_directory.view_materialization vm ",
                            "JOIN trend_directory.materialization m ON vm.materialization_id = m.id ",
                            "JOIN trend_directory.trend_store_part tsp ON dst_trend_store_part_id = tsp.id ",
                            "JOIN pg_proc ON trend_directory.fingerprint_function_name(m) = proname ",
                            "JOIN pg_views ON FORMAT('%s.\"%s\"', schemaname, viewname) = src_view"
                        ),
                        &[]
                    ).await;

                    match query_result {
                        Err(e) => HttpResponse::InternalServerError().json(Error {
                            code: 500,
                            message: e.to_string(),
                        }),
                        Ok(rows) => {
                            for row in rows {
                                let mat_id: i32 = row.get(1);

                                let mut this_sources: Vec<TrendMaterializationSourceData> = vec![];
                                for source in &sources {
                                    if source.materialization == mat_id {
                                        this_sources.push(source.source.clone())
                                    }
                                }

                                let materialization =
                                    TrendMaterializationDef::View(TrendViewMaterializationFull {
                                        id: row.get(0),
                                        materialization_id: row.get(1),
                                        target_trend_store_part: row.get(3),
                                        enabled: row.get(7),
                                        processing_delay: parse_interval(row.get(4)).unwrap(),
                                        stability_delay: parse_interval(row.get(5)).unwrap(),
                                        reprocessing_period: parse_interval(row.get(6)).unwrap(),
                                        sources: this_sources,
                                        view: row.get(2),
                                        description: row.get(9),
                                        fingerprint_function: row.get(8),
                                    });

                                m.push(materialization);
                            }

                            let query_result = client.query("SELECT fm.id, m.id, src_function, tsp.name, processing_delay::text, stability_delay::text, reprocessing_period::text, enabled, pg_proc.prosrc, data_type, routine_definition, external_language, m.description FROM trend_directory.function_materialization fm JOIN trend_directory.materialization m ON fm.materialization_id = m.id JOIN trend_directory.trend_store_part tsp ON dst_trend_store_part_id = tsp.id JOIN information_schema.routines ON FORMAT('%s.\"%s\"', routine_schema, routine_name) = src_function LEFT JOIN pg_proc ON trend_directory.fingerprint_function_name(m) = proname", &[],).await;
                            match query_result {
                                Err(e) => HttpResponse::InternalServerError().json(Error {
                                    code: 500,
                                    message: e.to_string(),
                                }),
                                Ok(rows) => {
                                    for row in rows {
                                        let mat_id: i32 = row.get(1);
                                        let mut this_sources: Vec<TrendMaterializationSourceData> =
                                            vec![];
                                        for source in &sources {
                                            if source.materialization == mat_id {
                                                this_sources.push(source.source.clone())
                                            }
                                        }

                                        let materialization = TrendMaterializationDef::Function(
                                            TrendFunctionMaterializationFull {
                                                id: row.get(0),
                                                materialization_id: row.get(1),
                                                target_trend_store_part: row.get(3),
                                                enabled: row.get(7),
                                                processing_delay: parse_interval(row.get(4))
                                                    .unwrap(),
                                                stability_delay: parse_interval(row.get(5))
                                                    .unwrap(),
                                                reprocessing_period: parse_interval(row.get(6))
                                                    .unwrap(),
                                                sources: this_sources,
                                                function: TrendMaterializationFunctionFull {
                                                    name: row.get(2),
                                                    return_type: row.get(9),
                                                    src: row.get(10),
                                                    language: row.get(11),
                                                },
                                                description: row.get(12),
                                                fingerprint_function: row.get(8),
                                            },
                                        );

                                        m.push(materialization)
                                    }

                                    HttpResponse::Ok().json(m)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// To call this with curl: -
// first: DROP TABLE trend."u2020-4g-pm_v-site_lcs_1w_staging";
//        DELETE FROM trend_directory.materialization;
// curl -H "Content-Type: application/json" -X POST -d '{"target_trend_store_part":"u2020-4g-pm_v-site_lcs_1w","enabled":true,"processing_delay":"30m","stability_delay":"5m","reprocessing_period":"3days","sources":[{"trend_store_part": "u2020-4g-pm-kpi_v-cell_capacity-management_15m", "mapping_function": "trend.mapping_id(timestamp with time zone)"}, {"trend_store_part": "u2020-4g-pm-kpi_v-cell_integrity_15m", "mapping_function": "trend.mapping_id(timestamp with time zone)"}],"view":"SELECT r.target_id AS entity_id, t.\"timestamp\", sum(t.samples) AS samples, sum(t.\"L.LCS.EcidMeas.Req\") AS \"L.LCS.EcidMeas.Req\", sum(t.\"L.LCS.EcidMeas.Succ\") AS \"L.LCS.EcidMeas.Succ\", sum(t.\"L.LCS.OTDOAInterFreqRSTDMeas.Succ\") AS \"L.LCS.OTDOAInterFreqRSTDMeas.Succ\" FROM (trend.\"u2020-4g-pm_Cell_lcs_1w\" t JOIN relation.\"Cell->v-site\" r ON (t.entity_id = r.source_id)) GROUP BY t.\"timestamp\", r.target_id;", "fingerprint_function":"SELECT modified.last, '\''{}'\''::jsonb FROM trend_directory.modified JOIN trend_directory.trend_store_part ttsp ON ttsp.id = modified.trend_store_part_id WHERE modified.timestamp = $1;"}' localhost:8000/trend-view-materializations

#[utoipa::path(
    post,
    path="/trend-view-materializations",
    responses(
    (status = 200, description = "Create a new view materialization", body = TrendViewMaterializationFull),
    (status = 400, description = "Incorrect data format", body = Error),
    (status = 404, description = "Materialization cannot be found after creation", body = Error),
    (status = 409, description = "View materialization cannot be created with these data", body = Error),
    (status = 500, description = "Unable to interact with database", body = Error),
    )
)]
#[post("/trend-view-materializations")]
pub(super) async fn post_trend_view_materialization(
    pool: Data<Pool>,
    post: String,
) -> Result<HttpResponse, ServiceError> {
    let data: TrendViewMaterializationData = serde_json::from_str(&post).map_err(|e| Error {
        code: 400,
        message: e.to_string(),
    })?;

    let mut manager = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let client: &mut tokio_postgres::Client = manager.deref_mut().deref_mut();

    let mut transaction = client.transaction().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    data.create(&mut transaction)
        .await
        .map(|materialization| Ok(HttpResponse::Ok().json(materialization)))?
}

// To call this with curl:
// first: DELETE FROM trend_directory.materialization;
// curl -H "Content-Type: application/json" -X POST -d '{"target_trend_store_part":"u2020-4g-pm-traffic-sum_Cell_1month","enabled":true,"processing_delay":"30m","stability_delay":"5m","reprocessing_period":"3days","sources":[{"trend_store_part":"u2020-4g-pm_Cell_channel-l-ca_1month","mapping_function":"trend.mapping_id(timestamp with time zone)"}],"function":{"name":"trend.\"u2020-4g-pm-traffic-sum_Cell_1month\"","return_type":"TABLE(entity_id integer, \"timestamp\" timestamp with time zone, samples numeric, \"L.Traffic.DRB.QCI.1.SUM\" numeric)","src":" BEGIN\r\nRETURN QUERY EXECUTE $query$\r\n    SELECT\r\n      entity_id,\r\n      $2 AS timestamp,\r\n      sum(t.\"samples\") AS \"samples\",\r\n      SUM(t.\"L.Traffic.DRB.QCI.1.SUM\") AS \"L.Traffic.DRB.QCI.1.SUM\"\r\n    FROM trend.\"u2020-4g-pm-traffic-sum_Cell_1d\" AS t\r\n    WHERE $1 < timestamp AND timestamp <= $2\r\n    GROUP BY entity_id\r\n$query$ USING $1 - interval '\''1month'\'', $1;\r\nEND;\r\n","language":"PLPGSQL"},"fingerprint_function":"SELECT max(modified.last), format('\''{%s}'\'', string_agg(format('\''\"%s\":\"%s\"'\'', t, modified.last), '\'','\''))::jsonb\r\nFROM generate_series($1 - interval '\''1month'\'' + interval '\''1d'\'', $1, interval '\''1d'\'') t\r\nLEFT JOIN (\r\n  SELECT timestamp, last\r\n  FROM trend_directory.trend_store_part part\r\n  JOIN trend_directory.modified ON modified.trend_store_part_id = part.id\r\n  WHERE part.name = '\''u2020-4g-pm-traffic-sum_Cell_1d'\''\r\n) modified ON modified.timestamp = t;\r\n"}' localhost:8000/trend-function-materializations

#[utoipa::path(
    post,
    path="/trend-function-materializations",
    responses(
    (status = 200, description = "Create a new view materialization", body = TrendViewMaterializationFull),
    (status = 400, description = "Incorrect data format", body = Error),
    (status = 404, description = "Materialization cannot be found after creation", body = Error),
    (status = 409, description = "View materialization cannot be created with these data", body = Error),
    )
)]
#[post("/trend-function-materializations")]
pub(super) async fn post_trend_function_materialization(
    pool: Data<Pool>,
    post: String,
) -> Result<HttpResponse, ServiceError> {
    let data: TrendFunctionMaterializationData =
        serde_json::from_str(&post).map_err(|e| Error {
            code: 400,
            message: e.to_string(),
        })?;

    let mut manager = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let client: &mut tokio_postgres::Client = manager.deref_mut().deref_mut();

    let mut transaction = client.transaction().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    data.create(&mut transaction)
        .await
        .map(|materialization| Ok(HttpResponse::Ok().json(materialization)))?
}

// curl -X DELETE localhost:8000/trend-view-materializations/1

#[utoipa::path(
    delete,
    path="/trend-view-materializations/{id}",
    responses(
    (status = 200, description = "Deleted function materialization", body = Success),
    (status = 404, description = "Function materialization not found", body = Error),
    (status = 500, description = "Deletion failed fully or partially", body = Error)
    )
)]
#[delete("/trend-view-materializations/{id}")]
pub(super) async fn delete_trend_view_materialization(
    pool: Data<Pool>,
    id: Path<i32>,
) -> impl Responder {
    let vm_id = id.into_inner();
    let query_result = pool.get().await;
    match query_result {
        Err(e) => HttpResponse::InternalServerError().json(Error {
            code: 500,
            message: e.to_string(),
        }),
        Ok(client) => {
            let query_result = client.query_one(
        "SELECT materialization_id FROM trend_directory.view_materialization WHERE id = $1",
        &[&vm_id],
        ).await;
            match query_result {
                Err(e) => HttpResponse::NotFound().json(Error {
                    code: 404,
                    message: "Trend view materialization not found: ".to_owned() + &e.to_string(),
                }),
                Ok(row) => {
                    let m_id: i32 = row.get(0);
                    let result = client
                        .execute(
                            "DELETE FROM trend_directory.view_materialization WHERE id = $1",
                            &[&vm_id],
                        )
                        .await;
                    match result {
                        Err(e) => HttpResponse::InternalServerError().json(Error {
                            code: 500,
                            message: "Deletion failed: ".to_owned() + &e.to_string(),
                        }),
                        Ok(_) => {
                            let result = client
                                .execute(
                                    "DELETE FROM trend_directory.materialization WHERE id = $1",
                                    &[&m_id],
                                )
                                .await;
                            match result {
                                Err(e) => HttpResponse::InternalServerError().json(Error {
                                    code: 500,
                                    message: "Deletion partially failed: ".to_owned()
                                        + &e.to_string(),
                                }),
                                Ok(_) => HttpResponse::Ok().json(Success {
                                    code: 200,
                                    message: "materialization deleted".to_string(),
                                }),
                            }
                        }
                    }
                }
            }
        }
    }
}

#[utoipa::path(
    delete,
    path="/trend-function-materializations/{id}",
    responses(
    (status = 200, description = "Deleted function materialization", body = Success),
    (status = 404, description = "Function materialization not found", body = Error),
    (status = 500, description = "Deletion failed fully or partially", body = Error)
    )
)]
#[delete("/trend-function-materializations/{id}")]
pub(super) async fn delete_trend_function_materialization(
    pool: Data<Pool>,
    id: Path<i32>,
) -> impl Responder {
    let fm_id = id.into_inner();
    let result = pool.get().await;
    match result {
        Err(e) => HttpResponse::InternalServerError().json(Error {
            code: 500,
            message: e.to_string(),
        }),
        Ok(client) => {
            let query_result = client
        .query_one(
            "SELECT materialization_id FROM trend_directory.function_materialization WHERE id = $1",
            &[&fm_id],
        )
        .await;
            match query_result {
                Err(e) => HttpResponse::NotFound().json(Error {
                    code: 404,
                    message: "Trend function materialization not found: ".to_owned()
                        + &e.to_string(),
                }),
                Ok(row) => {
                    let m_id: i32 = row.get(0);
                    let result = client
                        .execute(
                            "DELETE FROM trend_directory.function_materialization WHERE id = $1",
                            &[&fm_id],
                        )
                        .await;
                    match result {
                        Err(e) => HttpResponse::InternalServerError().json(Error {
                            code: 500,
                            message: "Deletion failed: ".to_owned() + &e.to_string(),
                        }),
                        Ok(_) => {
                            let result = client
                                .execute(
                                    "DELETE FROM trend_directory.materialization WHERE id = $1",
                                    &[&m_id],
                                )
                                .await;
                            match result {
                                Err(e) => HttpResponse::InternalServerError().json(Error {
                                    code: 500,
                                    message: "Deletion partially failed: ".to_owned()
                                        + &e.to_string(),
                                }),
                                Ok(_) => HttpResponse::Ok().json(Success {
                                    code: 200,
                                    message: "Function materialization deleted.".to_string(),
                                }),
                            }
                        }
                    }
                }
            }
        }
    }
}

#[utoipa::path(
    put,
    path="/trend-view-materializations",
    responses(
    (status = 200, description = "Updated view materialization", body = Success),
    (status = 400, description = "Input format incorrect", body = Error),
    (status = 404, description = "Function materialization not found", body = Error),
    (status = 500, description = "Deletion failed fully or partially", body = Error)
    )
)]
#[put("/trend-view-materializations")]
pub(super) async fn update_trend_view_materialization(
    pool: Data<Pool>,
    post: String,
) -> Result<HttpResponse, ServiceError> {
    let data: TrendFunctionMaterializationData =
        serde_json::from_str(&post).map_err(|e| Error {
            code: 400,
            message: e.to_string(),
        })?;

    let mut manager = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let client: &mut tokio_postgres::Client = manager.deref_mut().deref_mut();

    let mut transaction = client.transaction().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    data.update(&mut transaction)
        .await
        .map(|success| Ok(HttpResponse::Ok().json(success)))?
}

#[utoipa::path(
    put,
    path="/trend-function-materializations",
    responses(
    (status = 200, description = "Updated function materialization", body = TrendFunctionMaterializationFull),
    (status = 400, description = "Input format incorrect", body = Error),
    (status = 404, description = "Function materialization not found", body = Error),
    (status = 500, description = "Deletion failed fully or partially", body = Error)
    )
)]
#[put("/trend-function-materializations")]
pub(super) async fn update_trend_function_materialization(
    pool: Data<Pool>,
    post: String,
) -> Result<HttpResponse, ServiceError> {
    let data: TrendFunctionMaterializationData =
        serde_json::from_str(&post).map_err(|e| Error {
            code: 400,
            message: e.to_string(),
        })?;

    let mut manager = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let client: &mut tokio_postgres::Client = manager.deref_mut().deref_mut();

    let mut transaction = client.transaction().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    data.update(&mut transaction)
        .await
        .map(|success| Ok(HttpResponse::Ok().json(success)))?
}
