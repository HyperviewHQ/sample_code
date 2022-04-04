<#
  .SYNOPSIS
  Performs a simple upload of floor mounted assets.

  .DESCRIPTION
  Performs a simple upload of floor mounted assets. Uses a standard CSV import format.
  Review example file for more information. Note that that import file uses internal IDs
  for model information and asset type.

  .INPUTS
  Two configuration files. One for hostname and another for client credentials.
  Data file in ./data/floor_mounted.csv.

  .OUTPUTS
  Status of uploads and any API error messages, where applicable.
#>

# Import asset helper functions
Import-Module ./lib/asset_helpers.psm1

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
$HostName = $HyperviewHost.Hostname;
$TokenUrl = [string]::Format("https://{0}/connect/token", $HostName);

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

# Read CSV File
$CsvData = Import-Csv -Path ./data/floor_mounted.csv

# Start Upload Loop
foreach ($line in $CsvData) {
    $LocationId = Get-LocationId -AccessToken $accessToken -Location $line.Location -ApiHost $HostName -Type "Location";

    $AssetObject = @{
        "name"                     = $line.Name;
        "status"                   = 0; # Hardcode asset status id
        "assetTypeId"              = $line.AssetType;
        "parentId"                 = $LocationId;
        "creatableAssetProperties" = @(
            @{
                "type"  = "serialNumber";
                "value" = $line.SerialNumber;
            }
        );
        "assetLifecycleState"      = 0;
        "productId"                = $line.ModelId;
    };

    # Add asset tracker id if it is in the upload file
    if (-not ([string]::IsNullOrEmpty($line.AssetTrackerId))) {
        $AssetObject.creatableAssetProperties += @{
            "type"  = 147;
            "value" = $line.AssetTrackerId;
        }
    }

    Write-Host "Creating Asset: " $line.Name " Location: " $line.Location;

    Add-Asset -AssetObject $AssetObject -ApiHost $HostName ;
}
