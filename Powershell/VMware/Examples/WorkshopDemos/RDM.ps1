# Raw devices can be added based on existing LUNs.
Get-VMHost 10.91.246.2 | Get-ScsiLun

# We'll take a LUN off my Openfiler.
$targetLun = Get-VMHost 10.91.246.2 | Get-ScsiLun | Where { $_.Vendor -eq "OPNFILER" } | Select -Last 1

# Create a VM where we'll add the LUN.
Get-VMHost 10.91.246.2 | New-VM -Name Raw -DiskMB 1

# Add the RDM using New-HardDisk and the targetLun variable.
Get-VM Raw | New-HardDisk -DiskType RawPhysical -DeviceName $targetLun.ConsoleDeviceName

# Note: you can't use RDM if your VM is on NFS storage!