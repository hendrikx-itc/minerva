use std::fmt::{self};

use rust_decimal::prelude::*;

use lazy_static::lazy_static;
use postgres_types::{to_sql_checked, Type};
use serde::{Deserialize, Serialize};
use tokio_postgres::types::ToSql;

use crate::error::Error;

#[derive(Debug, Serialize, Deserialize, Clone, Copy, PartialEq)]
pub enum DataType {
    #[serde(rename = "boolean")]
    Boolean,
    #[serde(rename = "smallint")]
    Int2,
    #[serde(rename = "integer")]
    Integer,
    #[serde(rename = "bigint")]
    Int8,
    #[serde(rename = "real")]
    Real,
    #[serde(rename = "double precision")]
    Double,
    #[serde(rename = "text")]
    Text,
    #[serde(rename = "text[]")]
    TextArray,
    #[serde(rename = "timestamp")]
    Timestamp,
    #[serde(rename = "numeric")]
    Numeric,
    #[serde(rename = "numeric[]")]
    NumericArray,
}

impl ToSql for DataType {
    fn to_sql(
        &self,
        ty: &Type,
        out: &mut bytes::BytesMut,
    ) -> Result<postgres_types::IsNull, Box<dyn std::error::Error + Sync + Send>>
    where
        Self: Sized,
    {
        match self {
            DataType::Boolean => "boolean".to_sql(ty, out),
            DataType::Int2 => "smallint".to_sql(ty, out),
            DataType::Integer => "integer".to_sql(ty, out),
            DataType::Int8 => "bigint".to_sql(ty, out),
            DataType::Real => "real".to_sql(ty, out),
            DataType::Double => "double precision".to_sql(ty, out),
            DataType::Text => "text".to_sql(ty, out),
            DataType::TextArray => "text[]".to_sql(ty, out),
            DataType::Timestamp => "timestamptz".to_sql(ty, out),
            DataType::Numeric => "numeric".to_sql(ty, out),
            DataType::NumericArray => "numeric[]".to_sql(ty, out),
        }
    }

    fn accepts(ty: &Type) -> bool
    where
        Self: Sized,
    {
        ty == &Type::TEXT
    }

    to_sql_checked!();
}

impl fmt::Display for DataType {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            DataType::Boolean => write!(f, "boolean"),
            DataType::Int2 => write!(f, "smallint"),
            DataType::Integer => write!(f, "integer"),
            DataType::Int8 => write!(f, "bigint"),
            DataType::Real => write!(f, "real"),
            DataType::Double => write!(f, "double precision"),
            DataType::Text => write!(f, "text"),
            DataType::TextArray => write!(f, "text[]"),
            DataType::Timestamp => write!(f, "timestamp"),
            DataType::Numeric => write!(f, "numeric"),
            DataType::NumericArray => write!(f, "numeric[]"),
        }
    }
}

impl From<&str> for DataType {
    fn from(value: &str) -> DataType {
        match value {
            "smallint" => DataType::Int2,
            "integer" => DataType::Integer,
            "bigint" => DataType::Int8,
            "numeric" => DataType::Numeric,
            "real" => DataType::Real,
            "double precision" => DataType::Double,
            "text" => DataType::Text,
            "text[]" => DataType::TextArray,
            "timestamptz" => DataType::Timestamp,
            &_ => DataType::Text,
        }
    }
}

#[derive(Debug, PartialEq, Clone)]
pub enum MeasValue {
    Int2(Option<i16>),
    Integer(Option<i32>),
    Int8(Option<i64>),
    Real(Option<f32>),
    Double(Option<f64>),
    Text(String),
    TextArray(Vec<String>),
    Timestamp(chrono::DateTime<chrono::Utc>),
    Numeric(Option<Decimal>),
}

