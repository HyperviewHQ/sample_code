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
    rack_u_location: Option<String>,
    rack_side: Option<String>,
    rack_position: Option<String>,
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

            // Find parent id
            let parent_id = if r.asset_type == "rack" {
                get_parent_id(
                    &auth_header,
                    &hv_config.instance_url,
                    &"Location".to_string(),
                    &r.location,
                )
            } else {
                get_parent_id(
                    &auth_header,
                    &hv_config.instance_url,
                    &"Rack".to_string(),
                    &r.location,
                )
            };

            // Compose the asset properties array
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

            // Compose locationData object
            let mut location_data = json!({ "parentId": parent_id.clone() });
            if let Some(rack_side) = r.rack_side {
                location_data["rackSide"] = Value::from(rack_side.to_lowercase());
            }
            if let Some(rack_u_location) = r.rack_u_location {
                location_data["rackULocation"] = Value::from(rack_u_location.to_lowercase());
            }
            if let Some(rack_position) = r.rack_position {
                location_data["rackPosition"] = Value::from(rack_position.to_lowercase());
            }

            // Reconcile asset lifecycle state
            let mut asset_lifecycle_state = "0".to_string();
            if !r.lifecycle_state.is_empty() {
                asset_lifecycle_state = r.lifecycle_state.clone();
            }

            // Compose asset object
            let asset = json!({
                "name": r.name,
                "status": 0,
                "assetTypeId": r.asset_type,
                "parentId": parent_id,
                "assetLifecycleState": asset_lifecycle_state,
                "productId": r.model_id,
                "creatableAssetProperties": asset_properties,
                "locationData": location_data
            });

            println!(
                "-------------------------\nPayload: {}\n",
                serde_json::to_string_pretty(&asset).unwrap()
            );

            // Instantiate a client
            let req = reqwest::blocking::Client::new();

            // Post asset data to API
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

            println!(
                "Server Response: {}\n",
                serde_json::to_string_pretty(&resp).unwrap()
            );
        }
    } else {
        println!("Error: Could not open csv file.");
    }
}
