<# 
 
.SYNOPSIS 
 
Retrieves all IIS logs and deletes any older than x days
 
 
 
.DESCRIPTION 
 
The Get-IISLogs script gets the IIS log file location & recursively searches for all log files older than x days.  These files are then deleted

 
.EXAMPLE 
 
Search & Destroy all log files older than 6 months

Get-IISLogs -Age 180 -Delete $true
 
 
.EXAMPLE 
 
Search & List all log files older than 12 months

Get-IISLogs -Age 365 
 
.NOTES 
 
This is dependant on the WebAdministration module. 
 
#> 
 
 
Param 
( 
    [int]$Age = "", 
    [bool]$Delete = $false
) 
 
Import-Module WebAdministration

$LogsLocation = (Get-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -name logfile.directory).Value

$LogsAge = (Get-Date).AddDays(-$Age)

If ($Delete)
{
    Get-Childitem -Path $LogsLocation -Recurse -Include *.log | Where-Object {$_.LastWriteTime -lt $LogsAge} | foreach ($_) {Remove-Item $_.FullName}
}
Else
{
    Get-Childitem -Path $LogsLocation -Recurse -Include *.log | Where-Object {$_.LastWriteTime -lt $LogsAge}
}