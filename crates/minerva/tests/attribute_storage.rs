#[cfg(test)]
mod tests {
    use std::path::PathBuf;

    use minerva::cluster::MinervaCluster;

    #[tokio::test]
    async fn load_attribute_data() -> Result<(), Box<dyn std::error::Error>> {
        let config_file = PathBuf::from(concat!(env!("CARGO_MANIFEST_DIR"), "/postgresql.conf"));

        let cluster = MinervaCluster::start(&config_file, 3).await?;

        Ok(())
    }
}
