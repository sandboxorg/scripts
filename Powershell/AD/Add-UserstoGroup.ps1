#####################################################################################################
# Change Record
# ====================
# v1.0 - 07/11/2012 - Initial Version
#####################################################################################################

<#
.SYNOPSIS
Add-UserstoGroup imports users from csv file and adds them to the specified group
.DESCRIPTION
Add-UserstoGroup imports users from csv file and adds them to the specified group.  It searches AD based on firstname and lastname.
.PARAMETER userlist
CSV file to import users from
.PARAMETER group
Group to add users to
.EXAMPLE
Add-UserstoGroup "C:\Users.csv" "Laptop_Users"
#>

param ($userlist,$group)

Import-Module ActiveDirectory

$importfile = Import-Csv $userlist

Foreach ($item in $importfile) {
    $givenName = $item.givenName
    $surname = $item.surname
    
    $samAccountName = Get-ADUser -Filter * | Where {$_.givenName -match $givenName -and $_.surname -match $surname} | Select -expand samAccountName
    Add-ADGroupMember -Identity $group -Members $samAccountName
}
