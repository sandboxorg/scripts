# There are 3 cases to consider.
# Provision a new VM using thin provisioning.
Get-VMHost | Select-Object -first 1 |
	New-VM -Name "Thin VM" -DiskStorageFormat Thin

# Add a new disk to a VM using thin provisioning.
Get-VM "Test VM" | New-HardDisk -ThinProvisioned -CapacityKB 1kb

# Convert an existing disk to thin.
# BUG: 4.0 U1 requires the VM to be powered off to do this. Fixed in 4.1.
# The process is to convert the disk to thin as it is Storage VMotioned,
# Then svmotion back to its original location.
$oldDatastore = Get-VM "Test VM" | Get-Datastore
Get-VM "Test VM" | Get-HardDisk | Select-Object -First 1 | Set-HardDisk -StorageFormat Thin -Datastore openfiler01_share01
Get-VM "Test VM" | Get-HardDisk | Select-Object -First 1 | Set-HardDisk -Datastore $oldDatastore