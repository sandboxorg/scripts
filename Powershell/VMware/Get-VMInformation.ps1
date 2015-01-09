<#
.SYNOPSIS
Get-VIInventory retrieves information about each Virtual Machine within the environment
.DESCRIPTION
Get-VIInventory connects to the specified vCenter and collects information about each Virtual Machine's hardware.  This is then output to a CSV file.
.PARAMETER vCenter
FQDN of the vCenter you want to collect information from
.EXAMPLE
Get-VMInformation -vCenter "vcenter01.domain.local" 
#>
param (
	$vCenter
)

Add-PSSnapin vmware.vim.automation

Connect-VIServer $vCenter

Get-VM | Select @{N="Hostname";E={($_ | Get-View).Guest.Hostname}},
	@{N="Description";E={$_.Notes}},
	@{N="Site";E={$_.Parent}}