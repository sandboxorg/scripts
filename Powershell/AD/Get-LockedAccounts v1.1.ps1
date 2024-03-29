#####################################################################################################
# Changelog
# ====================
# v1.0 - 22/10/2012 - Initial Version
# v1.1 - 21/05/2012 - Added call to external PHP script for easyVista incident logging
#####################################################################################################

<#
.SYNOPSIS
Get-LockedAccounts searches AD for all locked accounts within the search scope specified
.DESCRIPTION
Get-LockedAccounts searches AD for all locked accounts within the search scope specified.  Output to Log file.
.PARAMETER scope
Scope that the search is run from
.EXAMPLE
Get-LockedAccounts "cn=users,dc=domain,dc=corp" 
#>

param (
    $scope
)

Import-Module ActiveDirectory

$logfile = "D:\Scripts\ActiveDirectory\Get-LockedAccounts_" + (Get-Date -format yyMMdd) +".log"

"######################################################################" | Out-File $logfile -Append
"" | Out-File $logfile -Append
"Get-LockedAccounts starting at: " + (Get-Date) | Out-File $logfile -Append
"" | Out-File $logfile -Append

If ($scope -eq $null){
    "Script failed to run, parameter not accepted" | Out-File $logfile -Append
}

$locked = Search-ADAccount -lockedout -searchbase $scope

If($locked -eq $null){
    "" | Out-File $logfile -Append
    "----------------------------------------------------------------------" | Out-File $logfile -Append
    "" | Out-File $logfile -Append
    "No accounts are currently locked" | Out-File $logfile -Append
    "" | Out-File $logfile -Append
    "----------------------------------------------------------------------" | Out-File $logfile -Append
    "" | Out-File $logfile -Append    
}
Else {
    "Total number of locked accounts: " + ($locked.count) | Out-File $logfile -Append
    "Locked accounts: " | Out-File $logfile -Append
    "" | Out-File $logfile -Append
    "----------------------------------------------------------------------" | Out-File $logfile -Append
    $locked | Select Name,@{N="Username";E={$_.SAMAccountName}} | Out-File $logfile -Append
    "----------------------------------------------------------------------" | Out-File $logfile -Append
    "" | Out-File $logfile -Append
    
    $locked | Unlock-ADAccount
	
	Foreach ($user in $locked){
		$mailaddress = Get-ADUser $user -Properties mail | Select -ExpandProperty mail
		Write-Host $mailaddress
		d:\php\aircelle\incident.bat $mailaddress
	}
}

"" | Out-File $logfile -Append
"Get-LockedAccounts completed at: " + (Get-Date) | Out-File $logfile -Append
"" | Out-File $logfile -Append
"######################################################################" | Out-File $logfile -Append
"" | Out-File $logfile -Append