#####################################################################################################
# Changelog
# ====================
# v1.0 - 24/05/2013 - Initial Version
#####################################################################################################

<#
.SYNOPSIS
Get-ExpiringAccounts searches AD for all locked accounts within the search scope specified
.DESCRIPTION
Get-ExpiringAccounts searches AD for all locked accounts within the search scope specified.  Output to Log file.
.PARAMETER scope
Scope that the search is run from
.PARAMETER timespan
Time in the future that the account will expire
.EXAMPLE
Get-ExpiringAccounts "cn=users,dc=domain,dc=corp" 60
#>

param (
    $scope,
	$timespan
)

$timespan = (Get-Date).addDays($timespan)

Import-Module ActiveDirectory

$logfile = "D:\Scripts\ActiveDirectory\Get-ExpiringAccounts_" + (Get-Date -format yyMMdd) +".log"
"######################################################################" | Out-File $logfile -Append
"" | Out-File $logfile -Append
"Get-ExpiringAccounts starting at: " + (Get-Date) | Out-File $logfile -Append
"" | Out-File $logfile -Append

If ($scope -eq $null){
    "Script failed to run, parameter not accepted" | Out-File $logfile -Append
}

$expiring = Search-ADAccount -AccountExpiring -DateTime $timespan -searchbase $scope

If($expiring -eq $null){
    "" | Out-File $logfile -Append
    "----------------------------------------------------------------------" | Out-File $logfile -Append
    "" | Out-File $logfile -Append
    "No accounts are currently due to expire in the next $timespan days" | Out-File $logfile -Append
    "" | Out-File $logfile -Append
    "----------------------------------------------------------------------" | Out-File $logfile -Append
    "" | Out-File $logfile -Append    
}
Else {
    "Total number of expiring accounts: " + ($expiring.count) | Out-File $logfile -Append
    "Expiring accounts: " | Out-File $logfile -Append
    "" | Out-File $logfile -Append
    "----------------------------------------------------------------------" | Out-File $logfile -Append
    $expiring | Select Name,@{N="Username";E={$_.SAMAccountName}} | Out-File $logfile -Append
    "----------------------------------------------------------------------" | Out-File $logfile -Append
    "" | Out-File $logfile -Append
    
	Foreach ($user in $expiring){
		$mailaddress = Get-ADUser $user -Properties mail | Select -ExpandProperty mail
		Write-Host $mailaddress
		#d:\php\aircelle\incident.bat $mailaddress
	}
}

"" | Out-File $logfile -Append
"Get-ExpiringAccounts completed at: " + (Get-Date) | Out-File $logfile -Append
"" | Out-File $logfile -Append
"######################################################################" | Out-File $logfile -Append
"" | Out-File $logfile -Append