#####################################################################################################
# Change Record
# ====================
# v1.0 - 14/02/2013 - Initial Version
#####################################################################################################

<#
.SYNOPSIS
Set-UserAttribute imports users from csv file and updates attributes defined below
.DESCRIPTION
Set-UserAttribute imports users from csv file and updates custom attributes using the "Instance" method
.PARAMETER userlist
CSV file to import users from
.EXAMPLE
Set-UserAttribute "C:\Users.csv"
#>

param ($userlist)

Import-Module ActiveDirectory

$importfile = Import-Csv $userlist

Foreach ($item in $importfile) {

	$samAccountName = $item.samAccountName
    $telephoneNumber = $item.telephoneNumber
    $ipPhone = $item.ipPhone
    
	$user = Get-ADUser $samAccountName -Properties telephoneNumber,ipPhone
	$user.telephoneNumber = $telephoneNumber
	$user.ipPhone = $ipPhone
	Set-ADUser -Instance $user
}
