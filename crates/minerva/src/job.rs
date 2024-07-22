use serde_json::Value;
use tokio_postgres::GenericClient;

use crate::error::{DatabaseError, Error};

pub async fn start_job<T: GenericClient + Send + Sync>(
    client: &T,
    description: &Value,
) -> Result<i64, Error> {
    let query = "SELECT logging.start_job($1)";

    let result = client
        .query_one(query, &[&description])
        .await
        .map_err(|e| {
            Error::Database(DatabaseError::from_msg(format!("Error starting job: {e}")))
        })?;

    let job_id = result.get(0);

    Ok(job_id)
}

pub async fn end_job<T: GenericClient + Send + Sync>(
    client: &T,
    job_id: i64,
) -> Result<(), Error> {
    let query = "SELECT logging.end_job($1)";

    client
        .execute(query, &[&job_id])
        .await
        .map_err(|e| Error::Database(DatabaseError::from_msg(format!("Error ending job: {e}"))))?;

    Ok(())
}
