#####################################################################################################
# Changelog
# ====================
# v1.0 - 24/05/2013 - Initial Version
# v1.1 - 06/06/2013 - Added check for E-mail address - alterntive specific to Aircelle
# v1.2 - 15/08/2013 - Added different text into freeform field - E-mail address, Username, Displayname
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

$logfile = "C:\Users\n302167\Dropbox\Scripts\Powershell\AD\Get-ExpiringAccounts_" + (Get-Date -format yyMMdd) +".log"
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
		If ((Get-ADUser $user -Properties mail).mail -eq $null){
			$mailaddress = "IS.Helpdesk@aircelle.com"
			}
		Else {
			$mailaddress = Get-ADUser $user -Properties mail | Select -ExpandProperty mail
			}
		$expirydate = Get-ADUser $user -Properties AccountExpirationDate | Select -ExpandProperty AccountExpirationDate
		$displayname = Get-ADUser $user -Properties Name | select -expand Name
		$samaccountname = Get-ADUser $user -Properties SamAccountName | Select -expand SamAccountName
		$a = '"Username - {0}, Account Expiry - {1}, Name - {2}"' -f $samaccountname, $expirydate, $displayname
		$a
		#d:\php\aircelle\account_renewal.bat $mailaddress $a
	}
}

"" | Out-File $logfile -Append
"Get-ExpiringAccounts completed at: " + (Get-Date) | Out-File $logfile -Append
"" | Out-File $logfile -Append
"######################################################################" | Out-File $logfile -Append
"" | Out-File $logfile -Append