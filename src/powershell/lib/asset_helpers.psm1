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
