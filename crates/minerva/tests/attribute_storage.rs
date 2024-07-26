mod common;

#[cfg(test)]
mod tests {
    use chrono::{DateTime, Utc};
    use log::debug;
    use minerva::entity::CachingEntityMapping;
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
        crate::common::setup();

        let config_file = PathBuf::from(concat!(env!("CARGO_MANIFEST_DIR"), "/postgresql.conf"));

        let entity_mapping = CachingEntityMapping::new(100);

        let cluster = MinervaCluster::start(&config_file, 3).await?;

        let test_database = cluster.create_db().await?;

        debug!("Created database '{}'", test_database.name);

        let (elapsed, stored_count) = {
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
                    timestamp: Utc::now(),
                    entity_name: format!("node_{}", num),
                    values: vec![Some(format!("node_{}", num))],
                })
                .collect();

            let start = std::time::Instant::now();

            let tx = client.transaction().await?;
            let stored_count = attribute_store.store(&tx, &entity_mapping, attributes, rows).await?;
            tx.commit().await?;

            (start.elapsed(), stored_count)
        };

        println!("Duration: {:?}", elapsed);

        assert_eq!(stored_count, 500);

        {
            let client = test_database.connect().await?;

            let rows = client
                .query(
                    "SELECT entity_id, timestamp, hash FROM attribute_history.hub_node a JOIN entity.node e ON e.id = a.entity_id order by e.name",
                    &[],
                )
                .await?;

            assert_eq!(rows.len(), 500);

            let first_row = rows.first().unwrap();

            let now = Utc::now();

            let first_timestamp: DateTime<Utc> = first_row.get(1);
            assert!(first_timestamp < now);
            let first_hash: String = first_row.get(2);
            assert_eq!(first_hash, "a0bd39a96dab92bf492a1dc8c380c96a");


            let last_row = rows.last().unwrap();

            let last_timestamp: DateTime<Utc> = last_row.get(1);
            assert!(last_timestamp < now);
            let last_hash: String = last_row.get(2);
            assert_eq!(last_hash, "4d29f20f44be7506e75e657b30571581");
        }

        Ok(())
    }
}
