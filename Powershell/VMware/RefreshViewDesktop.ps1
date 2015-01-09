#####################################################################################################
# Scheduled refresh of the BMS Risklink client desktops.  No error checking as yet.
#
#
# Change Record
# ====================
# v1.0 - 01/12/2011 - Initial Version
#
#####################################################################################################

# Add VMware View PS Snapin
"D:\Program Files\VMware\VMware View\Server\extras\PowerShell\add-snapin.ps1"

$sPoolID = 'BMS-RMS-Clients'

Get-Pool -pool_id $sPoolID | Get-DesktopVM | Send-LinkedCloneRefresh -schedule (get-Date) -forceLogoff $true