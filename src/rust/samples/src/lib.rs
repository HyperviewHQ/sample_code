pub mod hyperview {
    use oauth2::{
        basic::BasicClient, reqwest::http_client, AuthUrl, ClientId, ClientSecret, Scope,
        TokenResponse, TokenUrl,
    };
    use reqwest::header::{ACCEPT, AUTHORIZATION, CONTENT_TYPE};
    use serde::{Deserialize, Serialize};
    use serde_json::{json, Value};

    #[derive(Debug, Serialize, Deserialize, Default, Clone)]
    pub struct AppConfig {
        pub client_id: String,
        pub client_secret: String,
        pub scope: String, // This could be a vector of string if more than one scope
        pub auth_url: String,
        pub token_url: String,
        pub instance_url: String,
    }

    pub fn get_config_path() -> String {
        let home_path = dirs::home_dir().expect("Error: Home directory not found");

        format!("{}/.hyperview/hv_config.toml", home_path.to_str().unwrap())
    }

    pub fn get_auth_header(hv_config: AppConfig) -> String {
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
        format!("Bearer {}", token_result.access_token().secret())
    }

    pub fn get_parent_id(
        auth_header: &String,
        instance_url: &String,
        asset_type: &String,
        location_path: &String,
    ) -> String {
        let target_url = format!("{}/api/asset/search", instance_url);
        let mut split_path: Vec<&str> = location_path.split("/").collect();
        let location = split_path.pop().unwrap();
        let location_tabbed = split_path.join("\t");

        let search_query: Value = json!({
            "from": "0",
            "size": "10",
            "selectedFields": ["DisplayName"],
            "searchComplexDataFields": [],
            "query": {
                "bool": {
                    "filter": {
                        "bool": {
                            "must": [
                                {
                                    "match": {
                                        "assetType": asset_type
                                    }
                                },
                                {
                                    "wildcard": {
                                        "tabDelimitedPath": format!("{}*", location_tabbed)
                                    }
                                }
                            ]
                        }
                    },
                    "should": [
                        {
                            "query_string": {
                                "query": format!("\"{}\"", location),
                                "fields":[
                                    "displayNameLowerCase^5",
                                    "*"
                                ]
                            }
                        }
                    ],
                    "minimum_should_match": "1",
                }
            }
        });

        // Instantiate a client
        let req = reqwest::blocking::Client::new();

        // Fetch test data from api
        let resp = req
            .post(target_url)
            .header(AUTHORIZATION, auth_header)
            .header(CONTENT_TYPE, "application/json")
            .header(ACCEPT, "application/json")
            .json(&search_query)
            .send()
            .unwrap()
            .json::<Value>()
            .unwrap();

        let asset_data = resp["data"].as_array().unwrap();
        if asset_data.len() > 0 {
            asset_data[0]["id"].to_string().replace("\"", "")
        } else {
            String::new()
        }
    }
}
