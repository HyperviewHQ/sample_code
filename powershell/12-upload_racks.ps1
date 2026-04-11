#!/bin/env pwsh

<#
  .SYNOPSIS
    Performs an upload of racks

  .DESCRIPTION
    Performs a upload of racks. Uses a standard CSV import format.
    Review example file for more information. Note that that import file uses internal IDs
    for model information and asset type.

  .INPUTS
    Two configuration files. One for hostname and another for client credentials.
    Data file in ./data/racks.csv.

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
$CsvData = Import-Csv -Path ./data/racks.csv;

# Start Upload Loop
foreach ($line in $CsvData)
{
	$AssetObject = @{
		"name"                     = $line.Name;
		"status"                   = 0; # Hardcode asset status id
		"assetTypeId"              = $line.AssetType;
		"parentId"                 = $line.ParentId;
		"creatableAssetProperties" = @();
		"assetLifecycleState"      = 0;
		"productId"                = $line.ModelId;
	};

	if (-not ([string]::IsNullOrEmpty($line.SerialNumber)))
	{
		$AssetObject.creatableAssetProperties += @{
			"type"  = "serialNumber";
			"value" = $line.SerialNumber;
		}
	}

	if (-not ([string]::IsNullOrEmpty($line.AssetTag)))
	{
		$AssetObject.creatableAssetProperties += @{
			"type"  = "assetTag";
			"value" = $line.AssetTag;
		}
	}

	Write-Host "Creating Asset: " $line.Name " Location: " $line.ParentId;

	$object = $AssetObject | ConvertTo-Json;

	Write-Debug $object;

	$Response = Add-Asset -AssetObject $AssetObject -ApiHost $HostName -AccessToken $accessToken;

	Write-Host "Server Response: " $Response;
}
