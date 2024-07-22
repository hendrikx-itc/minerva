use deadpool_postgres::Pool;
use std::ops::DerefMut;

use actix_web::{get, put, web::Data, HttpResponse};

use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use serde_json::Map;

use minerva::trigger::{
    list_triggers, load_thresholds_with_client, load_trigger, set_thresholds, set_enabled, Threshold,
};

use super::serviceerror::{ServiceError, ExtendedServiceError, ServiceErrorKind};
use crate::error::{Error, Success};

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct TriggerData {
    name: String,
    enabled: bool,
    description: String,
    thresholds: Vec<Threshold>,
}

#[utoipa::path(
    get,
    path="/triggers",
    responses(
    (status = 200, description = "List of existing triggers", body = [TriggerData]),
    (status = 500, description = "Database unreachable", body = Error),
    )
)]
#[get("/triggers")]
pub(super) async fn get_triggers(pool: Data<Pool>) -> Result<HttpResponse, ServiceError> {
    let mut manager = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let client: &mut tokio_postgres::Client = manager.deref_mut().deref_mut();
    let triggerdata = list_triggers(client).await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    let mut result: Vec<TriggerData> = [].to_vec();

    for trigger in triggerdata.iter() {
        let thresholds = load_thresholds_with_client(client, &trigger.name)
            .await
            .map_err(|e| Error {
                code: 500,
                message: e.to_string(),
            })?;
        result.push(TriggerData {
            name: trigger.name.clone(),
            enabled: trigger.enabled,
            description: trigger.description.clone(),
            thresholds,
        })
    }

    Ok(HttpResponse::Ok().json(result))
}

// curl -H "Content-Type: application/json" -X PUT -d '{"name":"average-output","entity_type":"Cell","data_type":"numeric","enabled":true,"source_trends":["L.Thrp.bits.UL.NsaDc"],"definition":"public.safe_division(SUM(\"L.Thrp.bits.UL.NsaDc\"),1000::numeric)","description":{"type": "ratio", "numerator": [{"type": "trend", "value": "L.Thrp.bits.UL.NsaDC"}], "denominator": [{"type": "constant", "value": "1000"}]}}' localhost:8000/triggers
#[utoipa::path(
    put,
    path="/triggers",
    responses(
    (status = 200, description = "Updated trigger", body = Success),
    (status = 400, description = "Input format incorrect", body = Error),
    (status = 404, description = "Trigger not found", body = Error),
    (status = 409, description = "Update failed", body = Error),
    (status = 500, description = "General error", body = Error)
    )
)]
#[put("/triggers")]
pub(super) async fn change_thresholds(
    pool: Data<Pool>,
    post: String,
) -> Result<HttpResponse, ExtendedServiceError> {
    let data: TriggerData = serde_json::from_str(&post).map_err(|e| Error {
        code: 400,
        message: e.to_string(),
    })?;

    let mut manager = pool.get().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    let client: &mut tokio_postgres::Client = manager.deref_mut().deref_mut();

    let mut transaction = client.transaction().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    let mut trigger = load_trigger(&mut transaction, &data.name)
        .await
        .map_err(|e| Error {
            code: 404,
            message: e.to_string(),
        })?;

    let mut reports = Map::new();

    for threshold in &data.thresholds {
        match trigger.thresholds.iter().find(|th| th.name == threshold.name) {
            Some(_) => {},
            None => {
                reports.insert(threshold.name.clone(), "This field is required".into());
            }
        }
    }

    for threshold in &trigger.thresholds {
        match data.thresholds.iter().find(|th| th.name == threshold.name) {
            Some(_) => {},
            None => {
                reports.insert(threshold.name.clone(), "This field does not exist".into());
            }
        }
    }

    if !reports.is_empty() {
        Ok(HttpResponse::Conflict().json(ExtendedServiceError {
            kind: ServiceErrorKind::BadRequest,
            messages: reports,
        }))

    } else {

        trigger.thresholds = data.thresholds;
        trigger.enabled = data.enabled;
        trigger.description = data.description;

        set_thresholds(&trigger, &mut transaction)
            .await
            .map_err(|e| Error {
                code: 409,
                message: e.to_string(),
            })?;

        set_enabled(&mut transaction, &trigger.name, data.enabled)
            .await
            .map_err(|e| Error {
                code: 409,
                message: e.to_string(),
            })?;

        transaction.commit().await.map_err(|e| Error {
            code: 409,
            message: e.to_string(),
        })?;

        Ok(HttpResponse::Ok().json(Success {
            code: 200,
            message: "trigger updated".to_string(),
        }))
    }
}
