#[cfg(test)]
mod tests {
    use std::process::Command;

    use log::debug;

    use assert_cmd::prelude::*;
    use predicates::prelude::*;

    use minerva::cluster::MinervaCluster;

    #[ignore = "Container running not yet supported in CI pipeline"]
    #[tokio::test]
    async fn initialize() -> Result<(), Box<dyn std::error::Error>> {
        env_logger::init();

        let cluster = MinervaCluster::start(3).await?;

        debug!("Containers started");

        let test_database = cluster.create_db().await;

        debug!("Created database '{}'", test_database.name);

        let mut cmd = Command::cargo_bin("minerva")?;
        cmd
            .env("PGUSER", "postgres")
            .env("PGHOST", cluster.controller_host.to_string())
            .env("PGPORT", cluster.controller_port.to_string())
            .env("PGSSLMODE", "disable")
            .env("PGDATABASE", &test_database.name);

        let instance_root_path = std::fs::canonicalize("../../examples/tiny_instance_v1").unwrap();

        cmd.arg("initialize")
            .arg("--create-schema")
            .arg(&instance_root_path);
        cmd.assert()
            .success()
            .stdout(predicate::str::contains("Created trigger"));

        let client = test_database.connect().await?;

        let row = client.query_one("SELECT count(*) FROM trend_directory.trend_store", &[]).await?;

        let trend_store_count: i64 = row.get(0);

        assert_eq!(trend_store_count, 6);

        let row = client.query_one("SELECT count(*) FROM trigger.rule", &[]).await?;

        let trigger_count: i64 = row.get(0);

        assert_eq!(trigger_count, 4);

        Ok(())
    }
}