pub fn parse_meas_value(data_type: DataType, value: &str) -> MeasValue {
    match data_type {
        DataType::Int2 => {
            let value: Option<i16> = value.parse().ok();

            MeasValue::Int2(value)
        },
        DataType::Integer => {
            let value: Option<i32> = value.parse().ok();

            MeasValue::Integer(value)
        },
        DataType::Numeric => {
            let value: Option<Decimal> = value.parse().ok();

            MeasValue::Numeric(value)
        },
        DataType::Int8 => {
            let value: Option<i64> = value.parse().ok();

            MeasValue::Int8(value)
        },
        DataType::Real => {
            let value: Option<f32> = value.parse().ok();

            MeasValue::Real(value)
        },
        DataType::Double => {
            let value: Option<f64> = value.parse().ok();

            MeasValue::Double(value)
        },
        _ => {
            let value: String = value.to_string();

            MeasValue::Text(value)
        },
    }
}

pub fn map_int2(value: &Option<i16>, target_data_type: DataType) -> Result<MeasValue, Error> {
    match target_data_type {
        DataType::Int2 => Ok(MeasValue::Int2(*value)),
        DataType::Integer => Ok(MeasValue::Integer(value.map(|x| x as i32))),
        DataType::Int8 => Ok(MeasValue::Int8(value.map(|x| x as i64))),
        DataType::Numeric => Ok(MeasValue::Numeric(
            value.map(Decimal::from_i16).flatten(),
        )),
        DataType::Double => Ok(MeasValue::Double(value.map(f64::from_i16).flatten())),
        DataType::Real => Ok(MeasValue::Real(value.map(f32::from_i16).flatten())),
        _ => Err(Error::Runtime(crate::error::RuntimeError {
            msg: format!("No mapping defined for {:?} -> {}", value, target_data_type),
        })),
    }
}

pub fn map_int4(value: &Option<i32>, target_data_type: DataType) -> Result<MeasValue, Error> {
    match target_data_type {
        DataType::Integer => Ok(MeasValue::Integer(*value)),
        DataType::Int8 => Ok(MeasValue::Int8(value.map(|x| x as i64))),
        DataType::Numeric => Ok(MeasValue::Numeric(
            value.map(Decimal::from_i32).flatten(),
        )),
        DataType::Double => Ok(MeasValue::Double(value.map(f64::from_i32).flatten())),
        DataType::Real => Ok(MeasValue::Real(value.map(f32::from_i32).flatten())),
        _ => Err(Error::Runtime(crate::error::RuntimeError {
            msg: format!("No mapping defined for {:?} -> {}", value, target_data_type),
        })),
    }
}

pub fn map_int8(value: &Option<i64>, target_data_type: DataType) -> Result<MeasValue, Error> {
    match target_data_type {
        DataType::Integer => Ok(MeasValue::Integer(value.map(|x| x as i32))),
        DataType::Int8 => Ok(MeasValue::Int8(*value)),
        DataType::Numeric => Ok(MeasValue::Numeric(
            value.map(Decimal::from_i64).flatten(),
        )),
        DataType::Double => Ok(MeasValue::Double(value.map(f64::from_i64).flatten())),
        DataType::Real => Ok(MeasValue::Real(value.map(f32::from_i64).flatten())),
        _ => Err(Error::Runtime(crate::error::RuntimeError {
            msg: format!("No mapping defined for {:?} -> {}", value, target_data_type),
        })),
    }
}

pub fn map_real(value: &Option<f32>, target_data_type: DataType) -> Result<MeasValue, Error> {
    match target_data_type {
        DataType::Numeric => Ok(MeasValue::Numeric(
            value.map(Decimal::from_f32).flatten(),
        )),
        DataType::Real => Ok(MeasValue::Real(*value)),
        DataType::Double => Ok(MeasValue::Double(value.map(f64::from_f32).flatten())),
        DataType::Int8 => Ok(MeasValue::Int8(value.map(i64::from_f32).flatten())),
        DataType::Integer => Ok(MeasValue::Integer(
            value.map(i32::from_f32).flatten(),
        )),
        _ => Err(Error::Runtime(crate::error::RuntimeError {
            msg: format!("No mapping defined for {:?} -> {}", value, target_data_type),
        })),
    }
}

