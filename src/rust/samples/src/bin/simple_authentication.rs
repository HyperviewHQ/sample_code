use confy;
use hv_api_integration_samples::hyperview::{get_auth_header, get_config_path, AppConfig};

use reqwest::header::{ACCEPT, AUTHORIZATION, CONTENT_TYPE};
use serde_json::Value;
use std::{path::Path, process};

fn main() {
    // Read configuration and map to configuration object
    // config is expected in $HOME/.hyperview/hv_config.toml

    let config_path = get_config_path();

    if !Path::new(&config_path).exists() {
        // if the config file does not exist exit with a non zero exit code.
        println!("Error: Hyperview configuration file does not exist.");
        process::exit(1);
    }
    let hv_config: AppConfig = confy::load_path(config_path).unwrap();

    // Instantiate a client
    let req = reqwest::blocking::Client::new();

    // Construct target test URL
    let target_url = format!(
        "{}/api/asset/assets?(limit)=25&(sort)=%2BId",
        hv_config.instance_url
    );

    // Get formatted auth header
    let auth = get_auth_header(hv_config);

    // Fetch test data from api
    let resp = req
        .get(target_url)
        .header(AUTHORIZATION, auth)
        .header(CONTENT_TYPE, "application/json")
        .header(ACCEPT, "application/json")
        .send()
        .unwrap()
        .json::<Value>()
        .unwrap();

    println!("{}", serde_json::to_string_pretty(&resp).unwrap());
}
