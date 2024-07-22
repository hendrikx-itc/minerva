use std::sync::Once;

pub mod common;
pub mod create_kpi;
pub mod entity_set;
pub mod get_entity_types;
pub mod initialize;
pub mod load_data;

static INIT: Once = Once::new();

pub fn setup() {
    INIT.call_once(|| {
        env_logger::init();
    })
}
