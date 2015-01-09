# Version 1 locked.
# Round tripping with VM Annotations.
New-CustomAttribute -Name Owner -TargetType VirtualMachine

# Populate one of the attributes.
Get-VM "XP 1" | Set-Annotation -CustomAttribute Owner -Value "Carter Shanklin"

# Prepare a CSV report of VMs and their owners.
Get-VM | foreach { $vmName = $_.Name; $_ | Get-Annotation | Select *, { $vmName } } | Export-Csv -NoTypeInformation c:\report.csv

# Open the report.
Invoke-Item c:\report.csv

# Read the new data in and populate it to vCenter.
Foreach ($e in (Import-Csv c:\report.csv)) {
	if ($e.Value) {
		Get-VM -Id $e.AnnotatedEntityId | Set-Annotation -CustomAttribute $e.Name -Value $e.Value
	}
}

# Generate a new report (to the console this time).
Get-VM | foreach { $vmName = $_.Name; $_ | Get-Annotation | Select *, { $vmName } }
