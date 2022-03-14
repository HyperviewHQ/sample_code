#Fetch access token.
$PayloadBody = @{
    grant_type    = "client_credentials"
    client_id     = "<Client ID GUID>"
    client_secret = "<Client Secret GUID>"
};

# Put your Hyperview hostname here
$HostName = "https://<Hyperview Hostname>"
$TokenUrl = [string]::Format("{0}/connect/token", $HostName)

$FetchTokenHeaders = @{
    "Content-Type" = "application/x-www-form-urlencoded"
}

try {
    $resp = Invoke-RestMethod -Method Post -Headers $FetchTokenHeaders -Body $PayloadBody -Uri $TokenUrl
    Write-Verbose "Successfully authenticated...";
    $accessToken = $resp.access_token;
}
catch {
    Write-Output "Failed to authenticate. Exiting...";
    Exit $LASTEXITCODE;
}

$Headers = @{
    "Content-Type"  = "application/json";
    "Authorization" = "Bearer $accessToken";
};

Write-Host ("`nDebug: Access Token = $accessToken");

# Invoke a simple API connection to fetch data
$Uri = [string]::Format("{0}/api/asset/assets?(limit)=25&(sort)=%2BId", $HostName);

Write-Host("`nCalling Endpoint: $Uri`n");

$Response = Invoke-RestMethod -Uri "$Uri" -Method Get -Headers $Headers

# Write the data object to a JSON array

$Response.data | ConvertTo-Json
