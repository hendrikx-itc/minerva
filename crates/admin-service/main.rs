use actix_web::{middleware::Logger, web, App, HttpServer};

use bb8;
use bb8_postgres::{tokio_postgres::NoTls, PostgresConnectionManager};

use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

mod trendviewmaterialization;

use trendviewmaterialization::{
    get_trend_view_materializations, TrendMaterializationSource, TrendViewMaterialization,
};

mod trendstore;

use trendstore::{
    get_trend_store, get_trend_store_part, get_trend_store_parts, get_trend_stores, GeneratedTrend,
    Trend, TrendStore, TrendStorePart,
};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    #[derive(OpenApi)]
    #[openapi(
        handlers(
            trendviewmaterialization::get_trend_view_materializations,
	    trendstore::get_trend_store_parts,
	    trendstore::get_trend_store_part,
	    trendstore::get_trend_stores,
	    trendstore::get_trend_store,
        ),
        components(TrendMaterializationSource, TrendViewMaterialization, Trend, GeneratedTrend, TrendStorePart, TrendStore),
        tags(
            (name = "Trend Materialization", description = "Trend materialization management endpoints.")
        ),
    )]
    struct ApiDoc;

    let manager = PostgresConnectionManager::new(
        "host=127.0.0.1 user=postgres dbname=minerva"
            .parse()
            .unwrap(),
        NoTls,
    );
    let pool = bb8::Pool::builder().build(manager).await.unwrap();

    let openapi = ApiDoc::openapi();

    HttpServer::new(move || {
        App::new()
            .wrap(Logger::default())
            .app_data(web::Data::new(pool.clone()))
            .service(
                SwaggerUi::new("/swagger-ui/{_:.*}").url("/api-doc/openapi.json", openapi.clone()),
            )
            .service(get_trend_view_materializations)
            .service(get_trend_store_parts)
            .service(get_trend_store_part)
            .service(get_trend_stores)
            .service(get_trend_store)
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
