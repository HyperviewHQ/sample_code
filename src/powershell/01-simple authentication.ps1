# Read Client Configuration
$ClientConfiguration = Get-Content -Raw -Path ./conf/client_credential.json | ConvertFrom-Json

# Read Hostname
$HyperviewHost = Get-Content -Raw -Path ./conf/hostname.json | ConvertFrom-Json

#Fetch access token.
$PayloadBody = @{
    grant_type    = "client_credentials"
    client_id     = $ClientConfiguration.ClientId
    client_secret = $ClientConfiguration.ClientSecret
};

# Put your Hyperview hostname here
$HostName = [string]::Format("https://{0}", $HyperviewHost.Hostname);
$TokenUrl = [string]::Format("{0}/connect/token", $HostName);

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
