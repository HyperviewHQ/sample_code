<#
  .SYNOPSIS
  Performs a simple upload of in rack assets.

  .DESCRIPTION
  Performs a simple upload of in rack assets. Uses a standard CSV import format.
  Review example file for more information. Note that that import file uses internal IDs
  for model information and asset type.

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

try
{
    $resp = Invoke-RestMethod -Method Post -Headers $FetchTokenHeaders -Body $PayloadBody -Uri $TokenUrl
    Write-Verbose "Successfully authenticated...";
    $accessToken = $resp.access_token;
} catch
{
    Write-Output "Failed to authenticate. Exiting...";
    Exit $LASTEXITCODE;
}

# Read CSV File
$CsvData = Import-Csv -Path ./data/blades.csv

# Start Upload Loop
foreach ($line in $CsvData)
{
    $LocationId = Get-LocationId -AccessToken $accessToken -Location $line.Location -ApiHost $HostName -Type "BladeEnclosure";

    # Write-Host "DEBUG: Location ID = " $LocationId 

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
        };
    };

    # Add Bay Location id present
    if (-not ([string]::IsNullOrEmpty($line.BayLocation)))
    {
        $AssetObject.creatableAssetProperties += @{
            "type"  = "bayLocation";
            "value" = $line.BayLocation;
        }
    }

    Write-Host "Creating Asset: " $line.Name " Location: " $line.Location;

    $Response = Add-Asset -AssetObject $AssetObject -ApiHost $HostName -AccessToken $accessToken;

    Write-Host "Server Response: " $Response;
}

