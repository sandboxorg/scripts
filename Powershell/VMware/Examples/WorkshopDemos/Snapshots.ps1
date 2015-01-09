# PowerCLI makes it easy to deal with snapshots.
Get-VM | Get-Snapshot

# One of the most important attributes is the age of the snapshot.
Get-VM | Get-Snapshot | Select Name, VM, Created

# You can create snapshots in a very targeted way, because we rely on Get-VM
Get-Cluster "Cluster 01" | Get-VM
Get-VMHost esx01a.vmworld.com | Get-VM

# Snapshot every VM on host esx01a.vmworld.com
Get-VMHost esx01a.vmworld.com | Get-VM | New-Snapshot -Name "Snap1"
Get-Cluster "Cluster 01" | Get-VM | New-Snapshot -Name "Snap2"

# You can search for snapshots based on their age.
# Identify any snapshot older than a day.
Get-Snapshot | Where { $_.Created -lt (Get-Date).addDays(-1) }

# Remove any snapshot older than a day.
Get-Snapshot | Where { $_.Created -lt (Get-Date).addDays(-1) } | Remove-Snapshot

# Remove *ALL* snapshots.
Get-Snapshot | Remove-Snapshot