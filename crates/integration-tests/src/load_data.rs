#[cfg(test)]
mod tests {
    use assert_cmd::prelude::*;
    use predicates::prelude::*;
    use tokio::sync::OnceCell;
    use std::env;
    use std::io::Write;
    use std::path::PathBuf;
    use std::process::Command;

    use log::info;
    use rust_decimal::Decimal;
    use rust_decimal_macros::dec;

    use minerva::change::Change;
    use minerva::changes::trend_store::AddTrendStore;
    use minerva::schema::create_schema;
    use minerva::trend_store::{create_partitions_for_timestamp, TrendStore};
    use minerva::cluster::MinervaCluster;

    const TEST_CSV_DATA: &str = r###"
node,timestamp,outside_temp,inside_temp,power_kwh,freq_power
hillside14,2023-03-25T14:00:00Z,14.4,32.4,55.8,212.4
hillside15,2023-03-25T14:00:00Z,14.5,32.5,55.9,212.5
"###;

    const TEST_CSV_DATA_UPDATE_PARTIAL: &str = r###"
node,timestamp,power_kwh,freq_power
hillside15,2023-03-25T14:00:00Z,55.9,200.0
"###;

    const TREND_STORE_DEFINITION: &str = r###"
    title: Raw node data
    data_source: hub
    entity_type: node
    granularity: 15m
    partition_size: 1d
    parts:
      - name: hub_node_main_15m
        trends:
          - name: outside_temp
            data_type: numeric
          - name: inside_temp
            data_type: numeric
          - name: power_kwh
            data_type: numeric
          - name: freq_power
            data_type: numeric
        generated_trends:
          - name: power_Mwh
            data_type: numeric
            description: test
            expression: power_kwh / 1000

    "###;

    #[ignore = "Container running not yet supported in CI pipeline"]
    #[tokio::test]
    async fn load_data() -> Result<(), Box<dyn std::error::Error>> {
        crate::setup();

        let keep_database = env::var("DROP_DATABASE")
            .unwrap_or(String::from("1"))
            .eq("0");

        let cluster = MinervaCluster::start(3).await?;

        let data_source_name = "hub";

        let test_database = cluster.create_db().await;

        info!("Created database '{}'", test_database.name);

        {
            let mut client = test_database.connect().await?;
            create_schema(&mut client).await?;

            let trend_store: TrendStore = serde_yaml::from_str(TREND_STORE_DEFINITION)
                .map_err(|e| format!("Could not read trend store definition: {}", e))?;

            let add_trend_store = AddTrendStore { trend_store };

            let mut tx = client.transaction().await?;

            add_trend_store.apply(&mut tx).await?;

            tx.commit().await?;

            let timestamp =
                chrono::DateTime::parse_from_rfc3339("2023-03-25T14:00:00+00:00").unwrap();
            create_partitions_for_timestamp(&mut client, timestamp.into()).await?;
        }

        let mut cmd = Command::cargo_bin("minerva")?;
        cmd
            .env("PGUSER", "postgres")
            .env("PGHOST", cluster.controller_host.to_string())
            .env("PGPORT", cluster.controller_port.to_string())
            .env("PGSSLMODE", "disable")
            .env("PGDATABASE", &test_database.name);

        let mut csv_file = tempfile::tempfile().unwrap();

        csv_file.write_all(TEST_CSV_DATA.as_bytes()).unwrap();

        let instance_root_path = std::fs::canonicalize("../../examples/tiny_instance_v1").unwrap();

        let mut file_path = PathBuf::from(instance_root_path);
        file_path.push("sample-data/sample.csv");

        cmd.arg("load-data")
            .arg("--data-source")
            .arg(data_source_name)
            .arg(&file_path);
        cmd.assert()
            .success()
            .stdout(predicate::str::contains("Job ID"));

        if !keep_database {
            let mut client = cluster.connect_to_coordinator().await;

            test_database.drop_database(&mut client).await;

            println!("Dropped database '{}'", test_database.name);
        }

        Ok(())
    }

    #[ignore = "Container running not yet supported in CI pipeline"]
    #[tokio::test]
    async fn load_data_twice() -> Result<(), Box<dyn std::error::Error>> {
        crate::setup();

        let keep_database = env::var("DROP_DATABASE")
            .unwrap_or(String::from("1"))
            .eq("0");
        let data_source_name = "hub";

        let cluster = MinervaCluster::start(3).await?;

        let test_database = cluster.create_db().await;

        info!("Created database '{}'", test_database.name);

        {
            let mut client = test_database.connect().await?;

            create_schema(&mut client).await?;

            let trend_store: TrendStore = serde_yaml::from_str(TREND_STORE_DEFINITION)
                .map_err(|e| format!("Could not read trend store definition: {}", e))?;

            let add_trend_store = AddTrendStore { trend_store };

            let mut tx = client.transaction().await?;

            add_trend_store.apply(&mut tx).await?;
            let timestamp =
                chrono::DateTime::parse_from_rfc3339("2023-03-25T14:00:00+00:00").unwrap();

            tx.commit().await?;

            create_partitions_for_timestamp(&mut client, timestamp.into()).await?;
        }

        let mut cmd = Command::cargo_bin("minerva")?;
        cmd
            .env("PGUSER", "postgres")
            .env("PGHOST", cluster.controller_host.to_string())
            .env("PGPORT", cluster.controller_port.to_string())
            .env("PGSSLMODE", "disable")
            .env("PGDATABASE", &test_database.name);

        let mut csv_file = tempfile::NamedTempFile::new().unwrap();
        csv_file.write_all(TEST_CSV_DATA.as_bytes()).unwrap();

        cmd.arg("load-data")
            .arg("--data-source")
            .arg(data_source_name)
            .arg(csv_file.path());

        let output = cmd.output().unwrap();

        println!("{}", String::from_utf8(output.stdout).unwrap());

        let mut cmd = Command::cargo_bin("minerva")?;
        cmd
            .env("PGUSER", "postgres")
            .env("PGHOST", cluster.controller_host.to_string())
            .env("PGPORT", cluster.controller_port.to_string())
            .env("PGSSLMODE", "disable")
            .env("PGDATABASE", &test_database.name);

        let mut csv_file = tempfile::NamedTempFile::new().unwrap();
        csv_file
            .write_all(TEST_CSV_DATA_UPDATE_PARTIAL.as_bytes())
            .unwrap();

        cmd.arg("load-data")
            .arg("--data-source")
            .arg(data_source_name)
            .arg(csv_file.path());

        let output = cmd.output().unwrap();

        println!("{}", String::from_utf8(output.stdout).unwrap());

        {
            let client = test_database.connect().await?;

            let query = concat!(
                "SELECT freq_power ",
                "FROM trend.hub_node_main_15m t ",
                "JOIN entity.node e ON e.id = t.entity_id ",
                "WHERE e.name = $1 AND t.timestamp = $2::text::timestamptz"
            );

            let row = client
                .query_one(query, &[&"hillside14", &"2023-03-25T14:00:00Z"])
                .await?;

            let expected_value: Decimal = dec!(212.4);
            let value: Decimal = row.get(0);

            assert_eq!(value, expected_value);

            let row = client
                .query_one(query, &[&"hillside15", &"2023-03-25T14:00:00Z"])
                .await?;

            let expected_value: Decimal = dec!(200.0);
            let value: Decimal = row.get(0);

            assert_eq!(value, expected_value);
        }

        if !keep_database {
            let mut client = cluster.connect_to_coordinator().await;

            test_database.drop_database(&mut client).await;

            info!("Dropped database '{}'", test_database.name);
        }

        Ok(())
    }
}
