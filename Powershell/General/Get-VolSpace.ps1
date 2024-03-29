#####################################################################################################
# Change Record
# ====================
# v1.0 - 01/11/2012 - Initial Version
#####################################################################################################

<#
.SYNOPSIS
Get-VolSpace queries each server in the servers.txt file for it's disk space.
.DESCRIPTION
Get-VolSpace queries each server in the servers.txt file for it's disk space (total & free).  This is then output to a log file.
.PARAMETER inputFile
Text file containing server's hostnames
.PARAMETER outputFile
Text file to output results to
.EXAMPLE
Get-VolSpace servers.txt volspace.csv
#>

Get-WmiObject Win32_LogicalDisk -ComputerName server-email -Filter "DriveType = 3" | Select @{N="Hostname";E={$_.SystemName}}`
		,@{N="Drive Letter";E={$_.DeviceID}}`
		,@{N="Name";E={$_.VolumeName}}`
		,@{N="Free(GB)";E={($_.FreeSpace/1GB)}}`
		,@{N="Size(GB)";E={($_.Size/1GB)}}