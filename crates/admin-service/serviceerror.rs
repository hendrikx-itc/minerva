use actix_web::error::ResponseError;
use actix_web::{http::StatusCode, HttpResponse};
use core::fmt::Display;
use derive_more::{Display, From};
use log::error;
use serde::Serialize;
use serde_json::{Map, Value};

use super::error::{Error, ExtendedError};

#[derive(Display, From, Debug, Serialize)]
pub enum ServiceErrorKind {
    NotFound,
    PoolError,
    DbError,
    BadRequest,
    InternalError,
}

#[derive(From, Debug)]
pub struct ServiceError {
    pub kind: ServiceErrorKind,
    pub message: String,
}

#[derive(From, Debug, Serialize)]
pub struct ExtendedServiceError {
    pub kind: ServiceErrorKind,
    pub messages: Map<String, Value>,
}

impl Display for ServiceError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "({}) {}", self.kind, self.message)
    }
}

impl Display for ExtendedServiceError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let mut message_description: Vec<String> = vec![];
        for m in self.messages.iter() {
            message_description.push(format!("{}: {}", m.0, m.1))
        }
        write!(f, "({}) {}", self.kind, message_description.join(", "))
    }
}

impl std::error::Error for ServiceError {}

impl std::error::Error for ExtendedServiceError {}

impl ResponseError for ServiceError {
    fn status_code(&self) -> StatusCode {
        match self.kind {
            ServiceErrorKind::NotFound => StatusCode::NOT_FOUND,
            ServiceErrorKind::PoolError => StatusCode::INTERNAL_SERVER_ERROR,
            ServiceErrorKind::DbError => StatusCode::INTERNAL_SERVER_ERROR,
            ServiceErrorKind::BadRequest => StatusCode::BAD_REQUEST,
            ServiceErrorKind::InternalError => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }

    fn error_response(&self) -> HttpResponse {
        let status_code = self.status_code();

        HttpResponse::build(status_code).json(Error {
            code: i32::from(status_code.as_u16()),
            message: self.to_string(),
        })
    }
}

impl ResponseError for ExtendedServiceError {
    fn status_code(&self) -> StatusCode {
        match self.kind {
            ServiceErrorKind::NotFound => StatusCode::NOT_FOUND,
            ServiceErrorKind::PoolError => StatusCode::INTERNAL_SERVER_ERROR,
            ServiceErrorKind::DbError => StatusCode::INTERNAL_SERVER_ERROR,
            ServiceErrorKind::BadRequest => StatusCode::BAD_REQUEST,
            ServiceErrorKind::InternalError => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }

    fn error_response(&self) -> HttpResponse {
        let status_code = self.status_code();

        HttpResponse::build(status_code).json(Error {
            code: i32::from(status_code.as_u16()),
            message: self.to_string(),
        })
    }
}

impl From<tokio_postgres::error::Error> for ServiceError {
    fn from(value: tokio_postgres::error::Error) -> ServiceError {
        error!("{value:?}");

        ServiceError {
            kind: ServiceErrorKind::InternalError,
            message: format!("{value:?}"),
        }
    }
}

impl From<tokio_postgres::error::Error> for ExtendedServiceError {
    fn from(value: tokio_postgres::error::Error) -> ExtendedServiceError {
        error!("{value:?}");

        let mut map = Map::new();
        map.insert("general".to_string(), format!("{value:?}").into());

        ExtendedServiceError {
            kind: ServiceErrorKind::InternalError,
            messages: map,
        }
    }
}

impl From<Error> for ServiceError {
    fn from(value: Error) -> ServiceError {
        error!("{value:?}");

        ServiceError {
            kind: ServiceErrorKind::InternalError,
            message: format!("{value:?}"),
        }
    }
}

impl From<Error> for ExtendedServiceError {
    fn from(value: Error) -> ExtendedServiceError {
        error!("{value:?}");

        let mut map = Map::new();
        map.insert("general".to_string(), format!("{value:?}").into());

        ExtendedServiceError {
            kind: ServiceErrorKind::InternalError,
            messages: map,
        }
    }
}

impl From<ExtendedError> for ExtendedServiceError {
    fn from(value: ExtendedError) -> ExtendedServiceError {
        error!("{value:?}");

        ExtendedServiceError {
            kind: ServiceErrorKind::InternalError,
            messages: value.messages,
        }
    }
}
