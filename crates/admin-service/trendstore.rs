use bb8::Pool;
use bb8_postgres::{tokio_postgres::NoTls, PostgresConnectionManager};

use actix_web::{get, web::Data, web::Path, HttpResponse, Responder};

use serde::{Deserialize, Serialize};

use utoipa::Component;

#[derive(Debug, Serialize, Deserialize, Clone, Component)]
pub struct Trend {
    pub id: i32,
    pub trend_store_part: i32,
    pub name: String,
    pub data_type: String,
    pub time_aggregation: String,
    pub entity_aggregation: String,
    pub extra_data: String,
    pub description: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, Component)]
pub struct GeneratedTrend {
    pub id: i32,
    pub trend_store_part: i32,
    pub name: String,
    pub data_type: String,
    pub expression: String,
    pub extra_data: String,
    pub description: String,
}

#[derive(Debug, Serialize, Deserialize, Clone, Component)]
pub struct TrendStorePart {
    pub id: i32,
    pub name: String,
    pub trend_store: i32,
    pub trends: Vec<Trend>,
    pub generated_trends: Vec<GeneratedTrend>,
}

#[utoipa::path(
    responses(
	(status = 200, description = "List all trend store parts", body = [TrendStorePart])
    )
)]
#[get("/trend-store-parts")]
pub(super) async fn get_trend_store_parts(
    pool: Data<Pool<PostgresConnectionManager<NoTls>>>,
) -> impl Responder {
    let mut m: Vec<TrendStorePart> = vec![];

    let client = pool.get().await.unwrap();
    let mut trends: Vec<Trend> = vec![];
    for inner_row in client.query("SELECT id, trend_store_part_id, name, data_type, time_aggregation, entity_aggregation, extra_data, description FROM trend_directory.table_trend", &[]).await.unwrap() {
	let trend = Trend {
	    id: inner_row.get(0),
	    trend_store_part: inner_row.get(1),
	    name: inner_row.get(2),
	    data_type: inner_row.get(3),
	    time_aggregation: inner_row.get(4),
	    entity_aggregation: inner_row.get(5),
	    extra_data: "".to_string(),
	    description: inner_row.get(7)
	};
	trends.push(trend)
    };

    let mut generated_trends: Vec<GeneratedTrend> = vec![];
    for inner_row in client.query("SELECT id, trend_store_part_id, name, data_type, expression, extra_data, description FROM trend_directory.generated_table_trend", &[]).await.unwrap() {
	let trend = GeneratedTrend {
	    id: inner_row.get(0),
	    trend_store_part: inner_row.get(1),
	    name: inner_row.get(2),
	    data_type: inner_row.get(3),
	    expression: inner_row.get(4),
	    extra_data: "".to_string(),
	    description: inner_row.get(6)
	};
	generated_trends.push(trend)
    };

    for row in client
        .query(
            "SELECT id, name, trend_store_id FROM trend_directory.trend_store_part",
            &[],
        )
        .await
        .unwrap()
    {
        let tspid: i32 = row.get(0);

        let mut my_trends: Vec<Trend> = vec![];
        for trend in &trends {
            if trend.trend_store_part == tspid {
                my_trends.push(trend.clone())
            }
        }

        let mut my_generated_trends: Vec<GeneratedTrend> = vec![];
        for generated_trend in &generated_trends {
            if generated_trend.trend_store_part == tspid {
                my_generated_trends.push(generated_trend.clone())
            }
        }

        let trendstorepart = TrendStorePart {
            id: tspid,
            name: row.get(1),
            trend_store: row.get(2),
            trends: my_trends,
            generated_trends: my_generated_trends,
        };
        m.push(trendstorepart)
    }

    HttpResponse::Ok().json(m)
}

#[utoipa::path(
    responses(
	(status = 200, description = "Get a specific trend store part", body = TrendStorePart)
    )
)]
#[get("/trend-store-part/{id}")]
pub(super) async fn get_trend_store_part(
    pool: Data<Pool<PostgresConnectionManager<NoTls>>>,
    id: Path<i32>,
) -> impl Responder {
    let tsp_id = id.into_inner();

    let client = pool.get().await.unwrap();

    let query_result = client
        .query_one(
            "SELECT name, trend_store_id FROM trend_directory.trend_store_part WHERE id=$1",
            &[&tsp_id],
        )
        .await;

    match query_result {
        Ok(row) => {
            let mut trends: Vec<Trend> = vec![];
            for inner_row in client.query("SELECT id, trend_store_part_id, name, data_type, time_aggregation, entity_aggregation, extra_data, description FROM trend_directory.table_trend WHERE trend_store_part_id=$1", &[&tsp_id]).await.unwrap() {
		let trend = Trend {
		    id: inner_row.get(0),
		    trend_store_part: inner_row.get(1),
		    name: inner_row.get(2),
		    data_type: inner_row.get(3),
		    time_aggregation: inner_row.get(4),
		    entity_aggregation: inner_row.get(5),
		    extra_data: "".to_string(),
		    description: inner_row.get(7)
		};
		trends.push(trend)
	    }

            let mut generated_trends: Vec<GeneratedTrend> = vec![];
            for inner_row in client.query("SELECT id, trend_store_part_id, name, data_type, expression, extra_data, description FROM trend_directory.generated_table_trend WHERE trend_store_part_id=$1", &[&tsp_id]).await.unwrap() {
		let trend = GeneratedTrend {
		    id: inner_row.get(0),
		    trend_store_part: inner_row.get(1),
		    name: inner_row.get(2),
		    data_type: inner_row.get(3),
		    expression: inner_row.get(4),
		    extra_data: "".to_string(),
		    description: inner_row.get(6)
		};
		generated_trends.push(trend)
	    };

            let trendstorepart = TrendStorePart {
                id: tsp_id,
                name: row.get(0),
                trend_store: row.get(1),
                trends: trends,
                generated_trends: generated_trends,
            };

            HttpResponse::Ok().json(trendstorepart)
        }
        Err(_e) => {
            HttpResponse::NotFound().body(format!("Trend store part with id {} not found", &tsp_id))
        }
    }
}
