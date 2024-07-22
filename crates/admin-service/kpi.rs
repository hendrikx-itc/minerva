use lazy_static::lazy_static;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use std::ops::DerefMut;
use std::time::Duration;
use utoipa::ToSchema;

use deadpool_postgres::Pool;

use actix_web::{delete, get, post, put, web::Data, web::Path, HttpResponse};

use serde_json::json;
use tokio_postgres::{types::Type, GenericClient, Transaction};

use minerva::interval::parse_interval;
use minerva::trend_materialization::map_sql_to_plpgsql;

use crate::trendmaterialization::{
    TrendFunctionMaterializationData, TrendMaterializationFunctionData,
    TrendMaterializationSourceData, TrendMaterializationSourceIdentifier,
};
use crate::trendstore::{TrendData, TrendStorePartCompleteData};

use super::serviceerror::{ServiceError, ServiceErrorKind};
use crate::error::{Error, Success};

lazy_static! {
    static ref DATASOURCE: String = "kpi".to_string();
    static ref DESCRIPTION: String = "".to_string();
    static ref GRANULARITIES: Vec<String> = vec![
        "15m".to_string(),
        "1h".to_string(),
        "1d".to_string(),
        "1w".to_string(),
        "1month".to_string()
    ];
    static ref LANGUAGE: String = "PLPGSQL".to_string();
    static ref TIME_AGGREGATION: String = "SUM".to_string();
    static ref ENTITY_AGGREGATION: String = "SUM".to_string();
    static ref MAPPING_FUNCTION: String = "trend.mapping_id".to_string();
    static ref DEFAULT_GRANULARITY: String = "1d".to_string();
    static ref PROCESSING_DELAY: HashMap<String, Duration> = HashMap::from([
        ("15m".to_string(), parse_interval("10m").unwrap()),
        ("1h".to_string(), parse_interval("10m").unwrap()),
        ("1d".to_string(), parse_interval("30m").unwrap()),
        ("1w".to_string(), parse_interval("30m").unwrap()),
        ("1month".to_string(), parse_interval("30m").unwrap()),
    ]);
    static ref STABILITY_DELAY: HashMap<String, Duration> = HashMap::from([
        ("15m".to_string(), parse_interval("5m").unwrap()),
        ("1h".to_string(), parse_interval("5m").unwrap()),
        ("1d".to_string(), parse_interval("5m").unwrap()),
        ("1w".to_string(), parse_interval("5m").unwrap()),
        ("1month".to_string(), parse_interval("5m").unwrap()),
    ]);
    static ref REPROCESSING_PERIOD: HashMap<String, Duration> = HashMap::from([
        ("15m".to_string(), parse_interval("3 days").unwrap()),
        ("1h".to_string(), parse_interval("3 days").unwrap()),
        ("1d".to_string(), parse_interval("3 days").unwrap()),
        ("1w".to_string(), parse_interval("3 days").unwrap()),
        ("1month".to_string(), parse_interval("3 days").unwrap())
    ]);
    static ref PARTITION_SIZE: HashMap<String, Duration> = HashMap::from([
        ("15m".to_string(), parse_interval("1d").unwrap()),
        ("1h".to_string(), parse_interval("4d").unwrap()),
        ("1d".to_string(), parse_interval("3mons").unwrap()),
        ("1w".to_string(), parse_interval("1y").unwrap()),
        ("1month".to_string(), parse_interval("5y").unwrap())
    ]);
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct Kpi {
    pub trend_store_part: TrendStorePartCompleteData,
    pub materialization: TrendFunctionMaterializationData,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TrendInfo {
    pub name: String,
    pub data_type: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct KpiRawData {
    pub tsp_name: String,
    pub kpi_name: String,
    pub entity_type: String,
    pub data_type: String,
    pub enabled: bool,
    pub source_trends: Vec<String>,
    pub definition: String,
    pub description: Value,
}

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct KpiImplementedData {
    pub tsp_name: String,
    pub kpi_name: String,
    pub entity_type: String,
    pub data_type: String,
    pub enabled: bool,
    pub source_trendstore_parts: Vec<String>,
    pub definition: String,
    pub description: Value,
}

#[derive(Eq, PartialOrd, Ord, PartialEq)]
pub struct Source {
    pub name: String,
    pub relation: Option<String>,
}

async fn get_source<T: GenericClient + Send + Sync>(
    client: &mut T,
    trend_name: &str,
    entity_type: &str,
) -> Result<Source, String> {
    // First go look for a regular table trend
    let query = concat!(
        "SELECT tsp.name ",
        "FROM trend_directory.table_trend t ",
        "JOIN trend_directory.trend_store_part tsp ON t.trend_store_part_id = tsp.id ",
        "JOIN trend_directory.trend_store ts ON tsp.trend_store_id = ts.id ",
        "JOIN directory.entity_type et ON ts.entity_type_id = et.id ",
        "WHERE t.name = $1 AND ts.granularity = $2::interval AND et.name = $3"
    );

    let statement = client
        .prepare_typed(query, &[Type::TEXT, Type::TEXT, Type::TEXT])
        .await
        .map_err(|e| format!("Could not prepare statement: {e}"))?;

    let rows = client
        .query(
            &statement,
            &[&trend_name, &*DEFAULT_GRANULARITY, &entity_type],
        )
        .await
        .map_err(|e| {
            format!(
                "Error searching for source trend store part for trend '{}': {e}",
                &trend_name
            )
        })?;

    if rows.len() == 1 {
        let row = rows.first().unwrap();

        let tsp: String = row.get(0);

        return Ok(Source {
            name: tsp,
            relation: None,
        });
    }

    // Otherwise go look for a view based trend
    let query = concat!(
        "SELECT tvp.name ",
        "FROM trend_directory.view_trend t ",
        "JOIN trend_directory.trend_view_part tvp ON t.trend_view_part_id = tvp.id ",
        "JOIN trend_directory.trend_view tv ON tvp.trend_view_id = tv.id ",
        "JOIN directory.entity_type et ON tv.entity_type_id = et.id ",
        "WHERE t.name = $1 AND tv.granularity = $2::interval AND et.name = $3"
    );

    let statement = client
        .prepare_typed(query, &[Type::TEXT, Type::TEXT, Type::TEXT])
        .await
        .map_err(|e| format!("Could not prepare statement: {e}"))?;

    let row = client
        .query_one(
            &statement,
            &[&trend_name, &*DEFAULT_GRANULARITY, &entity_type],
        )
        .await
        .map_err(|_| {
            format!(
                "Could not find source trend store part for trend '{}', granularity '{}', entity type '{}'",
                &trend_name,
                &*DEFAULT_GRANULARITY,
                &entity_type,
            )
        })?;

    let tsp: String = row.get(0);

    Ok(Source {
        name: tsp,
        relation: None,
    })
}

impl KpiRawData {
    async fn get_implemented_data<T: GenericClient + Send + Sync>(
        &self,
        client: &mut T,
    ) -> Result<KpiImplementedData, String> {
        let mut sources: Vec<String> = vec![];

        for source_trend in self.source_trends.iter() {
            let source = get_source(client, source_trend, &self.entity_type).await?;

            sources.push(source.name);
        }

        sources.sort();
        sources.dedup();

        Ok(KpiImplementedData {
            tsp_name: self.tsp_name.clone(),
            kpi_name: self.kpi_name.clone(),
            entity_type: self.entity_type.clone(),
            data_type: self.data_type.clone(),
            enabled: self.enabled,
            source_trendstore_parts: sources,
            definition: self.definition.clone(),
            description: self.description.clone(),
        })
    }

    async fn get_kpi(
        &self,
        granularity: String,
        transaction: &mut Transaction<'_>,
    ) -> Result<Kpi, String> {
        let implementedkpi = self.get_implemented_data(transaction).await?;

        let kpi = implementedkpi.get_kpi(transaction, granularity).await.map_err(|e| format!("Could not define KPI: {e:?}"))?;
        
        kpi.ok_or("So such KPI found".into())
    }

    async fn create(
        &self,
        transaction: &mut Transaction<'_>,
    ) -> Result<String, Error> {
        let implementedkpi = self.get_implemented_data(transaction).await.map_err(|e| Error {
            code: 404,
            message: e,
        })?;

        implementedkpi.create(transaction).await
    }
}

/// Find the source trend store parts for a trend view
async fn get_view_sources(
    transaction: &mut Transaction<'_>,
    view_name: &str,
) -> Result<Vec<String>, tokio_postgres::Error> {
    let query = concat!(
        "SELECT c.relname ",
        "FROM trend_directory.trend_view_part tvp ",
        "JOIN pg_class vc on vc.relname = name ",
        "JOIN pg_rewrite rw ON rw.ev_class = vc.oid ",
        "JOIN pg_depend dep ON dep.objid = rw.oid ",
        "JOIN pg_class c ON c.oid = dep.refobjid ",
        "JOIN trend_directory.trend_store_part tsp ON tsp.name = c.relname ",
        "WHERE tvp.name = $1 AND dep.deptype = 'n' ",
        "GROUP BY c.relname"
    );

    let view_sources: Vec<String> = transaction
        .query(query, &[&view_name])
        .await
        .map(|rows| rows.iter().map(|row| row.get(0)).collect())?;

    Ok(view_sources)
}

async fn map_view_sources(
    transaction: &mut Transaction<'_>,
    source_name: &str,
) -> Result<Vec<String>, tokio_postgres::Error> {
    let view_sources = get_view_sources(transaction, source_name).await?;

    if !view_sources.is_empty() {
        Ok(view_sources)
    } else {
        Ok(vec![source_name.to_string()])
    }
}

async fn source_exists<T: GenericClient + Send + Sync>(
    client: &mut T,
    source_name: &str,
) -> Result<bool, tokio_postgres::Error> {
    let query = concat!(
        "SELECT c.relname ",
        "FROM pg_class c ",
        "WHERE c.relname = $1 ",
    );

    let source_relations: Vec<String> = client
        .query(query, &[&source_name])
        .await
        .map(|rows| rows.iter().map(|row| row.get(0)).collect())?;

    let exists = !source_relations.is_empty();

    Ok(exists)
}

impl KpiImplementedData {
    fn target_trend_store_part(&self, granularity: String) -> String {
        format!(
            "{}-{}_{}_{}",
            *DATASOURCE, &self.tsp_name, &self.entity_type, granularity
        )
    }

    async fn get_kpi(
        &self,
        transaction: &mut Transaction<'_>,
        granularity: String,
    ) -> Result<Option<Kpi>, Error> {
        let mut sources: Vec<TrendMaterializationSourceData> = vec![];
        let mut query_sources: Vec<String> = Vec::new();
        let mut modifieds: Vec<String> = vec![];
        let mut formats: Vec<String> = vec![];
        let mut partmodifieds: Vec<String> = vec![];
        let mut joins: Vec<String> = vec![];
        let mut i: i32 = 1;

        for default_source_name in self.source_trendstore_parts.iter() {
            // Map the source name for the default granularity to the requested granularity
            let source_name = default_source_name
                .replace(&DEFAULT_GRANULARITY.to_string(), &granularity.to_string());

            // Check if the source exists
            if !source_exists(transaction, &source_name).await.map_err(|e| Error { code: 500, message: format!("Could not check source existence: {e}") } )? {
                return Ok(None);
            }

            query_sources.push(source_name.clone());

            // Check if the source is a view, and if so, find it's sources
            let source_trend_store_parts = map_view_sources(transaction, &source_name)
                .await
                .map_err(|e| Error {
                    code: 500,
                    message: format!("Could not map source: {e}"),
                })?;

            let actual_source_name = source_trend_store_parts[0].to_string();

            for source_trend_store_part in source_trend_store_parts {
                sources.push(TrendMaterializationSourceData {
                    trend_store_part: source_trend_store_part.clone(),
                    mapping_function: MAPPING_FUNCTION.to_string(),
                });
            }

            modifieds.push(format!("modified{i}.last"));
            formats.push("\"%s\": \"%s\"".to_string());
            partmodifieds.push(format!("part{i}.name, modified{i}.last"));
            joins.push(format!(
                "LEFT JOIN trend_directory.trend_store_part part{} ON part{}.name = '{}'\nJOIN trend_directory.modified modified{} ON modified{}.trend_store_part_id = part{}.id AND modified{}.timestamp = t.timestamp",
                i, i, actual_source_name.clone(), i, i, i, i
            ));

            i += 1;
        }

        let fingerprint_function = format!(
            "SELECT\n  greatest({}),\n  format('{}', {})::jsonb\nFROM (values($1)) as t(timestamp)\n{}",
            modifieds.join(", "),
            "{".to_owned() + &formats.join(", ") + "}",
            partmodifieds.join(", "),
            joins.join("\n")
        );

        let mut sourcestrings: Vec<String> = vec![];
        let mut counter = 1;
        for source in &query_sources {
            match counter {
                1 => sourcestrings.push(format!("trend.\"{}\" t{}", source, counter)),
                _ => sourcestrings.push(format!("trend.\"{}\" t{} ON t1.entity_id = t{}.entity_id and t1.timestamp = t{}.timestamp", source, counter, counter, counter)),
            };
            counter += 1
        }

        let mut src_lines: Vec<String> = Vec::new();

        src_lines.push("SELECT\n".into());
        src_lines.push("  t1.entity_id,\n".into());
        src_lines.push("  $1 AS timestamp,\n".into());
        src_lines.push(format!("  {} AS \"{}\"\n", self.definition, self.kpi_name));
        src_lines.push(format!("FROM {}\n", sourcestrings.join("\nJOIN ")));
        src_lines.push("WHERE t1.timestamp = $1\n".into());
        src_lines.push("GROUP BY t1.entity_id\n".into());

        let function_src = map_sql_to_plpgsql(src_lines.join(""));

        let granularity_interval = parse_interval(&granularity)
            .map_err(|e| 
                Error {
                    code: 500,
                    message: format!("Could not parse granularity '{granularity}': {e}"),
                }
            )?;

        let kpi = Kpi {
            trend_store_part: TrendStorePartCompleteData {
                name: self.target_trend_store_part(granularity.clone()),
                entity_type: self.entity_type.clone(),
                data_source: DATASOURCE.to_string(),
                granularity: granularity_interval,
                partition_size: *PARTITION_SIZE.get(granularity.as_str()).unwrap(),
                trends: vec![TrendData {
                    name: self.kpi_name.clone(),
                    data_type: self.data_type.clone(),
                    time_aggregation: TIME_AGGREGATION.clone(),
                    entity_aggregation: ENTITY_AGGREGATION.clone(),
                    extra_data: json!("{}"),
                    description: DESCRIPTION.clone(),
                }],
                generated_trends: vec![],
            },
            materialization: TrendFunctionMaterializationData {
                enabled: self.enabled,
                target_trend_store_part: self.target_trend_store_part(granularity.clone()),
                processing_delay: PROCESSING_DELAY
                    .get(granularity.as_str())
                    .unwrap()
                    .to_owned(),
                stability_delay: STABILITY_DELAY
                    .get(granularity.as_str())
                    .unwrap()
                    .to_owned(),
                reprocessing_period: REPROCESSING_PERIOD
                    .get(granularity.as_str())
                    .unwrap()
                    .to_owned(),
                sources,
                function: TrendMaterializationFunctionData {
                    return_type: format!(
                        "TABLE (entity_id integer, \"timestamp\" timestamptz, \"{}\" {})",
                        self.kpi_name, self.data_type
                    ),
                    src: function_src,
                    language: LANGUAGE.clone(),
                },
                description: self.description.clone(),
                fingerprint_function,
            },
        };

        Ok(Some(kpi))
    }

    async fn create(
        &self,
        transaction: &mut Transaction<'_>,
    ) -> Result<String, Error> {
        for granularity in GRANULARITIES.iter() {
            if let Some(kpi) = self.get_kpi(transaction, granularity.to_string()).await? {
                kpi.trend_store_part
                    .create(transaction)
                    .await
                    .map_err(|e| Error {
                        code: e.code,
                        message: e.message,
                    })?;

                kpi.materialization
                    .create(transaction)
                    .await
                    .map_err(|e| Error {
                        code: e.code,
                        message: e.message,
                    })?;
            }
        }

        Ok("KPI created".to_string())
    }
}

#[utoipa::path(
    get,
    path="/kpis",
    responses(
    (status = 200, description = "List of existing KPIs", body = [KpiImplementedData]),
    (status = 500, description = "Database unreachable", body = Error),
    )
)]
#[get("/kpis")]
pub(super) async fn get_kpis(pool: Data<Pool>) -> Result<HttpResponse, ServiceError> {
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
            message: e.to_string(),
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

    let result: Vec<KpiImplementedData> = client
        .query(
            concat!(
                "SELECT t.name, tsp.name, et.name, t.data_type, m.enabled, m.id, prosrc, m.description ",
                "FROM trend_directory.table_trend t ",
                "JOIN trend_directory.trend_store_part tsp ON t.trend_store_part_id = tsp.id ",
                "JOIN trend_directory.trend_store ts ON tsp.trend_store_id = ts.id ",
                "JOIN directory.data_source ds ON ts.data_source_id = ds.id ",
                "JOIN directory.entity_type et ON ts.entity_type_id = et.id ",
                "JOIN trend_directory.materialization m ON tsp.id = m.dst_trend_store_part_id ",
                "JOIN trend_directory.function_materialization fm ON m.id = fm.materialization_id ",
                "JOIN pg_proc ON pg_proc.oid = format('%s(timestamptz)', fm.src_function)::regprocedure::oid ",
                "WHERE ds.name = $1 AND ts.granularity = $2::text::interval ",
                "ORDER BY t.name"
            ),
            &[&*DATASOURCE, &*DEFAULT_GRANULARITY]
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| rows
            .iter()
            .map(|row| {
                let mat_id: i32 = row.get(5);
                let this_sources: Vec<String> = sources
                    .iter()
                    .filter(|source| source.materialization == mat_id)
                    .map(|source| source.source.trend_store_part.clone())
                    .collect();

                let full_tsp_name: String = row.get(1);
                let tsp_name = ((full_tsp_name
                    .splitn(2, '-').collect::<Vec<&str>>())[1]
                    .rsplitn(3, '_').collect::<Vec<&str>>())[2];

                KpiImplementedData {
                    kpi_name: row.get(0),
                    tsp_name: tsp_name.to_string(),
                    entity_type: row.get(2),
                    data_type: row.get(3),
                    enabled: row.get(4),
                    source_trendstore_parts: this_sources,
                    definition: row.get(6),
                    description: row.get(7),
                }
            })
            .collect()
        )?;

    Ok(HttpResponse::Ok().json(result))
}

#[utoipa::path(
    get,
    path="/kpis/{name}",
    responses(
    (status = 200, description = "Content of KPI", body = [KpiImplementedData]),
    (status = 404, description = "KPI does not exist", body = Error),
    (status = 500, description = "Database unreachable", body = Error),
    )
)]
#[get("/kpis/{name}")]
pub(super) async fn get_kpi(
    pool: Data<Pool>,
    name: Path<String>,
) -> Result<HttpResponse, ServiceError> {
    let kpiname = name.into_inner().replace('_', " ");

    let client = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;
    let kpi = client
        .query_one(
            concat!(
                "SELECT t.name, tsp.name, et.name, t.data_type, m.enabled, m.id, routine_definition, m.description ",
                "FROM trend_directory.table_trend t ",
                "JOIN trend_directory.trend_store_part tsp ON t.trend_store_part_id = tsp.id ",
                "JOIN trend_directory.trend_store ts ON tsp.trend_store_id = ts.id ",
                "JOIN directory.data_source ds ON ts.data_source_id = ds.id ",
                "JOIN directory.entity_type et ON ts.entity_type_id = et.id ",
                "JOIN trend_directory.materialization m ON tsp.id = m.dst_trend_store_part_id ",
                "JOIN trend_directory.function_materialization fm ON m.id = fm.materialization_id ",
                "JOIN information_schema.routines ON FORMAT('%s.\"%s\"', routine_schema, routine_name) = fm.src_function ",
                "WHERE ds.name = $1 AND ts.granularity = $2 AND t.name = $3"
            ),
            &[&*DATASOURCE, &*DEFAULT_GRANULARITY, &kpiname]
        )
        .await
        .map_err(|_| Error {
            code: 404,
            message: format!("KPI {} not found", &kpiname),
        })?;

    let materialization_id: i32 = kpi.get(5);
    let sources: Vec<String> = client
        .query(
            concat!(
                "SELECT materialization_id, tsp.name, timestamp_mapping_func::text ",
                "FROM trend_directory.materialization_trend_store_link ",
                "JOIN trend_directory.trend_store_part tsp ON trend_store_part_id = tsp.id ",
                "WHERE materialization_id = $1"
            ),
            &[&materialization_id],
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| rows.iter().map(|row| row.get(1)).collect())?;

    let full_tsp_name: String = kpi.get(1);
    let tsp_name = ((full_tsp_name.splitn(2, '-').collect::<Vec<&str>>())[1]
        .rsplitn(3, '_')
        .collect::<Vec<&str>>())[2];

    let result = KpiImplementedData {
        kpi_name: kpi.get(0),
        tsp_name: tsp_name.to_string(),
        entity_type: kpi.get(2),
        data_type: kpi.get(3),
        enabled: kpi.get(4),
        source_trendstore_parts: sources,
        definition: kpi.get(6),
        description: kpi.get(7),
    };

    Ok(HttpResponse::Ok().json(result))
}

