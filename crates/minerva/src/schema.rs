use tokio_postgres::Client;

pub fn schema() -> &'static str {
    include_str!("schema.sql")
}

pub async fn create_schema(client: &mut Client) -> Result<(), String> {
    if let Err(e) = client.batch_execute(schema()).await {
        return Err(format!("Error creating Minerva schema: {e}"));
    }

    Ok(())
}
