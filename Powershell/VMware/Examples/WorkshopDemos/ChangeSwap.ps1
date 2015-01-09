# Change the swap file location.
Set-VMHost -VMSwapfilePolicy InHostDatastore -VMSwapfileDatastore FC_LUN02_PMG01

# You can also do this on a cluster level.
Get-Cluster | Set-Cluster -VMSwapfilePolicy InHostDatastore

# You can also control individual VMs.
$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
$spec.files = New-Object VMware.Vim.VirtualMachineFileInfo

# Note the format here!
$spec.files.snapshotDirectory = "[FC_LUN02_PMG01] NonexistantDirectory"
$vmView = Get-VM "Test VM" | Get-View
$vmView.config.files
$vmView.ReconfigVM($spec)

# Refresh the view after reconfiguration.
$vmView = Get-VM "Test VM" | Get-View
$vmView.config.files

# Now we can't power the VM on!
dir vmstore:\ha-datacenter\datastore2
Get-VM "Test VM" | Start-VM

# Creating the directory solves the problem.
mkdir vmstore:\ha-datacenter\FC_LUN02_PMG01\NonexistantDirectory
Get-VM "Test VM" | Start-VM
dir vmstore:\ha-datacenter\FC_LUN02_PMG01\NonexistantDirectory
