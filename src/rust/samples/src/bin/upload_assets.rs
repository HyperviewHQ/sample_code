use std::{path::Path, process};

use clap::Parser;
use hv_api_integration_samples::hyperview::{get_config_path, AppConfig};
use serde::Deserialize;

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

    if let Ok(mut reader) = csv::Reader::from_path(args.filename) {
        for record in reader.deserialize() {
            let r: Record = record.unwrap();
            println!(
                "{}, {}, {}, {}, {}, {}, {}",
                r.location,
                r.name,
                r.lifecycle_state,
                r.asset_type,
                r.model_id,
                r.serial_number,
                r.asset_tag
            );
        }
    } else {
        println!("Error: Could not open csv file.");
    }
}
