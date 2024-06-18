#[cfg(test)]
mod tests {
    use std::process::Command;

    use assert_cmd::prelude::*;
    use predicates::prelude::*;
    use rand::distributions::{Alphanumeric, DistString};

    use minerva::database::{connect_db, create_database, drop_database};

    fn generate_name() -> String {
        Alphanumeric.sample_string(&mut rand::thread_rng(), 16)
    }

    #[tokio::test]
    async fn initialize() -> Result<(), Box<dyn std::error::Error>> {
        let database_name = generate_name();
        let mut client = connect_db().await?;

        create_database(&mut client, &database_name).await?;

        println!("Dropped database");
        let mut cmd = Command::cargo_bin("minerva")?;
        cmd.env("PGDATABASE", &database_name);

        let instance_root_path = std::fs::canonicalize("../../examples/tiny_instance_v1").unwrap();

        cmd.arg("initialize")
            .arg("--create-schema")
            .arg(&instance_root_path);
        cmd.assert()
            .success()
            .stdout(predicate::str::contains("Created trigger"));

        let mut client = connect_db().await?;

        drop_database(&mut client, &database_name).await?;

        println!("Dropped database");

        Ok(())
    }
}
