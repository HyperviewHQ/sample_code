<#
  .DESCRIPTION
  A collection of asset API helper functions
#>

# Get Location Id for an asset using advanced search API
function Get-LocationId {
    param (
        $AccessToken,
        $Location,
        $ApiHost,
        $Type
    )

    $SearchUri = [string]::Format("https://{0}/api/asset/search", $ApiHost);

    $LocationData = $Location.Split("/")
    $EndLocation = $LocationData[-1]
    $LocationPath = $LocationData[0..($LocationData.Length - 2)]
    $LocationPathTabbed = $LocationPath -Join "`t"

    $Headers = @{
        "method"          = "POST";
        "Content-Type"    = "application/json";
        "Authorization"   = "Bearer $AccessToken";
        "scheme"          = "https";
        "path"            = "/api/asset/search";
        "pragma"          = "no-cache";
        "cache-control"   = "no-cache";
        "accept"          = "application/json, text/plain, */*";
        "origin"          = "$ApiHost";
        "sec-fetch-site"  = "same-origin";
        "sec-fetch-mode"  = "cors";
        "sec-fetch-dest"  = "empty";
        "accept-encoding" = "gzip, deflate, br";
        "accept-language" = "en-US,en;q=0.9";
    };

    $SearchPayload = @{
        "from"                    = "0";
        "size"                    = "10";
        "selectedFields"          = @("DisplayName");
        "searchComplexDataFields" = @();
        "query"                   = @{
            "bool" = @{
                "filter"               = @{
                    "bool" = @{
                        "must" = @(
                            @{
                                "match" = @{
                                    "assetType" = "$Type";
                                };
                            },
                            @{
                                "wildcard" = @{
                                    "tabDelimitedPath" = "$LocationPathTabbed*";
                                };
                            }
                        );
                    };
                };
                "should"               = @(
                    @{
                        "query_string" = @{
                            "query"  = "`"$EndLocation`"";
                            "fields" = @(
                                "displayNameLowerCase^5";
                                "*";
                            );
                        };
                    }
                );
                "minimum_should_match" = 1;
            };
        };
    };

    $Response = Invoke-WebRequest -Uri $SearchUri -Method "POST" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($SearchPayload | ConvertTo-Json -Depth 9) |
    ConvertFrom-Json |
    Select-Object -Property data;

    $AssetData = $Response.data

    if ($Response.data.length -gt 1) {
        $AssetData = $Response.data | Where-Object { $_.displayName -eq $RackName }
    }

    $Id = $AssetData.id;

    return $Id;
}

# Add Asset
function Add-Asset {
    param (
        $AssetObject,
        $ApiHost
    )

    $AddAssetUrl = [string]::Format("https://{0}/api/asset/assets", $ApiHost);

    $Headers = @{
        "method"          = "POST";
        "Content-Type"    = "application/json";
        "Authorization"   = "Bearer $AccessToken";
        "scheme"          = "https";
        "path"            = "/api/asset/search";
        "pragma"          = "no-cache";
        "cache-control"   = "no-cache";
        "accept"          = "application/json, text/plain, */*";
        "origin"          = "$ApiHost";
        "sec-fetch-site"  = "same-origin";
        "sec-fetch-mode"  = "cors";
        "sec-fetch-dest"  = "empty";
        "accept-encoding" = "gzip, deflate, br";
        "accept-language" = "en-US,en;q=0.9";
    };

    Invoke-WebRequest -Uri $AddAssetUrl -Method "POST" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($AssetObject | ConvertTo-Json) |
    ConvertFrom-Json 
}

# Get a list of assets by type using advanced search API
function Get-AssetsByType {
    param (
        $AccessToken,
        $ApiHost,
        $Type
    )

    $SearchUri = [string]::Format("https://{0}/api/asset/search", $ApiHost);

    $Headers = @{
        "method"          = "POST";
        "Content-Type"    = "application/json";
        "Authorization"   = "Bearer $AccessToken";
        "scheme"          = "https";
        "path"            = "/api/asset/search";
        "pragma"          = "no-cache";
        "cache-control"   = "no-cache";
        "accept"          = "application/json, text/plain, */*";
        "origin"          = "$ApiHost";
        "sec-fetch-site"  = "same-origin";
        "sec-fetch-mode"  = "cors";
        "sec-fetch-dest"  = "empty";
        "accept-encoding" = "gzip, deflate, br";
        "accept-language" = "en-US,en;q=0.9";
    };

    $SearchPayload = @{
        "from"                    = "0";
        "size"                    = "1000";
        "selectedFields"          = @("DisplayName");
        "searchComplexDataFields" = @();
        "query"                   = @{
            "bool" = @{
                "filter" = @{
                    "bool" = @{
                        "must" = @(
                            @{
                                "match" = @{
                                    "assetType" = "$Type";
                                };
                            },
                            @{
                                "wildcard" = @{
                                    "tabDelimitedPath" = "All`t*";
                                };
                            }
                        );
                    };
                };
            };
        };
    };

    $Response = Invoke-WebRequest -Uri $SearchUri -Method "POST" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($SearchPayload | ConvertTo-Json -Depth 9) |
    ConvertFrom-Json |
    Select-Object -Property data;

    $AssetData = $Response.data

    return $AssetData;
}

