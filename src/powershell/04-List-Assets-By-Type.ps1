<#
  .SYNOPSIS
  Download asset information into an array of json objects

  .DESCRIPTION
  Queries the platform for racks and return the information to stdout. 

  .PARAMETER AssetType
  A string value for asset type. E.g Server, Rack or Location

  .INPUTS
  None.

  .OUTPUTS
  List of assets in a flat output format suitable for integration with other systems.

  .EXAMPLE
  > pwsh 04-List-Assets-By-Type.ps1 -AssetType Server
#>

Param(

    [Parameter(Mandatory = $true)]

    [string]$AssetType

) #end param

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

# Get a list of assets from the API
$Assets = Get-AssetsByType -AccessToken $accessToken -ApiHost $HostName -Type $AssetType;

# Receive and map output

if ($Assets.length -eq 0) {
    Write-Host "Query return zero results";
    Exit 1;
}

foreach ($asset in $Assets) {
    $output = @{
        "u_dns_hostname"              = "";
        "u_hyperview_asset_type"      = $asset.assetType;
        "u_hyperview_id"              = $asset.id;
        "u_lifecycle_state"           = $assset.assetLifecycleState;
        "u_location_path"             = $asset.locationDisplayValue;        
        "u_manufacturer"              = $asset.manufacturerName;
        "u_model"                     = $asset.productName;
        "u_name"                      = $asset.displayName; # use the displayNameLowerCase property if you want the output normalized
        "u_operating_system"          = "";
        "u_power_providing_asset_ids" = "";
        "u_power_providing_assets"    = "";
        "u_rack_elevation"            = "";
        "u_rack_location"             = "";
        "u_rack_location_id"          = "";
        "u_rack_side"                 = "";
        "u_room_location"             = "";
        "u_room_location_id"          = "";
        "u_serial_number"             = $asset.serialNumber;
    };

    Write-Host ($output | ConvertTo-Json -Depth 9);   
}
