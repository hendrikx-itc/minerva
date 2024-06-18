use std::fmt;
use std::path::PathBuf;

use serde::{Deserialize, Serialize};
use tokio_postgres::Transaction;

use async_trait::async_trait;

use crate::change::ChangeResult;

use super::change::Change;
use super::error::{ConfigurationError, DatabaseError, Error, RuntimeError};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Relation {
    pub name: String,
    pub query: String,
}

impl fmt::Display for Relation {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Relation({})", &self.name)
    }
}

pub fn load_relation_from_file(path: &PathBuf) -> Result<Relation, Error> {
    let f = std::fs::File::open(path).map_err(|e| {
        ConfigurationError::from_msg(format!(
            "Could not open relation definition file '{}': {}",
            path.display(),
            e
        ))
    })?;

    if path.extension() == Some(std::ffi::OsStr::new("yaml")) {
        let relation: Relation = serde_yaml::from_reader(f).map_err(|e| {
            RuntimeError::from_msg(format!(
                "Could not read relation definition from file '{}': {}",
                path.display(),
                e
            ))
        })?;

        Ok(relation)
    } else if path.extension() == Some(std::ffi::OsStr::new("json")) {
        let relation: Relation = serde_json::from_reader(f).map_err(|e| {
            RuntimeError::from_msg(format!(
                "Could not read relation definition from file '{}': {}",
                path.display(),
                e
            ))
        })?;

        Ok(relation)
    } else {
        return Err(ConfigurationError::from_msg(format!(
            "Unsupported relation definition format '{}'",
            path.extension().unwrap().to_string_lossy()
        ))
        .into());
    }
}

pub struct AddRelation {
    pub relation: Relation,
}

impl fmt::Display for AddRelation {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "AddRelation({})", &self.relation)
    }
}

#[async_trait]
impl Change for AddRelation {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let query = format!(
            "CREATE TABLE relation.\"{}\"(source_id integer, target_id integer)",
            self.relation.name
        );
        client
            .query(&query, &[])
            .await
            .map_err(|e| DatabaseError::from_msg(format!("Error creating relation table: {e}")))?;

        let query = format!(
            "CREATE VIEW relation_def.\"{}\" AS {}",
            self.relation.name, self.relation.query
        );

        client
            .query(&query, &[])
            .await
            .map_err(|e| DatabaseError::from_msg(format!("Error creating relation view: {e}")))?;

        let query = format!(
            "CREATE UNIQUE INDEX ON relation.\"{}\"(source_id, target_id)",
            self.relation.name
        );

        client.query(&query, &[]).await.map_err(|e| {
            DatabaseError::from_msg(format!("Error creating index on relation table: {e}"))
        })?;

        let query = format!(
            "CREATE INDEX ON relation.\"{}\"(target_id)",
            self.relation.name
        );

        client.query(&query, &[]).await.map_err(|e| {
            DatabaseError::from_msg(format!("Error creating index on relation table: {e}"))
        })?;

        // Make the table available on each of the Citus nodes.
        let query = format!(
            "SELECT create_reference_table('relation.\"{}\"')",
            self.relation.name
        );

        client.query(&query, &[]).await.map_err(|e| {
            DatabaseError::from_msg(format!(
                "Error converting relation table to reference table: {e}"
            ))
        })?;

        let query = "SELECT relation_directory.register_type($1)";

        client
            .query_one(query, &[&self.relation.name])
            .await
            .map_err(|e| DatabaseError::from_msg(format!("Error registering relation: {e}")))?;

        Ok(format!("Added relation {}", &self.relation))
    }
}

impl From<Relation> for AddRelation {
    fn from(relation: Relation) -> Self {
        AddRelation { relation }
    }
}