// curl -H "Content-Type: application/json" -X POST -d '{"name":"average-output","entity_type":"Cell","data_type":"numeric","enabled":true,"source_trends":["L.Thrp.bits.UL.NsaDc","L.DL.CRS.RateAvg"],"definition":"public.safe_division(SUM(\"L.Thrp.bits.UL.NsaDc\"),SUM(\"L.DL.CRS.RateAvg\") * 1000)","description":{"type": "ratio", "numerator": [{"type": "trend", "value": "L.Thrp.bits.UL.NsaDC"}], "denominator": [{"type": "constant", "value": "1000"}, {"type": "operator", "value": "*"}, {"type": "trend", "value": "L.DL.CRS.RateAvg"}]}}' localhost:8000/kpis

#[utoipa::path(
    post,
    path="/kpis",
    responses(
    (status = 200, description = "Create a new KPI", body = Success),
    (status = 400, description = "Incorrect data format", body = Error),
    (status = 409, description = "KPI creation failed", body = Error),
    (status = 500, description = "Database unreachable", body = Error),
    )
)]
#[post("/kpis")]
pub(super) async fn post_kpi(pool: Data<Pool>, post: String) -> Result<HttpResponse, ServiceError> {
    let data: KpiRawData = serde_json::from_str(&post).map_err(|e| Error {
        code: 400,
        message: format!("Unable to parse input JSON data: {e}"),
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

    transaction.execute("SET LOCAL citus.multi_shard_modify_mode TO 'sequential';", &[]).await?;

    data.create(&mut transaction).await?;

    transaction.commit().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    Ok(HttpResponse::Ok().json(Success {
        code: 200,
        message: "Successfully created KPI".to_string(),
    }))
}

// curl -H "Content-Type: application/json" -X PUT -d '{"name":"average-output","entity_type":"Cell","data_type":"numeric","enabled":true,"source_trends":["L.Thrp.bits.UL.NsaDc"],"definition":"public.safe_division(SUM(\"L.Thrp.bits.UL.NsaDc\"),1000::numeric)","description":{"type": "ratio", "numerator": [{"type": "trend", "value": "L.Thrp.bits.UL.NsaDC"}], "denominator": [{"type": "constant", "value": "1000"}]}}' localhost:8000/kpis
#[utoipa::path(
    put,
    path="/kpis",
    responses(
    (status = 200, description = "Updated KPI", body = Success),
    (status = 400, description = "Input format incorrect", body = Error),
    (status = 404, description = "KPI not found", body = Error),
    (status = 409, description = "Update failed", body = Error),
    (status = 500, description = "General error", body = Error)
    )
)]
#[put("/kpis")]
pub(super) async fn update_kpi(
    pool: Data<Pool>,
    post: String,
) -> Result<HttpResponse, ServiceError> {
    let data: KpiRawData = serde_json::from_str(&post).map_err(|e| Error {
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

    for granularity in GRANULARITIES.iter() {
        let kpi = data
            .get_kpi(granularity.to_string(), &mut transaction)
            .await
            .map_err(|e| Error {
                code: 404,
                message: e,
            })?;

        kpi.materialization.update(&mut transaction).await?;
    }

    transaction.commit().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    Ok(HttpResponse::Ok().json(Success {
        code: 200,
        message: "KPI changed".to_string(),
    }))
}

#[utoipa::path(
    delete,
    path="/kpis/{et}/{name}",
    responses(
    (status = 200, description = "Updated KPI", body = Success),
    (status = 400, description = "Input format incorrect", body = Error),
    (status = 404, description = "KPI not found", body = Error),
    (status = 409, description = "Update failed", body = Error),
    (status = 500, description = "General error", body = Error)
    )
)]
#[delete("/kpis/{et}/{name}")]
pub(super) async fn delete_kpi(
    pool: Data<Pool>,
    args: Path<(String, String)>,
) -> Result<HttpResponse, ServiceError> {
    let kpiname = &args.1;
    let entitytype = &args.0;
    let mut manager = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let client: &mut tokio_postgres::Client = manager.deref_mut().deref_mut();

    let mut transaction = client.transaction().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    let kpi = transaction
        .query_one(
        concat!(
                "SELECT t.name, tsp.name, et.name, t.data_type, m.enabled, m.id, routine_definition, m.description ",
                "FROM trend_directory.table_trend t ",
                "JOIN trend_directory.trend_store_part tsp ON t.trend_store_part_id = tsp.id ",
                "JOIN trend_directory.trend_store ts ON tsp.trend_store_id = ts.id ",
                "JOIN directory.data_source ds ON ts.data_source_id = ds.id ",
                "JOIN directory.entity_type et ON ts.entity_type_id = et.id ",
                "JOIN trend_directory.materialization m ON tsp.id = m.dst_trend_store_part_id ",
                "JOIN trend_directory.function_materialization fm ON m.id = fm.materialization_id ",
                "JOIN information_schema.routines ON FORMAT('%s.\"%s\"', routine_schema, routine_name) = fm.src_function ",
                "WHERE ds.name = $1 AND et.name = $2 AND ts.granularity = $3::text::interval AND t.name = $4",
            ),
            &[&*DATASOURCE, &entitytype, &*DEFAULT_GRANULARITY, &kpiname]
        )
        .await
        .map_err(|_| ServiceError {
            kind: ServiceErrorKind::NotFound,
            message: format!("KPI '{}' not found", &kpiname),
        })?;

    let materialization_id: i32 = kpi.get(5);

    let sources: Vec<String> = transaction
        .query(
            concat!(
                "SELECT materialization_id, tsp.name, timestamp_mapping_func::text ",
                "FROM trend_directory.materialization_trend_store_link ",
                "JOIN trend_directory.trend_store_part tsp ON trend_store_part_id = tsp.id ",
                "WHERE materialization_id = $1"
            ),
            &[&materialization_id],
        )
        .await
        .map_err(|e| Error {
            code: 500,
            message: e.to_string(),
        })
        .map(|rows| rows.iter().map(|row| row.get(1)).collect())?;

    let full_tsp_name: String = kpi.get(1);
    let tsp_name = ((full_tsp_name.splitn(2, '-').collect::<Vec<&str>>())[1]
        .rsplitn(3, '_')
        .collect::<Vec<&str>>())[2];

    let kpidata = KpiImplementedData {
        kpi_name: kpiname.to_string(),
        tsp_name: tsp_name.to_string(),
        entity_type: kpi.get(2),
        data_type: kpi.get(3),
        enabled: kpi.get(4),
        source_trendstore_parts: sources,
        definition: kpi.get(6),
        description: kpi.get(7),
    };

    for granularity in GRANULARITIES.iter() {
        let kpi_result = kpidata
            .get_kpi(&mut transaction, granularity.to_string())
            .await?;

        if let Some(kpi) = kpi_result {
            kpi.materialization
                .as_minerva()
                .delete(&mut transaction)
                .await
                .map_err(|e| Error {
                    code: 409,
                    message: e.to_string(),
                })?;
        };

        transaction
            .query(
                "DELETE FROM trend_directory.trend_store_part WHERE NAME = $1",
                &[&("kpi-".to_string() + tsp_name + "_" + entitytype + "_" + granularity)],
            )
            .await
            .map_err(|e| Error {
                code: 500,
                message: e.to_string(),
            })?;

        transaction
            .query(
                &format!("DROP TABLE trend.\"kpi-{tsp_name}_{entitytype}_{granularity}_staging\""),
                &[],
            )
            .await
            .map_err(|e| Error {
                code: 500,
                message: e.to_string(),
            })?;
    }

    transaction.commit().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    Ok(HttpResponse::Ok().json(Success {
        code: 200,
        message: "KPI deleted".to_string(),
    }))
}
