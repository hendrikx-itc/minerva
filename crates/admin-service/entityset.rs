use deadpool_postgres::Pool;
use serde::{Deserialize, Serialize};
use std::ops::DerefMut;
use utoipa::ToSchema;

use actix_web::{get, post, put, web::Data, web::Json, HttpResponse, Responder};
use chrono::{DateTime, Utc};

use minerva::change::Change;
use minerva::entity_set::{load_entity_sets, ChangeEntitySet, CreateEntitySet, EntitySet};

use super::serviceerror::{ServiceError, ServiceErrorKind};
use crate::error::{Error, Success};

type PostgresName = String;

#[derive(Debug, Serialize, Deserialize, Clone, ToSchema)]
pub struct EntitySetData {
    pub name: PostgresName,
    pub group: Option<String>,
    pub entity_type: Option<String>,
    pub owner: String,
    pub description: Option<String>,
    pub entities: Vec<String>,
    pub created: Option<DateTime<Utc>>,
    pub modified: Option<DateTime<Utc>>,
}

impl EntitySetData {
    fn entity_set(&self) -> EntitySet {
        let group = match &self.group {
            None => "".to_string(),
            Some(value) => value.to_string(),
        };
        let entity_type = match &self.entity_type {
            None => "".to_string(),
            Some(value) => value.to_string(),
        };
        let description = match &self.description {
            None => "".to_string(),
            Some(value) => value.to_string(),
        };
        EntitySet {
            name: self.name.to_string(),
            group,
            entity_type,
            owner: self.owner.to_string(),
            description,
            entities: self.entities.to_vec(),
            created: self.created.unwrap_or(Utc::now()),
            modified: self.modified.unwrap_or(Utc::now()),
        }
    }
}

#[utoipa::path(
    get,
    path="/entitysets",
    responses(
    (status = 200, description = "List of existing entity sets", body = [EntitySet]),
    (status = 500, description = "Database unreachable", body = Error),
    )
)]
#[get("/entitysets")]
pub(super) async fn get_entity_sets(pool: Data<Pool>) -> Result<HttpResponse, ServiceError> {
    let mut manager = pool.get().await.map_err(|_| ServiceError {
        kind: ServiceErrorKind::PoolError,
        message: "".to_string(),
    })?;

    let client: &mut tokio_postgres::Client = manager.deref_mut().deref_mut();

    let data = load_entity_sets(client).await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    Ok(HttpResponse::Ok().json(data))
}

async fn change_entity_set_fn(
    pool: Data<Pool>,
    data: Json<EntitySetData>,
) -> Result<HttpResponse, Error> {
    let mut manager = pool.get().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    let action = ChangeEntitySet {
        entity_set: data.entity_set(),
        entities: data.entities.clone(),
    };

    let mut tx = manager.transaction().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    action.apply(&mut tx).await.map_err(|e| Error {
        code: 409,
        message: format!("Change of entity set failed: {e}"),
    })?;

    tx.commit().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    Ok(HttpResponse::Ok().json(Success {
        code: 200,
        message: "Entity set changed".to_string(),
    }))
}

#[utoipa::path(
    put,
    path="/entitysets",
    responses(
    (status = 200, description = "Changing entity set succeeded", body = Success),
    (status = 400, description = "Request could not be parsed", body = Error),
    (status = 409, description = "Changing entity set failed", body = Error),
    (status = 500, description = "Database unreachable", body = Error),
    )
)]
#[put("/entitysets")]
pub(super) async fn change_entity_set(
    pool: Data<Pool>,
    data: Json<EntitySetData>,
) -> impl Responder {
    let result = change_entity_set_fn(pool, data).await;
    match result {
        Ok(res) => res,
        Err(e) => {
            let err = Error {
                code: e.code,
                message: e.message,
            };
            match err.code {
                400 => HttpResponse::BadRequest().json(err),
                409 => HttpResponse::Conflict().json(err),
                _ => HttpResponse::InternalServerError().json(err),
            }
        }
    }
}

async fn create_entity_set_fn(
    pool: Data<Pool>,
    data: Json<EntitySetData>,
) -> Result<HttpResponse, Error> {
    let mut manager = pool.get().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    let action = CreateEntitySet {
        entity_set: data.entity_set(),
    };

    let mut tx = manager.transaction().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    action.apply(&mut tx).await.map_err(|e| Error {
        code: 409,
        message: format!("Creation of entity set failed: {e}"),
    })?;

    tx.commit().await.map_err(|e| Error {
        code: 500,
        message: e.to_string(),
    })?;

    Ok(HttpResponse::Ok().json(Success {
        code: 200,
        message: "Entity set created".to_string(),
    }))
}

#[utoipa::path(
    post,
    path="/entitysets",
    responses(
    (status = 200, description = "Creating entity set succeeded", body = Success),
    (status = 400, description = "Request could not be parsed", body = Error),
    (status = 409, description = "Creating entity set failed", body = Error),
    (status = 500, description = "Database unreachable", body = Error),
    )
)]
#[post("/entitysets")]
pub(super) async fn create_entity_set(
    pool: Data<Pool>,
    data: Json<EntitySetData>,
) -> impl Responder {
    let result = create_entity_set_fn(pool, data).await;
    match result {
        Ok(res) => res,
        Err(e) => {
            let err = Error {
                code: e.code,
                message: e.message,
            };
            match err.code {
                400 => HttpResponse::BadRequest().json(err),
                409 => HttpResponse::Conflict().json(err),
                _ => HttpResponse::InternalServerError().json(err),
            }
        }
    }
}
