# Enable Software iSCSI across all hosts.
Get-VMHost | Get-VMHostStorage | Set-VMHostStorage -SoftwareIScsiEnabled:$true

# Add an iSCSI target at 10.91.246.21 to these hosts.
# This assumes you are using dynamic discovery.
Get-VMHost | Foreach {
	$_ | Get-VMHostHba -Type iSCSI | New-IScsiHbaTarget -Address 10.91.246.21
}

# Rescan storage.
Get-VMHost | Get-VMHostStorage -RescanAllHba -RescanVmfs

# At this point you need to identify a LUN to format as VMFS.
# You will need to modify this code.
# The sample below selects the first LUN presented by an Openfiler.
$targetLun = Get-VMHost | Select -First 1 | Get-ScsiLun | Where { $_.Vendor -eq "OPNFILER" } | Select -First 1

# Pass the LUN's canonical name to New-Datastore.
Get-VMHost | Select -first 1 | New-Datastore -Vmfs -Path $targetLun.CanonicalName -Name iScsi1

# At this point *ALL* of your hosts will see the iScsi1 datastore.
Get-Datastore