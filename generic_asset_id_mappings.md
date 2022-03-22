# Asset Type to Id mapping

If you are interacting with a API, it is sometimes useful to have the numeric 
ID mappings for the common asset types supported in hyperview. Almost everything 
else can be extracted from the API or the application GUI.

The AssetTypeEnum is documented in the Swagger Docs but it is easier to look 
at this information in a table.

Please note that these are fairly static but there is no guarantee that they 
will not change in the future. 

| Id    |Type                   |
|-------|-----------------------|
| 0     |"unknown"              |
| 1     |"location"             |
| 2     |"server"               |
| 3     |"rack"                 |
| 4     |"rackPdu"              |
| 5     |"bladeEnclosure"       |
| 6     |"ups"                  |
| 7     |"networkStorage"       |
| 8     |"transferSwitch"       |
| 9     |"bladeServer"          |
| 10    |"smallUps"             |
| 11    |"powerMeter"           |
| 12    |"camera"               |
| 13    |"busway"               |
| 14    |"chiller"              |
| 15    |"crac"                 |
| 16    |"crah"                 |
| 17    |"environmental"        |
| 18    |"fireControlPanel"     |
| 19    |"generator"            |
| 20    |"inRowCooling"         |
| 21    |"kvmSwitch"            |
| 22    |"bladeStorage"         |
| 23    |"monitor"              |
| 24    |"networkDevice"        |
| 25    |"otherDevice"          |
| 26    |"patchPanel"           |
| 27    |"pduAndRpp"            |
| 28    |"bladeNetwork"         |
| 29    |"utilityBreaker"       |
| 30    |"virtualServer"        |
| 34    |"processor"            |
| 35    |"memory"               |
| 37    |"pduRppBreaker"        |
| 39    |"nic"                  |
| 40    |"operatingSystem"      |
| 41    |"powerSupply"          |
| 45    |"physicalStorage"      |
| 46    |"ipAddress"            |
| 47    |"application"          |
| 48    |"outlet"               |
| 49    |"rackShelf"            |
| 50    |"cable"                |
| 51    |"transceiver"          |
| 52    |"buswayTapOff"         |
| 53    |"nodeServer"           |
| 54    |"lineCardSwitchModule" |


