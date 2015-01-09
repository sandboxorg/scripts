# Tools version on VMs.
New-VIObjectExtensionProperty -ObjectType VirtualMachine -name ToolsVersion `
    -ValueFromExtensionProperty 'config.tools.ToolsVersion' -Force
Get-VM | Select Name, ToolsVersion
Get-VM | Where { $_.ToolsVersion -lt 100000 } | Update-Tools

# Number of VMs per host.
New-VIObjectExtensionProperty -ObjectType VMHost -name NumberOfVMs `
    -Value { ($args[0] | Get-VM | Measure-Object).Count } -Force
Get-VMHost | Select Name, NumberOfVMs

# Host average CPU usage last 24 hours.
New-VIObjectExtensionProperty -ObjectType VMHost -name AvgCPUUsage24Hr `
    -Value {
	"{0:f2}" -f
	($args[0] |
		Get-Stat -stat cpu.usage.average |
		Where { $_.Instance -eq "" } |
		Measure-Object -Property Value -Average
	).Average } -Force
Get-VMHost | Select Name, AvgCPUUsage24Hr | Sort -Property AvgCPUUsage24Hr -descending

# This makes it much less confusing to do things like this:
Get-VM | Select Name, @{ N="Average"; E={($_ | Get-Stat -stat cpu.usage.average -maxsamples 1 -Realtime).Value} } | Sort -property Average -Descending

New-VIObjectExtensionProperty -ObjectType VirtualMachine -name AverageCPU `
    -Value { ($args[0] | Get-Stat -stat cpu.usage.average -MaxSamples 1 -Realtime).Value } -Force

# Write a report:
Get-VM | Select Name, AverageCPU

# A sorted report.
Get-VM | Select Name, AverageCPU | Sort -Property AverageCPU -descending

# Or, use this to partition my VMs.
Get-VM | Where { $_.AverageCPU -gt 50 }

# Of course we can select that property too while we're at it.
Get-VM | Where { $_.AverageCPU -gt 50 } | Select Name, AverageCPU
