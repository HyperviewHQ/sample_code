#Fetch access token.
$PayloadBody = @{
    grant_type    = "client_credentials"
    client_id     = "<client id GUID>"
    client_secret = "<client secret GUID>"
};

# Put your hostname here
$TokenUrl = "https://nightly.hyperviewhq.com/connect/token"

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

Write-Host $accessToken

# Invoke a simple API connection to fetch data
## Put your hostname here as well
$Response = Invoke-RestMethod -Uri "$TokenUrl/api/asset/assets?(limit)=25&(sort)=%2BId" -Method Get -Headers $Headers

# Write the data object to a JSON array
$Response.data | ConvertTo-Json
