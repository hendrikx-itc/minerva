use serde::{Deserialize, Serialize};
use std::fmt;
use std::path::PathBuf;
use tokio_postgres::types::ToSql;
use tokio_postgres::{Client, GenericClient, Transaction};

use async_trait::async_trait;

type PostgresName = String;

use super::change::{Change, ChangeResult};
use super::error::{ConfigurationError, DatabaseError, Error, RuntimeError};

#[derive(Debug, Serialize, Deserialize, Clone, ToSql)]
#[postgres(name = "attribute_descr")]
pub struct Attribute {
    pub name: PostgresName,
    pub data_type: String,
    #[serde(default = "default_empty_string")]
    pub description: String,
}

fn default_empty_string() -> String {
    String::new()
}

pub struct AddAttributes {
    pub notification_store: NotificationStore,
    pub attributes: Vec<Attribute>,
}

impl fmt::Display for AddAttributes {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "AddAttributes({}, {:?})",
            &self.notification_store, &self.attributes
        )
    }
}

#[async_trait]
impl Change for AddAttributes {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let query = concat!(
            "with a as (",
            "insert into notification_directory.attribute(notification_store_id, name, data_type, description) ",
            "select ns.id, $1, $2, $3 from notification_directory.notification_store ns join directory.data_source ds on ds.id = ns.data_source_id where ds.name = $4 returning attribute",
            ") ",
            "select notification_directory.create_attribute_column(a.attribute) from a;"
        );

        for attribute in &self.attributes {
            client
                .execute(
                    query,
                    &[
                        &attribute.name,
                        &attribute.data_type,
                        &attribute.description,
                        &self.notification_store.data_source,
                    ],
                )
                .await
                .map_err(|e| {
                    DatabaseError::from_msg(format!(
                        "Error adding attribute to notification store: {e}"
                    ))
                })?;
        }

        Ok(format!(
            "Added attributes to notification store '{}'",
            &self.notification_store
        ))
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct NotificationStore {
    pub title: Option<String>,
    pub data_source: String,
    pub attributes: Vec<Attribute>,
}

impl NotificationStore {
    pub fn diff(&self, other: &NotificationStore) -> Vec<Box<dyn Change + Send>> {
        let mut changes: Vec<Box<dyn Change + Send>> = Vec::new();

        let mut new_attributes: Vec<Attribute> = Vec::new();

        for other_attribute in &other.attributes {
            match self
                .attributes
                .iter()
                .find(|my_part| my_part.name == other_attribute.name)
            {
                Some(_my_part) => {
                    // Ok attribute exists
                }
                None => {
                    new_attributes.push(other_attribute.clone());
                }
            }
        }

        if !new_attributes.is_empty() {
            changes.push(Box::new(AddAttributes {
                notification_store: self.clone(),
                attributes: new_attributes,
            }));
        }

        changes
    }
}

impl fmt::Display for NotificationStore {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "NotificationStore({})", &self.data_source,)
    }
}

pub struct AddNotificationStore {
    pub notification_store: NotificationStore,
}

impl fmt::Display for AddNotificationStore {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "AddNotificationStore({})", &self.notification_store)
    }
}

#[async_trait]
impl Change for AddNotificationStore {
    async fn apply(&self, client: &mut Transaction) -> ChangeResult {
        let query = format!(
            "SELECT notification_directory.create_notification_store($1::text, ARRAY[{}]::notification_directory.attr_def[])",
            self.notification_store.attributes.iter().map(|att| format!("('{}', '{}', '')", &att.name, &att.data_type)).collect::<Vec<String>>().join(",")
        );

        client
            .query_one(&query, &[&self.notification_store.data_source])
            .await
            .map_err(|e| {
                DatabaseError::from_msg(format!("Error creating notification store: {e}"))
            })?;

        Ok(format!(
            "Created attribute store '{}'",
            &self.notification_store
        ))
    }
}

pub async fn load_notification_stores(conn: &mut Client) -> Result<Vec<NotificationStore>, Error> {
    let mut notification_stores: Vec<NotificationStore> = Vec::new();

    let query = concat!(
        "SELECT notification_store.id, data_source.name ",
        "FROM notification_directory.notification_store ",
        "JOIN directory.data_source ON data_source.id = notification_store.data_source_id ",
    );

    let result = conn
        .query(query, &[])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Error loading notification stores: {e}")))?;

    for row in result {
        let attribute_store_id: i32 = row.get(0);
        let data_source: &str = row.get(1);

        let attributes = load_attributes(conn, attribute_store_id).await;

        notification_stores.push(NotificationStore {
            title: None,
            data_source: String::from(data_source),
            attributes,
        });
    }

    Ok(notification_stores)
}

pub async fn load_notification_store(
    conn: &mut Client,
    data_source: &str,
    entity_type: &str,
) -> Result<NotificationStore, Error> {
    let query = concat!(
        "SELECT attribute_store.id ",
        "FROM attribute_directory.attribute_store ",
        "JOIN directory.data_source ON data_source.id = attribute_store.data_source_id ",
        "WHERE data_source.name = $1"
    );

    let result = conn
        .query_one(query, &[&data_source, &entity_type])
        .await
        .map_err(|e| DatabaseError::from_msg(format!("Could not load attribute stores: {e}")))?;

    let attributes = load_attributes(conn, result.get::<usize, i32>(0)).await;

    Ok(NotificationStore {
        title: None,
        data_source: String::from(data_source),
        attributes,
    })
}

async fn load_attributes(conn: &mut Client, notification_store_id: i32) -> Vec<Attribute> {
    let attribute_query = "SELECT name, data_type, description FROM notification_directory.attribute WHERE notification_store_id = $1";
    let rows = conn
        .query(attribute_query, &[&notification_store_id])
        .await
        .unwrap();

    rows.iter()
        .map(|row| {
            let attribute_name: &str = row.get(0);
            let attribute_data_type: &str = row.get(1);
            let attribute_description: Option<String> = row.get(2);

            Attribute {
                name: String::from(attribute_name),
                data_type: String::from(attribute_data_type),
                description: attribute_description.unwrap_or(String::from("")),
            }
        })
        .collect()
}

pub fn load_notification_store_from_file(path: &PathBuf) -> Result<NotificationStore, Error> {
    let f = std::fs::File::open(path).map_err(|e| {
        ConfigurationError::from_msg(format!(
            "Could not open notification store definition file '{}': {}",
            path.display(),
            e
        ))
    })?;

    let notification_store: NotificationStore = serde_yaml::from_reader(f).map_err(|e| {
        RuntimeError::from_msg(format!(
            "Could not read notification store definition from file '{}': {}",
            path.display(),
            e
        ))
    })?;

    Ok(notification_store)
}

pub async fn notification_store_exists<T: GenericClient + Sync + Send>(
    client: &mut T,
    data_source_name: &str,
) -> Result<bool, Error> {
    let query = concat!(
        "SELECT notification_store.id, data_source.name ",
        "FROM notification_directory.notification_store ",
        "JOIN directory.data_source ON data_source.id = notification_store.data_source_id ",
        "WHERE data_source.name = $1"
    );

    let result = client
        .query(query, &[&data_source_name])
        .await
        .map_err(|e| {
            DatabaseError::from_msg(format!("Error checking notification store existence: {e}"))
        })?;

    match result.len() {
        0 => Ok(false),
        1 => Ok(true),
        _ => Err(Error::Database(DatabaseError::from_msg(format!(
            "Unexpected number of notification store matches: {}",
            result.len()
        )))),
    }
}