pub fn map_double(value: &Option<f64>, target_data_type: DataType) -> Result<MeasValue, Error> {
    match target_data_type {
        DataType::Numeric => Ok(MeasValue::Numeric(
            value.map(Decimal::from_f64).flatten(),
        )),
        DataType::Double => Ok(MeasValue::Double(*value)),
        DataType::Int8 => Ok(MeasValue::Int8(value.map(i64::from_f64).flatten())),
        DataType::Integer => Ok(MeasValue::Integer(
            value.map(i32::from_f64).flatten(),
        )),
        _ => Err(Error::Runtime(crate::error::RuntimeError {
            msg: format!("No mapping defined for {:?} -> {}", value, target_data_type),
        })),
    }
}

pub fn map_numeric(
    value: &Option<Decimal>,
    target_data_type: DataType,
) -> Result<MeasValue, Error> {
    match target_data_type {
        DataType::Integer => Ok(MeasValue::Integer(value.map(|x| x.to_i32()).flatten())),
        DataType::Int8 => Ok(MeasValue::Int8(value.map(|x| x.to_i64()).flatten())),
        DataType::Real => Ok(MeasValue::Real(value.map(|x| x.to_f32()).flatten())),
        DataType::Double => Ok(MeasValue::Double(value.map(|x| x.to_f64()).flatten())),
        DataType::Numeric => Ok(MeasValue::Numeric(*value)),
        _ => Err(Error::Runtime(crate::error::RuntimeError {
            msg: format!("No mapping defined for {:?} -> {}", value, target_data_type),
        })),
    }
}

impl MeasValue {
    pub fn null_value_of_type(data_type: DataType) -> MeasValue {
        match data_type {
            DataType::Int2 => MeasValue::Int2(None),
            DataType::Integer => MeasValue::Integer(None),
            DataType::Numeric => MeasValue::Numeric(None),
            DataType::Int8 => MeasValue::Int8(None),
            DataType::Real => MeasValue::Real(None),
            DataType::Double => MeasValue::Double(None),
            _ => MeasValue::Text("".to_string())
        }
    }

    pub fn to_value_of(&self, data_type: DataType) -> Result<MeasValue, Error> {
        match self {
            MeasValue::Int2(v) => map_int2(v, data_type),
            MeasValue::Integer(v) => map_int4(v, data_type),
            MeasValue::Int8(v) => map_int8(v, data_type),
            MeasValue::Real(v) => map_real(v, data_type),
            MeasValue::Double(v) => map_double(v, data_type),
            MeasValue::Text(v) => match data_type {
                DataType::Text => Ok(MeasValue::Text(v.to_string())),
                _ => Err(Error::Runtime(crate::error::RuntimeError {
                    msg: format!("No mapping defined for {:?} -> {}", v, data_type),
                })),
            },
            MeasValue::TextArray(v) => match data_type {
                DataType::Text => Ok(MeasValue::Text(v.join(","))),
                _ => Err(Error::Runtime(crate::error::RuntimeError {
                    msg: format!("No mapping defined for {:?} -> {}", v, data_type),
                })),
            },
            MeasValue::Timestamp(v) => match data_type {
                DataType::Timestamp => Ok(MeasValue::Timestamp(*v)),
                _ => Err(Error::Runtime(crate::error::RuntimeError {
                    msg: format!("No mapping defined for {:?} -> {}", v, data_type),
                })),
            },
            MeasValue::Numeric(v) => map_numeric(v, data_type),
        }
    }
}

