use bytes::BytesMut;
use futures_util::pin_mut;
use log::debug;
use postgres_protocol::escape::escape_identifier;
use thiserror::Error;
use tokio_postgres::binary_copy::BinaryCopyInWriter;
use tokio_postgres::types::{ToSql, Type, IsNull};
use tokio_postgres::Transaction;

use crate::attribute_store::{Attribute, AttributeStore};
use crate::meas_value::{
    parse_meas_value, DataType, MeasValue, INT2_NONE_VALUE, TEXT_NONE_VALUE,
};


#[derive(Error, Debug)]
pub enum AttributeStorageError {
    #[error("Database error: {0}")]
    DatabaseError(tokio_postgres::Error),
}

#[derive(Debug, Clone)]
struct AttributeValue<'a> {
    data_type: DataType,
    inner_value: &'a Option<String>,
}

impl<'a> ToSql for AttributeValue<'a> {
    fn to_sql(
        &self,
        ty: &Type,
        out: &mut bytes::BytesMut,
    ) -> Result<IsNull, Box<dyn std::error::Error + Sync + Send>>
    where
        Self: Sized,
    {
        debug!("to_sql: {:?}", self.inner_value);
        match self.inner_value {
            Some(value) => parse_meas_value(self.data_type, value).to_sql(ty, out),
            None => MeasValue::null_value_of_type(self.data_type).to_sql(ty, out),
        }
    }

    fn accepts(_ty: &Type) -> bool
    where
        Self: Sized,
    {
        true
    }

    fn to_sql_checked(
        &self,
        ty: &Type,
        out: &mut BytesMut,
    ) -> Result<IsNull, Box<dyn std::error::Error + Sync + Send>> {
        debug!("to_sql_checked: {:?}", self.inner_value);
        match self.inner_value {
            Some(value) => {
                let meas_value = parse_meas_value(self.data_type, value);
                debug!("meas_value: {:?}", meas_value);
                meas_value.to_sql_checked(ty, out)
            }
            None => MeasValue::null_value_of_type(self.data_type).to_sql_checked(ty, out),
        }
    }
}

fn to_sql_type(data_type: DataType) -> Type {
    match data_type {
        DataType::Int2 => Type::INT2,
        DataType::Integer => Type::INT4,
        DataType::Int8 => Type::INT8,
        DataType::Numeric => Type::NUMERIC,
        DataType::Real => Type::FLOAT4,
        DataType::Double => Type::FLOAT8,
        DataType::Timestamp => Type::TIMESTAMPTZ,
        _ => Type::TEXT,
    }
}

#[derive(Debug, Clone)]
struct NullValue {
    data_type: DataType,
}

impl ToSql for NullValue {
    fn to_sql(
        &self,
        ty: &Type,
        out: &mut bytes::BytesMut,
    ) -> Result<tokio_postgres::types::IsNull, Box<dyn std::error::Error + Sync + Send>>
    where
        Self: Sized,
    {
        debug!("to_sql: {}", self.data_type);
        match self.data_type {
            DataType::Int2 => INT2_NONE_VALUE.to_sql(ty, out),
            _ => TEXT_NONE_VALUE.to_sql(ty, out),
        }
    }

    fn accepts(_ty: &Type) -> bool
    where
        Self: Sized,
    {
        true
    }

    fn to_sql_checked(
        &self,
        ty: &Type,
        out: &mut BytesMut,
    ) -> Result<IsNull, Box<dyn std::error::Error + Sync + Send>> {
        debug!("to_sql_checked: {}", self.data_type);
        TEXT_NONE_VALUE.to_sql_checked(ty, out)
    }
}

pub struct AttributeDataRow {
    pub entity_name: String,
    pub values: Vec<Option<String>>,
}

pub trait RawAttributeStore {
    fn store(
        &self,
        tx: &Transaction,
        attributes: Vec<String>,
        rows: Vec<AttributeDataRow>,
    ) -> impl std::future::Future<Output = Result<(), AttributeStorageError>> + Send;
}

async fn create_temp_table<C: tokio_postgres::GenericClient + Send + Sync>(
    client: &C,
    attribute_store: &AttributeStore,
) -> Result<String, AttributeStorageError> {
    let temp_table_name = format!(
        "tmp_{}_{}",
        attribute_store.data_source, attribute_store.entity_type
    );
    let attribute_columns_part: String = attribute_store
        .attributes
        .iter()
        .map(|att| format!("{} {}", escape_identifier(&att.name), att.data_type))
        .collect::<Vec<String>>()
        .join(",");

    let create_temp_table_query = format!(
        "CREATE TEMPORARY TABLE {}(entity_name text,{}) ON COMMIT DROP",
        escape_identifier(&temp_table_name),
        attribute_columns_part
    );

    client
        .execute(&create_temp_table_query, &[])
        .await
        .map_err(AttributeStorageError::DatabaseError)?;

    Ok(temp_table_name)
}

async fn create_entities<C: tokio_postgres::GenericClient + Send + Sync>(
    client: &C,
    type_name: &str,
    entity_names: Vec<String>,
) -> Result<u64, AttributeStorageError> {
    let query = format!("WITH names AS (SELECT unnest($1::text[]) AS name) INSERT INTO entity.{}(name) SELECT name FROM names ON CONFLICT DO NOTHING", escape_identifier(type_name));

    let count = client
        .execute(&query, &[&entity_names])
        .await
        .map_err(AttributeStorageError::DatabaseError)?;

    Ok(count)
}

