use actix_web::{get, web::Path, HttpRequest, HttpResponse};

use super::serviceerror::{ServiceError, ServiceErrorKind};

#[utoipa::path(
    get,
    path="/headers",
    responses(
    (status = 200, description = "Value of the header", body = String),
    (status = 404, description = "Header does not exist", body = Error),
    )
)]
#[get("/headers/{name}")]
async fn get_header(req: HttpRequest, name: Path<String>) -> Result<HttpResponse, ServiceError> {
    let headers = req.headers();
    let headername = name.into_inner();
    match headers.get(headername) {
        Some(value) => match value.to_str() {
            Ok(val) => Ok(HttpResponse::Ok().body::<String>(val.to_string())),
            Err(e) => Err(ServiceError {
                kind: ServiceErrorKind::InternalError,
                message: e.to_string(),
            }),
        },
        None => Err(ServiceError {
            kind: ServiceErrorKind::NotFound,
            message: "No such header".to_string(),
        }),
    }
}
