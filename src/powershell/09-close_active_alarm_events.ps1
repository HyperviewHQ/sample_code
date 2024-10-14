#!/bin/env pwsh

<#
  .SYNOPSIS
    List alarm event from the API.

  .DESCRIPTION
    List alarm events from the API.

  .INPUTS
    Two configuration files. One for hostname and another for client credentials.

  .PARAMETER BatchSize
    Optional parameter to specify size of the batch. Default: 100.

  .OUTPUTS
    API response stdout.
#>

param (
    [Parameter(HelpMessageBaseName="Specify the size of the alarm event acknowledge batch, default 100")]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $BatchSize = [int] 100
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

$HostName = [string]::Format("https://{0}", $HyperviewHost.Hostname);
$TokenUrl = [string]::Format("{0}/connect/token", $HostName);
$BaseWorkUri = [string]::Format("{0}/api/asset/alarmEvents/bulkClose", $HostName);

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

# Read CSV File
$CsvData = Import-Csv -Path ./data/alarm_ids_to_close.csv

$WorkQueue = New-Object System.Collections.ArrayList;
$WorkQueue.Add(@());
$WorkQueueIndex = 0;

for ($i = 0; $i -lt $CsvData.Length; $i++)
{
    if ($i -gt 0)
    {
        if (($i % $BatchSize) -eq 0)
        {
            $WorkQueueIndex += 1;
            $WorkQueue.Add(@());
        }
    }

    $WorkQueue[$WorkQueueIndex] += $CsvData[$i].id;
}

foreach($WorkBatch in $WorkQueue)
{
    $Request = [System.UriBuilder]$BaseWorkUri;
    $Body = $WorkBatch | ConvertTo-Json;

    # Invoke a simple API connection to fetch data
    Write-Debug("Calling Endpoint: $Request");
    Write-Debug("Request Body: $Body");

    $Response = Invoke-WebRequest -Uri $Request.Uri -Method Put -Headers $Headers -Body $Body;
    Write-Host ("API Response: ", $Response.StatusCode)
}
