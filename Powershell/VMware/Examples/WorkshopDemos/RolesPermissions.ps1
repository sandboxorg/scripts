# The basics.
Get-VIRole
Get-VIPermission

# Many permissions are inherited, you can pipe any inventory object into Get-VIPermission.
Get-VM vCenter | Get-VIPermission
Get-VMHost esx01a.vmworld.com | Get-VIPermission

# See what permissions are by expanding the privilegelist.
get-virole DatastoreConsumer | select -expand privilegelist
get-virole NotQuiteAdministrator | select -expand privilegelist

# You can clone and update roles.
New-VIRole -name DatastoreConsumer2 -Privilege (Get-VIRole DatastoreConsumer | Get-VIPrivilege)
Get-VIRole DatastoreConsumer2 | Set-VIRole -AddPrivilege "Create snapshot"
Get-VIRole DatastoreConsumer2 | select -expand privilegelist
Get-VIRole DatastoreConsumer2 | Remove-VIRole
