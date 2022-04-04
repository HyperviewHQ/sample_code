use std::{path::Path, process};

use clap::Parser;
use hv_api_integration_samples::hyperview::{
    get_auth_header, get_config_path, get_parent_id, AppConfig,
};
use reqwest::header::{ACCEPT, AUTHORIZATION, CONTENT_TYPE};
use serde::Deserialize;
use serde_json::{json, Value};

#[derive(Parser, Debug)]
#[clap(author, version, about, long_about = None)]
struct Args {
    #[clap(short = 'f', long)]
    filename: String,
}

#[derive(Debug, Clone, Deserialize)]
struct Record {
    location: String,
    name: String,
    lifecycle_state: String,
    asset_type: String,
    model_id: String,
    serial_number: String,
    asset_tag: String,
}

fn main() {
    let args = Args::parse();

    // Read configuration and map to configuration object
    // config is expected in $HOME/.hyperview/hv_config.toml

    let config_path = get_config_path();

    if !Path::new(&config_path).exists() {
        // if the config file does not exist exit with a non zero exit code.
        println!("Error: Hyperview configuration file does not exist.");
        process::exit(1);
    }

    let hv_config: AppConfig = confy::load_path(config_path).unwrap();

    // Construct target test URL
    let target_url = format!("{}/api/asset/assets", hv_config.instance_url);

    // Get formatted auth header
    let auth_header = get_auth_header(hv_config.clone());

    if let Ok(mut reader) = csv::Reader::from_path(args.filename) {
        for record in reader.deserialize() {
            let r: Record = record.unwrap();

            let parent_id = get_parent_id(
                &auth_header,
                &hv_config.instance_url,
                &"Location".to_string(),
                &r.location,
            );

            let mut asset_properties: Vec<Value> = Vec::new();

            asset_properties.push(json!({
                "type": "serialNumber",
                "value": r.serial_number
            }));

            if !r.asset_tag.is_empty() {
                asset_properties.push(json!({
                    "type": "assetTag",
                    "value": r.asset_tag
                }));
            }

            let mut asset_lifecycle_state = "0".to_string();
            if !r.lifecycle_state.is_empty() {
                asset_lifecycle_state = r.lifecycle_state.clone();
            }

            let asset = json!({
                "name": r.name,
                "status": 0,
                "assetTypeId": r.asset_type,
                "parentId": parent_id,
                "assetLifecycleState": asset_lifecycle_state,
                "productId": r.model_id,
                "creatableAssetProperties": asset_properties
            });

            println!("{}", serde_json::to_string_pretty(&asset).unwrap());

            // Instantiate a client
            let req = reqwest::blocking::Client::new();

            // Fetch test data from api
            let resp = req
                .post(&target_url)
                .header(AUTHORIZATION, &auth_header)
                .header(CONTENT_TYPE, "application/json")
                .header(ACCEPT, "application/json")
                .json(&asset)
                .send()
                .unwrap()
                .json::<Value>()
                .unwrap();

            println!("{}", serde_json::to_string_pretty(&resp).unwrap());
        }
    } else {
        println!("Error: Could not open csv file.");
    }
}
