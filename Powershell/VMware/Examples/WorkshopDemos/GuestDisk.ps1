# See which VMs are running VMware tools.
Get-VM | Get-VMGuest

# See what attributes are available with Format-List.
Get-VM | Get-VMGuest | Format-List *

# Note the entry for disks.
# Let's find out more about the disks.
Get-VM | Get-VMGuest | Where { $_.Disks } | Select -ExpandProperty Disks

# That's great but what VMs did those disks come from?
# Select can also take arguments in addition to expanded properties.
Get-VM | Get-VMGuest | Where { $_.Disks } | Select -ExpandProperty Disks VMName

# Sort by minimum free space.
Get-VM | Get-VMGuest | Where { $_.Disks } | Select -ExpandProperty Disks VMName | Sort FreeSpace

# Determine free space percentage.
Get-VM | Get-VMGuest | Where { $_.Disks } | Select -ExpandProperty Disks VMName |
	Select VmName, Capacity, FreeSpace, @{ N="PercentFree"; E={ "{0:f2}" -f ($_.FreeSpace / $_.Capacity * 100)  }} |
	Sort PercentFree
