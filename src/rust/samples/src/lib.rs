pub mod hyperview {
    use oauth2::{
        basic::BasicClient, reqwest::http_client, AuthUrl, ClientId, ClientSecret, Scope,
        TokenResponse, TokenUrl,
    };
    use serde::{Deserialize, Serialize};

    #[derive(Debug, Serialize, Deserialize, Default)]
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
}
