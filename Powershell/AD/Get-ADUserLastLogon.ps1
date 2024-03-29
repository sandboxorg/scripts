<#
.SYNOPSIS
Get-ADUserLastLogon retrieves the last logon time
.DESCRIPTION
Get-ADUserLastLogon retrieves the last logon property from the specified user, ensures it is the latest time from all DCs.
.PARAMETER username
Username of the user you would like the information for
.EXAMPLE
Get-ADUserLastLogon mcleodj
#>
param (
	$username
)

Import-Module ActiveDirectory

function Get-ADUserLastLogon([string]$userName)
{
  $dcs = Get-ADDomainController -Filter {Name -like "*"}
  $time = 0
  foreach($dc in $dcs)
  { 
    $hostname = $dc.HostName
    $user = Get-ADUser $userName | Get-ADObject -Properties lastLogon 
    if($user.LastLogon -gt $time) 
    {
      $time = $user.LastLogon
    }
  }
  $dt = [DateTime]::FromFileTime($time)
  Write-Host $username "last logged on at:" $dt }

Get-ADUserLastLogon -username $username