impl RawAttributeStore for AttributeStore {
    async fn store(
        &self,
        tx: &Transaction<'_>,
        attributes: Vec<String>,
        rows: Vec<AttributeDataRow>,
    ) -> Result<(), AttributeStorageError> {
        let matched_attributes: Vec<(usize, &Attribute)> = self 
            .attributes
            .iter()
            .filter_map(|att| {
                attributes
                    .iter()
                    .position(|att_name| *att_name.to_lowercase() == att.name.to_lowercase())
                    .map(|index| (index, att))
            })
            .collect();

        let table_name = format!(
            "{}_{}",
            self.data_source, self.entity_type
        );

        let entity_ids: Vec<i32> = names_to_entity_ids(
            client,
            &self.entity_type,
            records
                .iter()
                .map(|(entity_name, _timestamp, _values)| entity_name.clone())
                .collect(),
        )
        .await?;

        let temp_table_name = create_temp_table(tx, self).await?;

        let mut column_names = vec!["entity_name".to_string()];
        column_names.extend(
            matched_attributes
                .iter()
                .map(|(_index, att)| escape_identifier(&att.name)),
        );

        let column_names_part = column_names.join(",");

        let copy_from_query = format!(
            "COPY {}({}) FROM STDIN BINARY",
            escape_identifier(&temp_table_name),
            column_names_part,
        );

        let copy_in_sink = tx
            .copy_in(&copy_from_query)
            .await
            .map_err(AttributeStorageError::DatabaseError)?;

        let types: Vec<Type> = vec![Type::TEXT]
            .into_iter()
            .chain(
                matched_attributes
                    .iter()
                    .map(|(_index, att)| to_sql_type(att.data_type)),
            )
            .collect();

        debug!("types: {:?}", &types);

        let binary_copy_writer = BinaryCopyInWriter::new(copy_in_sink, &types);
        pin_mut!(binary_copy_writer);

        for row in rows {
            let attr_values: Vec<_> = matched_attributes
                .iter()
                .map(|(index, attr)| {
                    debug!("{}: {}", attr.name, attr.data_type);
                    AttributeValue {
                        data_type: attr.data_type,
                        inner_value: row.values.get(*index).unwrap(),
                    }
                })
                .collect();

            let mut vs: Vec<&(dyn ToSql + Sync)> = vec![map_string(&row.entity_name)];
            vs.extend(attr_values.iter().map(map_value));

            binary_copy_writer
                .as_mut()
                .write_raw(vs)
                .await
                .map_err(AttributeStorageError::DatabaseError)?;
        }

        binary_copy_writer.finish().await.unwrap();

        let entity_column_name = "entity_name";

        let get_missing_entities_query = format!(
            "SELECT tmp.{} name FROM {} tmp LEFT JOIN entity.{} e ON e.name = tmp.{} WHERE e.id IS NULL",
            escape_identifier(entity_column_name), escape_identifier(&temp_table_name), escape_identifier(&self.entity_type), escape_identifier(entity_column_name)
        );

        let rows = tx.query(&get_missing_entities_query, &[])
            .await
            .map_err(AttributeStorageError::DatabaseError)?;

        let missing_entities = rows
            .iter()
            .map(|row| row.try_get::<usize, String>(0))
            .collect::<Result<Vec<String>, tokio_postgres::error::Error>>()
            .map_err(AttributeStorageError::DatabaseError)?;

        if !missing_entities.is_empty() {
            debug!("Missing entities: {:?}", missing_entities);

            let created =
                create_entities(tx, &self.entity_type, missing_entities).await?;

            debug!("Created entities: {}", created);
        }

        if matched_attributes.is_empty() {
            debug!("No attributes matched, skipping storing");
            return Ok(());
        }

        let fields = matched_attributes
            .iter()
            .map(|(_index, att)| escape_identifier(&att.name))
            .collect::<Vec<String>>()
            .join(",");

        // Transfer from temp table to the attribute staging table
        let query = format!(
            "INSERT INTO attribute_staging.{}(entity_id, timestamp, {fields}) SELECT e.id, now(), {fields} FROM {} tmp JOIN entity.{} e ON e.name = tmp.{}",
            escape_identifier(&table_name), escape_identifier(&temp_table_name), escape_identifier(&self.entity_type), escape_identifier(entity_column_name),
        );

        let staged_count = tx.execute(&query, &[])
            .await
            .map_err(AttributeStorageError::DatabaseError)?;

        debug!("Staged {} records in '{}'", staged_count, &table_name);

        let transfer_staged_query = "SELECT attribute_directory.transfer_staged(attribute_store) FROM attribute_directory.attribute_store WHERE attribute_store::text = $1";

        let row = tx.query_one(transfer_staged_query, &[&table_name])
            .await
            .map_err(AttributeStorageError::DatabaseError)?;

        debug!("Transferred staged data: {:?}", row);

        debug!(
            "Stored {} rows with {} attributes for '{}'",
            rows.len(),
            attributes.len(),
            self 
        );

        Ok(())
    }
}

fn map_value<'a>(value: &'a AttributeValue) -> &'a (dyn ToSql + Sync) {
    value
}

fn map_string(value: &String) -> &(dyn ToSql + Sync) {
    value
}
