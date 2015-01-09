# Cache objects client-side when you will be using them more than once.
# Don't
Measure-Command {
foreach ($datastore in (Get-Datastore)) {
	$dsvms = Get-VM -Datastore $datastore
	$hvms = Get-VMHost esx01a.vmworld.com | Get-VM
	foreach ($vm1 in $dsvms) {
		foreach ($vm2 in $hvms) {
			if ($vm1.Name -eq $vm2.Name) {
				Write-Host "Host has VMs on", $datastore.Name
			}
		}
	}
}
}

# Do.
Measure-Command {
$hvms = Get-VMHost esx01a.vmworld.com | Get-VM
foreach ($datastore in (Get-Datastore)) {
	$dsvms = Get-VM -Datastore $datastore
	foreach ($vm1 in $dsvms) {
		foreach ($vm2 in $hvms) {
			if ($vm1.Name -eq $vm2.Name) {
				Write-Host "Host has VMs on", $datastore.Name
			}
		}
	}
}
}

# Note that Object-by-name creates a performance penalty.
# If you have the object, use it rather than the name.
Measure-Command {
Foreach ($vm in (Get-VM)) {
	# Do it this way!
	Get-Datastore -VM $vm
}
}

Measure-Command {
Foreach ($vm in (Get-VM)) {
	# Don't do it this way!!!
	Get-Datastore -VM $vm.Name
}
}

# When you use Get-View, use -Property to speed it up.
Measure-command { Get-View -ViewType VirtualMachine }
Measure-command { Get-View -ViewType VirtualMachine -Property Name }

# -Property can be an array.
Measure-command { Get-View -ViewType VirtualMachine -Property Name,OverallStatus }