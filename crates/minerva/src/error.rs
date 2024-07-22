use std::fmt;

use tokio_postgres::{self, error::SqlState};

#[derive(Debug)]
pub enum DatabaseErrorKind {
    Default,
    UniqueViolation,
}

#[derive(Debug)]
pub struct DatabaseError {
    pub msg: String,
    pub kind: DatabaseErrorKind,
}

fn map_error_kind(sql_state: &SqlState) -> DatabaseErrorKind {
    match sql_state {
        &SqlState::UNIQUE_VIOLATION => DatabaseErrorKind::UniqueViolation,
        _ => DatabaseErrorKind::Default,
    }
}

impl DatabaseError {
    pub fn from_msg(msg: String) -> DatabaseError {
        DatabaseError {
            msg,
            kind: DatabaseErrorKind::Default,
        }
    }
}

impl From<tokio_postgres::Error> for DatabaseError {
    fn from(err: tokio_postgres::Error) -> DatabaseError {
        DatabaseError {
            msg: format!("{err}"),
            kind: err
                .code()
                .map_or(DatabaseErrorKind::Default, map_error_kind),
        }
    }
}

#[derive(Debug)]
pub struct ConfigurationError {
    pub msg: String,
}

impl ConfigurationError {
    pub fn from_msg(msg: String) -> ConfigurationError {
        ConfigurationError { msg }
    }
}

#[derive(Debug)]
pub struct RuntimeError {
    pub msg: String,
}

impl RuntimeError {
    pub fn from_msg(msg: String) -> RuntimeError {
        RuntimeError { msg }
    }
}

impl From<String> for RuntimeError {
    fn from(msg: String) -> RuntimeError {
        RuntimeError { msg }
    }
}

#[derive(Debug)]
pub enum Error {
    Database(DatabaseError),
    Configuration(ConfigurationError),
    Runtime(RuntimeError),
}

impl std::error::Error for Error {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        None
    }

    fn description(&self) -> &str {
        match self {
            Error::Database(_) => "Database error",
            Error::Configuration(_) => "Configuration error",
            Error::Runtime(_) => "Runtime error",
        }
    }

    fn cause(&self) -> Option<&dyn std::error::Error> {
        None
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::Database(e) => write!(f, "{}", &e.msg),
            Error::Configuration(e) => write!(f, "{}", &e.msg),
            Error::Runtime(e) => write!(f, "{}", &e.msg),
        }
    }
}

impl From<DatabaseError> for Error {
    fn from(err: DatabaseError) -> Error {
        Error::Database(err)
    }
}

impl From<ConfigurationError> for Error {
    fn from(err: ConfigurationError) -> Error {
        Error::Configuration(err)
    }
}

impl From<RuntimeError> for Error {
    fn from(err: RuntimeError) -> Error {
        Error::Runtime(err)
    }
}

impl From<tokio_postgres::Error> for Error {
    fn from(err: tokio_postgres::Error) -> Error {
        Error::Database(DatabaseError::from(err))
    }
}

impl From<String> for Error {
    fn from(err: String) -> Error {
        Error::Runtime(RuntimeError {
            msg: err.to_string(),
        })
    }
}
