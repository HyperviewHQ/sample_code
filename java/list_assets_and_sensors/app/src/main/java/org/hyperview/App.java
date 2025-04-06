package org.hyperview;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.StringJoiner;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import io.github.cdimascio.dotenv.Dotenv;

public class App {
    private static final ObjectMapper object_mapper = new ObjectMapper();
    public static void main(String[] args) throws Exception {
        // Load .env file
        Dotenv dotenv = Dotenv
                            .configure()
                            .directory("assets")
                            .filename(".env")
                            .load();

        // load configuration variables
        String client_id = dotenv.get("CLIENT_ID");
        String client_secret = dotenv.get("CLIENT_SECRET");
        String instance_url = dotenv.get("INSTANCE_URL");

        // Build http client
        HttpClient http_client = HttpClient
                                    .newBuilder()
                                    .connectTimeout(Duration.ofSeconds(30))
                                    .build();
        
        String access_token = authenticate(instance_url, client_id, client_secret, http_client);

        // Fetch asset list
        JsonNode asset_list = getAssetList(instance_url, access_token, http_client);

        // Get asset metadata
        JsonNode metadata = asset_list.get("_metadata");
        System.out.println("Asset response metadata: " + metadata.toPrettyString());
    }

    private static String authenticate(
        String instance_url,
        String client_id,
        String client_secret,
        HttpClient http_client) throws Exception {

        // Set token endpoint    
        String token_endpoint = instance_url + "/connect/token";
        System.out.println("Token endpoint: " + token_endpoint);

        // Build auth payload
        String payload = "grant_type=client_credentials&client_id=" + client_id + "&client_secret=" + client_secret;

        HttpRequest req = HttpRequest
                            .newBuilder()
                            .POST(HttpRequest.BodyPublishers.ofString(payload))
                            .uri(URI.create(token_endpoint))
                            .header("Content-Type", "application/x-www-form-urlencoded")
                            .header("Accept", "application/json")
                            .timeout(Duration.ofSeconds(30))
                            .build();
        
        HttpResponse<String> resp = http_client.send(req, 
                HttpResponse.BodyHandlers.ofString());
        
        JsonNode json_response = object_mapper.readTree(resp.body());

        return json_response.get("access_token").asText();
    }

    private static JsonNode getAssetList(
        String instance_url,
        String access_token,
        HttpClient http_client) throws Exception{
        // Build parameter
        // Fetch the first CRAC units

        Map<String, String> params = new HashMap<>();
        params.put("assetType", "crac");
        params.put("includeDimensions", "false");
        params.put("(after)", "0");
        params.put("(limit)", "10");
        params.put("(sort)", "+Id");

        StringJoiner paramsString = new StringJoiner("&");

        for(Map.Entry<String, String> param : params.entrySet()) {
            String key = URLEncoder.encode(param.getKey(), StandardCharsets.UTF_8);
            String value = URLEncoder.encode(param.getValue(), StandardCharsets.UTF_8);
            paramsString.add(key + "=" + value);
        }

        // Set asset endpoint
        String asset_endpoint = instance_url + "/api/asset/assets" + "?" + paramsString.toString();
        System.out.println("Asset endpoint: " + asset_endpoint);

        // Set query params
        HttpRequest req = HttpRequest
                            .newBuilder()
                            .GET()
                            .uri(URI.create(asset_endpoint))
                            .header("Content-Type", "application/json")
                            .header("Authorization", "Bearer " + access_token)
                            .timeout(Duration.ofSeconds(30))
                            .build();

        HttpResponse<String> resp = http_client.send(req, HttpResponse.BodyHandlers.ofString());

        // return data
        return object_mapper.readTree(resp.body());
    }
}
