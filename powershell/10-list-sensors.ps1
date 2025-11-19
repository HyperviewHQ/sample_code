#!/bin/env pwsh

<#
  .SYNOPSIS
    Performs a simple API query.

  .DESCRIPTION
    This is a simple example script.

  .INPUTS
    Two configuration files. One for hostname and another for client credentials.

  .OUTPUTS
    API response in JSON to stdout.
#>

# To print debug statements while executing the script
# set $DebugPreference='Continue' before running the script

param(
	[Parameter(Mandatory=$false)]
	[int]$AssetLimit = 10,  # Default value of 10

	[Parameter(Mandatory=$true)]
	[string]$OutputFile
)

# Read client configuration
$ClientConfiguration = Get-Content -Raw -Path ./conf/client_credential.json | ConvertFrom-Json

# Read Hostname
$HyperviewHost = Get-Content -Raw -Path ./conf/hostname.json | ConvertFrom-Json

#Fetch access token.
$PayloadBody = @{
	grant_type    = "client_credentials"
	client_id     = $ClientConfiguration.ClientId
	client_secret = $ClientConfiguration.ClientSecret
};

$HostName = [string]::Format("https://{0}", $HyperviewHost.Hostname);
$TokenUrl = [string]::Format("{0}/connect/token", $HostName);

$FetchTokenHeaders = @{
	"Content-Type" = "application/x-www-form-urlencoded"
}

try
{
	$resp = Invoke-RestMethod -Method Post -Headers $FetchTokenHeaders -Body $PayloadBody -Uri $TokenUrl
	Write-Debug("Successfully authenticated...");
	$accessToken = $resp.access_token;
} catch
{
	Write-Output "Failed to authenticate. Exiting...";
	Exit $LASTEXITCODE;
}

$Headers = @{
	"Content-Type"  = "application/json";
	"Authorization" = "Bearer $accessToken";
};

Write-Debug("`nDebug: Access Token = $accessToken");

# Invoke a simple API connection to fetch data
$Uri = [string]::Format("{0}/api/asset/assets?(limit)=$AssetLimit&(sort)=%2BId", $HostName);

Write-Debug("`nCalling Endpoint: $Uri`n");

$Response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $Headers;

$AssetDataJson = $Response.data;

$AllSensors = @();

foreach ($Asset in $AssetDataJson)
{
	# Set asset id
	$Id = $($Asset.id)
	
	Write-Debug("Fetching Sensors for Asset ID: $($Asset.id)");

	$SensorsUri = [string]::Format("{0}/api/asset/sensors/{1}", $HostName, $Id);
	$Sensors = Invoke-RestMethod -Method Get -Headers $Headers -Uri $SensorsUri;
	
	Write-Debug("Read $($Sensors.Count) sensors from asset $Id");

	# Add new sensors to list
	$AllSensors += $Sensors;

	Start-Sleep -Milliseconds 50;
}

Write-Output("- Fetched $($AllSensors.Count) Sensors");
Write-Output("- Writing sensor data to file $OutputFile...");
$AllSensors | ConvertTo-Csv | Out-File -FilePath $OutputFile
