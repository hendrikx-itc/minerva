use std::collections::HashMap;

use postgres_protocol::escape::escape_identifier;
use thiserror::Error;
use tokio_postgres::GenericClient;
use quick_cache::sync::Cache;

use lazy_static::lazy_static;

lazy_static! {
    static ref ENTITY_MAPPING_CACHE: Cache<(String, String), i32> = Cache::new(100000);
}

#[derive(Error, Debug)]
pub enum EntityMappingError {
    #[error("Database error: {0}")]
    DatabaseError(tokio_postgres::Error),
    #[error("Could not create entity: {0}")]
    EntityCreationError(tokio_postgres::Error),
    #[error("Could not insert entity")]
    EntityInsertError,
    #[error("Could not map entity")]
    UnmappedEntityError,
}

pub fn clear_entity_cache() {
    ENTITY_MAPPING_CACHE.clear();
}

pub async fn names_to_entity_ids<T: GenericClient>(
    client: &T,
    entity_type_table: &str,
    names: Vec<String>,
) -> Result<Vec<i32>, EntityMappingError> {
    let mut entity_ids: HashMap<String, i32> = HashMap::new();

    let query = format!(
        "WITH lookup_list AS (SELECT unnest($1::text[]) AS name) \
        SELECT l.name, e.id FROM lookup_list l \
        LEFT JOIN entity.{} e ON l.name = e.name ",
        escape_identifier(entity_type_table)
    );

    let mut names_list: Vec<&str> = Vec::new();

    for name in &names {
        if let Some(entity_id) =
            ENTITY_MAPPING_CACHE.get(&(entity_type_table.to_string(), String::from(name)))
        {
            entity_ids.insert(name.clone(), entity_id);
        } else {
            names_list.push(name.as_ref());
        }
    }

    // Only lookup in the database if there is anything left to lookup
    if !names_list.is_empty() {
        let rows = client
            .query(&query, &[&names_list])
            .await
            .map_err(EntityMappingError::DatabaseError)?;

        for row in rows {
            let name: String = row.get(0);
            let entity_id_value: Option<i32> =
                row.try_get(1).map_err(EntityMappingError::DatabaseError)?;
            let entity_id: i32 = match entity_id_value {
                Some(entity_id) => entity_id,
                None => create_entity(client, entity_type_table, &name).await?,
            };

            ENTITY_MAPPING_CACHE.insert((entity_type_table.to_string(), name.clone()), entity_id);

            entity_ids.insert(name, entity_id);
        }
    }

    names
        .into_iter()
        .map(|name| -> Result<i32, EntityMappingError> {
            entity_ids
                .get(&name)
                .copied()
                .ok_or(EntityMappingError::UnmappedEntityError)
        })
        .collect()
}

async fn create_entity<T: GenericClient>(
    client: &T,
    entity_type_table: &str,
    name: &str,
) -> Result<i32, EntityMappingError> {
    let query = format!(
        "INSERT INTO entity.{}(name) VALUES($1) ON CONFLICT(name) DO UPDATE SET name=EXCLUDED.name RETURNING id",
        escape_identifier(entity_type_table)
    );

    let rows = client
        .query(&query, &[&name])
        .await
        .map_err(EntityMappingError::DatabaseError)?;

    match rows.first() {
        Some(row) => row
            .try_get(0)
            .map_err(EntityMappingError::EntityCreationError),
        None => Err(EntityMappingError::EntityInsertError),
    }
}
