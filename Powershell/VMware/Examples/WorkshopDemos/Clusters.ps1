# Clusters are created beneath datacenters.
Get-Datacenter

# Clusters are created beneath datacenters.
Get-Datacenter | New-Cluster -Name "New Cluster"

# Take a look at our new cluster.
Get-Cluster | Format-List *

# Move some hosts in.
Get-VMHost | Move-VMHost -Destination "New Cluster"

# Enable DRS and set it to fully automated.
Get-Cluster "New Cluster" | Set-Cluster -DrsEnabled:$true -DrsAutomationLevel FullyAutomated

# Enable HA as well.
Get-Cluster "New Cluster" | Set-Cluster -HAEnabled:$true -HAAdmissionControlEnabled:$true

# This makes it easy to ensure your clusters all have consistent and desired configuration.
Get-Datacenter | New-Cluster -Name "New Cluster 2"
Get-Cluster "New Cluster 2" | Set-Cluster -DrsAutomationLevel Manual
Get-Cluster | Select Name, DrsAutomationLevel

# DRS rules are also easy to create and audit.
New-DrsRule -Cluster "New Cluster" -Name affinityRule1 `
	-KeepTogether $true -VM "Test VM 1","Test VM 2"
New-DrsRule -Cluster "New Cluster" -Name antiAffinityRule1 `
	-KeepTogether $false -VM "Test VM 1","Test VM 3"
Get-Cluster "New Cluster" | Get-DrsRule | Select *

# Delete the DRS rules.
Get-DrsRule | Remove-DrsRule