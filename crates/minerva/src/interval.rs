use std::time::Duration;

use super::error::{Error, RuntimeError};

use regex::Regex;

pub fn parse_interval(interval_str: &str) -> Result<Duration, Error> {
    let month_re = Regex::new("mon(s|th|ths)?").unwrap();
    let interval_re = Regex::new(r"^(\d{2}):(\d{2}):(\d{2})$").unwrap();

    let capture_result = interval_re.captures(interval_str);

    let interval_str: String = match capture_result {
        Some(cap) => {
            format!("{} hours {} minutes {} seconds", &cap[1], &cap[2], &cap[3])
        }
        None => month_re.replace(interval_str, "month").to_string(),
    };

    humantime::parse_duration(&interval_str).map_err(|e| {
        Error::Runtime(RuntimeError::from_msg(format!(
            "Could not parse '{interval_str}' as interval: {e}"
        )))
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_interval() {
        let dur = parse_interval("00:01:00").unwrap();

        let expected_dur = Duration::new(60, 0);

        assert_eq!(dur, expected_dur);

        let dur = parse_interval("2 months 29 days").unwrap();

        let expected_dur = Duration::new(7765632, 0);

        assert_eq!(dur, expected_dur);
    }
}
