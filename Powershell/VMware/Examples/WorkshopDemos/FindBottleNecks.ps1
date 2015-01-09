# Some interesting stats to look for:
# Find CPU wait time (helps identify contention).
Get-VM | Select Name, @{ N="Summation"; E={($_ | Get-Stat -stat cpu.ready.summation -maxsamples 1 -Realtime | select -first 1).Value} } | Sort -property Summation -Descending

# Identify high disk use VMs on the same LUN.

# First let's add LUN as an attribute for VM.
# Note: Future feature! Sorry!
New-VIObjectExtensionProperty -ObjectType VirtualMachine -name LUN `
    -Value { ($args[0] | Get-Datastore | Select -Last 1 | Get-ScsiLun | Select -First 1).CanonicalName } -Force

# Watch this in action.
Get-VM | Select Name, LUN

# We can group these with PowerShell.
$vmGroups = Get-VM | Group -Property LUN

# Now we see how many VMs per LUN.
$vmGroups

# And we can count up total disk usage per LUN.
for ($i = 0; $i -lt $vmGroups.count; $i++) {
	$totalUsage = 0
	foreach ($vm in $vmGroups[$i].Group) {
		$totalUsage += ($vm | get-stat -stat disk.usage.average -maxsamples 1 -realtime -erroraction SilentlyContinue).value
	}
	$obj = New-Object PSObject
	$obj | Add-Member -Name LUN -Value $vmGroups[$i].Name -MemberType NoteProperty
	$obj | Add-Member -Name TotalUsage -Value $totalUsage -MemberType NoteProperty
	Write-Output $obj
}
