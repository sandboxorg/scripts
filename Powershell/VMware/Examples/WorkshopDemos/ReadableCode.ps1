# DO 1: Make maximum use of OBN (object-by-name)
Get-VM -Datastore Storage1					# Do
# DON'T 1: Don't use Get-* cmdlets when OBN will do.
Get-VM -Datastore (Get-Datastore Storage1)	# Don't

# Do: Favor the use of the pipeline for navigating the inventory tree.

# Do:
Get-Datastore FC_LUN01_PMG01 | Get-VM
# Also ok in this case but not ideal:
Get-VM -Datastore FC_LUN01_PMG01

# Do:
Get-VMHost esx01a.vmworld.com | Get-VM
# Bad idea:
Get-VM -Location esx01a.vmworld.com

# Do:
Get-Datacenter "Data Center 01" | Get-Cluster "Cluster 01" |
	Get-VMHost esx01a.vmworld.com | Get-VM
# Really bad idea:
Get-VM -Location (Get-Datacenter "Data Center 01" |
	Get-Cluster "Cluster 01" | Get-VMHost esx01a.vmworld.com)

# Use backticks to continue lines.
# Do
New-VM -Name "My First VM" -Datastore FC_LUN01_PMG01 `
	-VMHost esx01a.vmworld.com -NetworkName DHCP-VM02 `
	-MemoryMB 1024 -GuestId rhel5Guest
# Don't!
New-VM -Name "My First VM" -Datastore FC_LUN01_PMG01 -VMHost esx01a.vmworld.com -NetworkName DHCP-VM02 -MemoryMB 1024 -GuestId rhel5Guest
# Note you can put a linefeed after a pipe.