impl fmt::Display for MeasValue {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            MeasValue::Int2(v) => match v {
                Some(i) => write!(f, "{}", i),
                None => write!(f, "NULL"),
            },
            MeasValue::Integer(v) => match v {
                Some(i) => write!(f, "{}", i),
                None => write!(f, "NULL"),
            },
            MeasValue::Int8(v) => match v {
                Some(i) => write!(f, "{}", i),
                None => write!(f, "NULL"),
            },
            MeasValue::Real(v) => match v {
                Some(i) => write!(f, "{}", i),
                None => write!(f, "NULL"),
            },
            MeasValue::Double(v) => match v {
                Some(i) => write!(f, "{}", i),
                None => write!(f, "NULL"),
            },
            MeasValue::Text(v) => write!(f, "{}", v),
            MeasValue::TextArray(_) => write!(f, "ARRAY(text)"),
            MeasValue::Timestamp(v) => write!(f, "{}", v),
            MeasValue::Numeric(v) => match v {
                Some(i) => write!(f, "{}", i),
                None => write!(f, "NULL"),
            },
        }
    }
}

trait ToType {
    fn to_type(&self) -> &Type;
}

impl ToType for MeasValue {
    fn to_type(&self) -> &Type {
        match self {
            MeasValue::Int2(_) => &Type::INT2,
            MeasValue::Integer(_) => &Type::INT4,
            MeasValue::Int8(_) => &Type::INT8,
            MeasValue::Real(_) => &Type::NUMERIC,
            MeasValue::Double(_) => &Type::NUMERIC,
            MeasValue::Text(_) => &Type::TEXT,
            MeasValue::TextArray(_) => &Type::TEXT_ARRAY,
            MeasValue::Timestamp(_) => &Type::TIMESTAMPTZ,
            MeasValue::Numeric(_) => &Type::NUMERIC,
        }
    }
}

impl ToSql for MeasValue {
    fn to_sql(
        &self,
        ty: &Type,
        out: &mut bytes::BytesMut,
    ) -> Result<postgres_types::IsNull, Box<dyn std::error::Error + Sync + Send>>
    where
        Self: Sized,
    {
        match self {
            MeasValue::Int2(x) => x.to_sql(ty, out),
            MeasValue::Integer(x) => x.to_sql(ty, out),
            MeasValue::Int8(x) => x.to_sql(ty, out),
            MeasValue::Real(x) => x.to_sql(ty, out),
            MeasValue::Double(x) => x.to_sql(ty, out),
            MeasValue::Text(x) => x.to_sql(ty, out),
            MeasValue::TextArray(x) => x.to_sql(ty, out),
            MeasValue::Timestamp(x) => x.to_sql(ty, out),
            MeasValue::Numeric(x) => x.to_sql(ty, out),
        }
    }

    fn accepts(_ty: &Type) -> bool
    where
        Self: Sized,
    {
        true
    }

    fn to_sql_checked(
        &self,
        ty: &Type,
        out: &mut bytes::BytesMut,
    ) -> Result<postgres_types::IsNull, Box<dyn std::error::Error + Sync + Send>> {
        match self {
            MeasValue::Int2(x) => x.to_sql_checked(ty, out),
            MeasValue::Integer(x) => x.to_sql_checked(ty, out),
            MeasValue::Int8(x) => x.to_sql_checked(ty, out),
            MeasValue::Real(x) => x.to_sql_checked(ty, out),
            MeasValue::Double(x) => x.to_sql_checked(ty, out),
            MeasValue::Text(x) => x.to_sql_checked(ty, out),
            MeasValue::TextArray(x) => x.to_sql_checked(ty, out),
            MeasValue::Timestamp(x) => x.to_sql_checked(ty, out),
            MeasValue::Numeric(x) => x.to_sql_checked(ty, out),
        }
    }
}

lazy_static! {
    pub static ref INT2_NONE_VALUE: MeasValue = MeasValue::Int2(None);
    pub static ref INTEGER_NONE_VALUE: MeasValue = MeasValue::Integer(None);
    pub static ref INT8_NONE_VALUE: MeasValue = MeasValue::Int8(None);
    pub static ref NUMERIC_NONE_VALUE: MeasValue = MeasValue::Numeric(None);
    pub static ref TEXT_NONE_VALUE: MeasValue = MeasValue::Text("".to_string());
}
