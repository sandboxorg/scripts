#####################################################################################################
# Changelog
# ====================
# v1.0 - 29/08/2013 - Initial Version
#####################################################################################################

<#
.SYNOPSIS
New-HDrive creates new email archive folder on BLSRARC01
.DESCRIPTION
New-HDrive creates new email archive folder on BLSRARC01
.PARAMETER user
Username that the folder is for
.EXAMPLE
New-HDrive n312345
#>

param (
    $user
)

$newfolder = "\\BLSRARC01\Archive\$user"

New-Item $newfolder -ItemType Directory

$acl = Get-ACL $newfolder
$principal = "AIRCELLECORP\$user"
$inheritance = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
$propogation = [System.Security.AccessControl.PropagationFlags]"None"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($principal,"FullControl",$inheritance,$propogation,"Allow")
$acl.SetAccessRule($rule)

Set-ACL $newfolder $acl