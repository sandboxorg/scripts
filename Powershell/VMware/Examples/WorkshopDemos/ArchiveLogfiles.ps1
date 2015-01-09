function Extract-TkeDatastorePathElements {
	param(
		[string]$path
	)

	# Extract the subpath.
	if ($path -match "\[([^\]]+)\] (.+)") {
		$datastore = $matches[1]
		$dsPath = $matches[2]
		$ret = new-object psobject
		$ret | add-member -type NoteProperty -name "Datastore" -value $datastore
		$ret | add-member -type NoteProperty -name "Path" -value $dsPath

		return $ret
	} else {
		return $null
	}
}

# List all VMs.
Get-VM

# Determine a VM's datastore location.
# This stuff is all located in the VM view's config.files.
Get-VM | Select-Object -First 1 | Set-Variable vm
$vm | Get-View | Set-Variable vmView
$vmView.config.files

# Now we can use the datastore provider to look at this VM and copy its files.
dir vmstore:

# A quirk about the data provider, you have to know the VM's datacenter.
$vm | Get-Datacenter | Set-Variable dc

# Look inside the datacenter.
dir vmstore:\$dc

# Another difficulty: you have to parse the log directory location.
# Extract-TkeDatastorePathElements will do that.
$elements = Extract-TkeDatastorePathElements $vmview.config.files.LogDirectory
$datastore = $elements.Datastore
$path = $elements.Path
dir vmstore:\$dc\$datastore\$path
dir vmstore:\$dc\$datastore\$path\*.log

# Warning: bugs in 4.0 U1 make the datastore provider amazingly slow.
# It is much faster in the upcoming 4.1. I promise.

# Copy the log files locally.
Mkdir c:\Temp
Mkdir c:\Temp\logs
dir vmstore:\$dc\$datastore\$path\*.log | Copy-DatastoreItem -Destination c:\Temp\logs
dir

# Today this is not too quick but you can't beat the simplicity and it will
# get faster in coming releases.