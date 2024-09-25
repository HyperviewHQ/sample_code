#!/bin/env pwsh

<#
  .SYNOPSIS
    List alarm event from the API.

  .DESCRIPTION
    List alarm events from the API.

  .INPUTS
    Two configuration files. One for hostname and another for client credentials.

  .PARAMETER Skip
    Optional parameter to specify the number of records to skip. Default: 0.

  .PARAMETER Limit
    Optional parameter to specify the record limit to pull from the API. Default: 100.

  .PARAMETER AllEvents
    Optional parameter to specify where to list all alarm events.
    Not setting this will list only unacknowledged events

  .OUTPUTS
    API response in CSV to stdout.
#>

param (
    [Parameter(HelpMessageBaseName="Specify records to skip")]
    [int] $Skip = [int] 0,

    [Parameter(HelpMessageBaseName="Specify record limit")]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $Limit = [int] 100,

    [Parameter(HelpMessageBaseName="Specify if all events should be fetched")]
    [switch] $AllEvents
)

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

try
{
    $resp = Invoke-RestMethod -Method Post -Headers $FetchTokenHeaders -Body $PayloadBody -Uri $TokenUrl
    Write-Debug "Successfully authenticated...";
    $accessToken = $resp.access_token;
} catch
{
    Write-Debug "Failed to authenticate. Exiting...";
    Exit $LASTEXITCODE;
}

$Headers = @{
    "Content-Type"  = "application/json";
    "Authorization" = "Bearer $accessToken";
};

Write-Debug ("Access Token = $accessToken");

# Build request
$Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty);
$Parameters['skip'] = $Skip;
$Parameters['take'] = $Limit;

if (-not $AllEvents)
{
    $Parameters['filter'] = '["isActive","=",true]';
}

$BaseUri = [string]::Format("{0}/api/asset/alarmEvents/allAssets/advancedCollection", $HostName);
$Request = [System.UriBuilder]$BaseUri;
$Request.Query = $Parameters.ToString();

# Invoke a simple API connection to fetch data
Write-Debug("Calling Endpoint: $Request");

$Response = Invoke-RestMethod -Uri $Request.Uri -Method Get -Headers $Headers

# Write the data object to CSV and stream to stdout
if ($null -ne $Response.data)
{
    $Response.data | ConvertTo-Csv
}
