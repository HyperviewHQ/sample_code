<#
  .SYNOPSIS
  Performs a simple upload of in rack assets.

  .DESCRIPTION
  Performs a simple upload of in rack assets. Uses a standard CSV import format.
  Review example file for more information. Note that that import file uses internal IDs
  for model information and asset type.

  .PARAMETER InputPath
  None. 

  .PARAMETER OutputPath
  None.

  .INPUTS
  Two configuration files. One for hostname and another for client credentials.
  Data file in ./data/in_rack.csv.

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
$CsvData = Import-Csv -Path ./data/in_rack.csv

# Start Upload Loop
foreach ($line in $CsvData) {
    $LocationId = Get-LocationId -AccessToken $accessToken -Location $line.Location -ApiHost $HostName -Type "Rack";

    $AssetObject = @{
        "name"                     = $line.Name;
        "status"                   = 0; # Hardcode asset status id
        "assetTypeId"              = $line.AssetType;
        "parentId"                 = $LocationId;
        "creatableAssetProperties" = @(
            @{
                "type"  = 1;
                "value" = $line.SerialNumber;
            }
        );
        "assetLifecycleState"      = 0;
        "productId"                = $line.ModelId;
        "locationData"             = @{
            "parentId" = $LocationId;
            "rackSide" = [string]($line.RackSide).ToLower();
        };
    };

    if (-not ([string]::IsNullOrEmpty($line.Elevation))) {
        $assetObject.locationData += @{
            "rackULocation" = $line.Elevation;
        }
    }

    if (-not ([string]::IsNullOrEmpty($line.RackPosition))) {
        $assetObject.locationData += @{
            "rackPosition" = $line.RackPosition
        }
    }


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

