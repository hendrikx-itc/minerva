use std::fmt;

use serde::{Deserialize, Serialize};

use chrono::{DateTime, Utc};
use tokio_postgres::{Client, Transaction};

use async_trait::async_trait;

use super::change::{ChangeResult, Change};
use super::error::{Error, DatabaseError, RuntimeError, DatabaseErrorKind};

type PostgresName = String;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct EntitySet {
    pub name: PostgresName,
    pub group: String,
    pub entity_type: String,
    pub owner: String,
    pub description: String,
    pub entities: Vec<String>,
    pub created: DateTime<Utc>,
    pub modified: DateTime<Utc>,
}

impl fmt::Display for EntitySet {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "EntitySet({}:{})", &self.owner, &self.name,)
    }
}

async fn get_entity_set_members(
    conn: &mut Client,
    id: i32,
) -> Result<Vec<String>, String> {
    let query = "SELECT relation_directory.get_entity_set_members($1)";
    let row = conn.query_one(query, &[&id]).await.map_err(|e| format!("{e}"))?;
    Ok(row.get(0))
}

pub async fn load_entity_sets(
    conn: &mut Client,
) -> Result<Vec<EntitySet>, String> {
    let query = concat!(
        "SELECT name, \"group\", source_entity_type, owner, description, ",
        "id, first_appearance, modified ",
        "FROM attribute.minerva_entity_set es"
    );

    let rows = conn.query(query, &[])
        .await
        .map_err(|e| format!("Error loading entity sets: {e}"))?;

    let mut entity_sets: Vec<EntitySet> = vec!();

    for row in rows {
        let entities = get_entity_set_members(conn, row.get(5))
            .await
            .map_err(|e| format!("Error loading entity set content: {e}"))?;

        entity_sets.push(
            EntitySet {
                name: row.get(0),
                group: row.get(1),
                entity_type: row.get(2),
                owner: row.get(3),
                description: row.try_get(4).unwrap_or("".into()),
                entities,
                created: row.get(6),
                modified: row.get(7),
            }
        )
    };
     
    Ok(entity_sets)
}

pub async fn load_entity_set(
    conn: &mut Client,
    owner: &str,
    name: &str
) -> Result<EntitySet, String> {
    let query = concat!(
        "SELECT name, \"group\", source_entity_type, owner, description, ",
        "entity_set.get_entity_set_members(es.id), first_appearance, modified ",
        "FROM attribute.minerva_entity_set es ",
        "WHERE es.owner = $1 AND es.name = $2"
    );

    let row = conn.query_one(query, &[&owner, &name]).await.map_err(|e| {
        format!("Could not load entity set {owner}:{name}: {e}")
    })?;

    let entity_set = EntitySet {
            name: row.get(0),
            group: row.get(1),
            entity_type: row.get(2),
            owner: row.get(3),
            description: row.try_get(4).unwrap_or("".into()),
            entities: row.get(5),
            created: row.get(6),
            modified: row.get(7),
    };

    Ok(entity_set)
}

pub struct ChangeEntitySet {
    pub entity_set: EntitySet,
    pub entities: Vec<String>
}

impl fmt::Display for ChangeEntitySet {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "ChangeEntitySet({}:{})", &self.entity_set.owner, &self.entity_set.name)
    }
}

#[async_trait]
impl Change for ChangeEntitySet {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let entitieslist = self.entities.join("', '");
        let prequery = "SELECT id FROM attribute.minerva_entity_set es WHERE es.owner = $1 AND es.name = $2".to_string();
        let prerow = client.query_one(
            &prequery,
            &[&self.entity_set.owner, &self.entity_set.name]
        )
        .await
        .map_err(|e| {
            DatabaseError::from_msg(format!(
                "Error changing entity set '{}:{}': {}",
                &self.entity_set.owner, &self.entity_set.name, e
            ))
        })?;
        let id:i32 = prerow.get(0);

        let query = format!(
            concat!(
                "SELECT relation_directory.change_set_entities_guarded({}, ARRAY['{}'])"
            ),
            id.to_string(),
            entitieslist
        );
        let row = client.query_one(
            &query,
            &[]
        )
        .await
        .map_err(|e| {
            DatabaseError::from_msg(format!(
                "Error changing entity set '{}:{}': {}",
                &self.entity_set.owner, &self.entity_set.name, e
            ))
        })?;

        let missing_entities:Vec<String> = row.get(0);

        if missing_entities.is_empty() {
            Ok("Entity set updated".to_string())
        } else {
            let missing_entities_list = missing_entities.join(", ");
            Err(
                Error::Runtime(
                    RuntimeError::from_msg(
                        format!(
                            "The following entities do not exist: {}", missing_entities_list
                        )
            )))
        }
    }
}

pub struct CreateEntitySet {
    pub entity_set: EntitySet
}

impl fmt::Display for CreateEntitySet {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "CreateEntitySet({}:{})", &self.entity_set.owner, &self.entity_set.name)
    }
}

#[async_trait]
impl Change for CreateEntitySet {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let row = client.query_one(
            "SELECT relation_directory.entity_set_exists($1, $2)",
            &[&self.entity_set.owner, &self.entity_set.name]
        )
        .await
        .map_err(|e| {
            DatabaseError::from_msg(format!(
                "Error checking existence of entity set '{}:{}': {}",
                &self.entity_set.owner, &self.entity_set.name, e
            ))
        })?;

        match row.get(0) {
            true => Err(
                Error::Database(
                    DatabaseError{
                        msg: format!(
                            "An entity set with name {} and owner {} already exists.",
                            &self.entity_set.name,
                            &self.entity_set.owner,
                        ),
                        kind: DatabaseErrorKind::UniqueViolation
                    }
                )
            ),
            false => {
                let entitieslist = self.entity_set.entities.join("', '");
                let query = format!(
                    concat!(
                        "SELECT relation_directory.create_entity_set_guarded(",
                        "$1, $2, $3, $4, $5, ARRAY['{}'])"
                    ),
                    entitieslist
                );

                let row = client.query_one(
                    &query,
                    &[
                        &self.entity_set.name, 
                        &self.entity_set.group, 
                        &self.entity_set.entity_type, 
                        &self.entity_set.owner, 
                        &self.entity_set.description,
                    ]
                )
                .await
                .map_err(|e| {
                    DatabaseError::from_msg(format!(
                        "Error creating entity set '{}:{}': {}",
                        &self.entity_set.owner, &self.entity_set.name, e
                    ))
                })?;
        
                let missing_entities:Vec<String> = row.get(0);
        
                if missing_entities.is_empty() {
                    Ok("Entity set created".to_string())
                } else {
                    let missing_entities_list = missing_entities.join(", ");
                    Err(
                        Error::Runtime(
                            RuntimeError::from_msg(
                                format!(
                                    "The following entities do not exist: {}", missing_entities_list
                                )
                    )))
                }

            }
        }
    }
}