# Get Asset Discovered DNS name
function Get-DiscoveredDnsName {
    param (
        $AccessToken,
        $ApiHost,
        $AssetId
    )

    $SearchUri = [string]::Format("https://{0}/api/asset/assetProperties/{1}", $ApiHost, $AssetId);

    $Headers = @{
        "Authorization" = "Bearer $AccessToken";
        "accept"        = "application/json, text/plain, */*";
    };

    $Response = Invoke-WebRequest -Uri $SearchUri -Method "GET" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($SearchPayload | ConvertTo-Json -Depth 9) |
    ConvertFrom-Json |
    Where-Object -FilterScript { $_.type -eq 'hostName' -and $_.dataSource -eq 'dns' };

    return $Response;
}

# Get Asset Discovered OS
function Get-DiscoveredOs {
    param (
        $AccessToken,
        $ApiHost,
        $AssetId
    )

    $SearchUri = [string]::Format("https://{0}/api/asset/componentAssets/{1}/virtualComponents?includeAssetTypes=operatingSystem", $ApiHost, $AssetId);

    $Headers = @{
        "Authorization" = "Bearer $AccessToken";
        "accept"        = "application/json, text/plain, */*";
    };

    $Response = Invoke-WebRequest -Uri $SearchUri -Method "GET" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($SearchPayload | ConvertTo-Json -Depth 9) |
    ConvertFrom-Json |
    Where-Object -FilterScript { $_.assetType -eq 'operatingSystem' };

    return $Response;
}

# Get Power Associations
function Get-PowerAssociations {
    param (
        $AccessToken,
        $ApiHost,
        $AssetId
    )

    $SearchUri = [string]::Format("https://{0}/api/asset/powerSourceAssociations?consumingDestinationAssetId={1}", $ApiHost, $AssetId);

    $Headers = @{
        "Authorization" = "Bearer $AccessToken";
        "accept"        = "application/json, text/plain, */*";
    };

    $Response = Invoke-WebRequest -Uri $SearchUri -Method "GET" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($SearchPayload | ConvertTo-Json -Depth 9) |
    ConvertFrom-Json;

    $PowerAssociations = @{
        "by_id"   = @();
        "by_name" = @();
    };

    if ( $Response.length -ne 0 ) {
        foreach ( $powerAssociation in $Response ) {
            $PowerAssociations.by_id += $powerAssociation.providingSourceDeviceAssetId;
            $PowerAssociations.by_name += $powerAssociation.providingSourceDeviceAssetDisplayName;
        }
    } 

    return $PowerAssociations;
}

# Get Rack and Room information for an asset
function Get-RackAndRoomInformation {
    param (
        $AccessToken,
        $ApiHost,
        $AssetId
    )

    $SearchUri = [string]::Format("https://{0}/api/asset/assets/{1}", $ApiHost, $AssetId);

    $Headers = @{
        "Authorization" = "Bearer $AccessToken";
        "accept"        = "application/json, text/plain, */*";
    };

    $Response = Invoke-WebRequest -Uri $SearchUri -Method "GET" `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body ($SearchPayload | ConvertTo-Json -Depth 9) |
    ConvertFrom-Json;

    $RackAndRoomInfomation = @{
        "rack_name" = "";
        "rack_id"   = "";
        "room_name" = "";
        "room_id"   = "";
    };

    if ( $Response.assetTypeId -eq "rack" ) {
        $RackAndRoomInfomation.rack_name = $Response.name;
        $RackAndRoomInfomation.rack_id = $Response.id;
        $RackAndRoomInfomation.room_name = $Response.parentName;
        $RackAndRoomInfomation.room_id = $Response.parentId;
    }
    elseif ( $Response.assetTypeId -eq "location" ) {
        $RackAndRoomInfomation.room_name = $Response.name;
        $RackAndRoomInfomation.room_id = $Response.id;
    }

    return $RackAndRoomInfomation;
}

