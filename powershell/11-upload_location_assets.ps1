#!/bin/env pwsh

<#
  .SYNOPSIS
    Performs a simple upload of floor mounted assets.

  .DESCRIPTION
    Performs a simple upload of location assets. Uses a standard CSV import format.
    Review example file for more information. Note that that import file uses internal IDs.

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
$CsvData = Import-Csv -Path  ./data/locations.csv

# Start Upload Loop
foreach ($line in $CsvData)
{
	$Name = $line.Name;
	$ParentId = $line.ParentId
	$Address = $line.Address
	$Latitude = $line.Latitude
	$Longitude = $line.Longitude

	$AssetObject = @{
		"assetTypeId"= "location";
		"name"= "$($Name)";
		"parentId"= "$($ParentId)";
		"creatableAssetProperties"= @(
			@{
				"type"= "locationType";
				"value"= "OnPremise";
			},
			@{
				"type"= "streetAddress";
				"value"= "$($Address)";
			},
			@{
				"type"= "latitude";
				"value"= $($Latitude);
			},
			@{
				"type"= "longitude";
				"value"= $($Longitude);
			}
		)
	};

	Write-Host "Creating Location: " $line.Name ;

	$Response = Add-Asset -AssetObject $AssetObject -ApiHost $HostName -AccessToken $accessToken;

	Write-Host "Server Response: " $Response;
}
