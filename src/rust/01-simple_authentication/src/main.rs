use std::{path::Path, process};

use confy;
use oauth2::{
    basic::BasicClient, reqwest::http_client, AuthUrl, ClientId, ClientSecret, Scope,
    TokenResponse, TokenUrl,
};
use reqwest::header::{ACCEPT, AUTHORIZATION, CONTENT_TYPE};
use serde::{Deserialize, Serialize};

// Design config struct
#[derive(Debug, Serialize, Deserialize, Default, Clone)]
struct AppConfig {
    client_id: String,
    client_secret: String,
    scope: String, // This could be a vector of string if more than one scope
    auth_url: String,
    token_url: String,
    instance_url: String,
}

fn main() {
    // Read configuration and map to configuration object
    // config is expected in $HOME/.hyperview/hv_config.toml

    let home_path = dirs::home_dir().expect("Error: Home directory not found");
    let config_path = format!("{}/.hyperview/hv_config.toml", home_path.to_str().unwrap());

    if !Path::new(&config_path).exists() {
        // if the config file does not exist exit with a non zero exit code.
        println!("Error: Hyperview configuration file does not exist.");
        process::exit(1);
    }
    let hv_config: AppConfig = confy::load_path(config_path).unwrap();

    // Create client
    let client = BasicClient::new(
        ClientId::new(hv_config.client_id),
        Some(ClientSecret::new(hv_config.client_secret)),
        AuthUrl::new(hv_config.auth_url).unwrap(),
        Some(TokenUrl::new(hv_config.token_url).unwrap()),
    );

    // Fetch token
    let token_result = client
        .exchange_client_credentials()
        .add_scope(Scope::new(hv_config.scope))
        .request(http_client)
        .unwrap();

    // Format Authorization header
    let auth = format!("Bearer {}", token_result.access_token().secret());

    // Instantiate a client
    let req = reqwest::blocking::Client::new();

    // construct target test URL
    let target_url = format!(
        "{}/api/asset/assets?(limit)=25&(sort)=%2BId",
        hv_config.instance_url
    );

    // Fetch test data from api
    let resp = req
        .get(target_url)
        .header(AUTHORIZATION, auth)
        .header(CONTENT_TYPE, "application/json")
        .header(ACCEPT, "application/json")
        .send()
        .unwrap()
        .text()
        .unwrap();

    // print unformated return data to stdout
    println!("{:?}", resp);
}
