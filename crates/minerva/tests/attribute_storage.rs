#[cfg(test)]
mod tests {
    use log::debug;
    use std::path::PathBuf;

    use minerva::attribute_storage::{AttributeDataRow, RawAttributeStore};
    use minerva::attribute_store::{AddAttributeStore, AttributeStore};
    use minerva::change::Change;
    use minerva::cluster::MinervaCluster;
    use minerva::schema::create_schema;

    const ATTRIBUTE_STORE_DEFINITION: &str = r###"
        data_source: hub
        entity_type: node
        attributes:
        - name: name
          data_type: text
          unit: null
          description: null
          extra_data: null
        - name: equipment_type
          data_type: text
          unit: null
          description: The equipment type
          extra_data: null
        - name: equipment_serial
          data_type: text
          unit: null
          description: The manufacturer serial number of the equipment
          extra_data: null
        - name: longitude
          data_type: real
          unit: null
          description: Coordinate of equipment location
          extra_data: null
        - name: latitude
          data_type: real
          unit: null
          description: Coordinate of equipment location
          extra_data: null
        "###;

    #[tokio::test]
    async fn load_attribute_data() -> Result<(), Box<dyn std::error::Error>> {
        let config_file = PathBuf::from(concat!(env!("CARGO_MANIFEST_DIR"), "/postgresql.conf"));

        let cluster = MinervaCluster::start(&config_file, 3).await?;

        let test_database = cluster.create_db().await?;

        debug!("Created database '{}'", test_database.name);

        {
            let mut client = test_database.connect().await?;
            create_schema(&mut client).await?;

            let attribute_store: AttributeStore = serde_yaml::from_str(ATTRIBUTE_STORE_DEFINITION)
                .map_err(|e| format!("Could not read trend store definition: {}", e))?;

            let add_trend_store = AddAttributeStore {
                attribute_store: attribute_store.clone(),
            };

            let mut tx = client.transaction().await?;

            add_trend_store.apply(&mut tx).await?;

            tx.commit().await?;

            let attributes = vec!["name".to_string()];
            let rows = (0..500)
                .map(|num| AttributeDataRow {
                    entity_name: format!("node_{}", num),
                    values: vec![Some(format!("node_{}", num))],
                })
                .collect();

            let tx = client.transaction().await?;
            attribute_store.store(&tx, attributes, rows).await?;
            tx.commit().await?;
        }

        {
            let client = test_database.connect().await?;

            let rows = client
                .query(
                    "SELECT entity_id, timestamp FROM attribute_history.\"hub_node\"",
                    &[],
                )
                .await?;

            assert_eq!(rows.len(), 500);
        }

        Ok(())
    }
}
