# Sort VMs in order of utilization over the last 5 minutes.
# Let's start by identifying what we need.
get-vm vCenter | Get-Stat -stat cpu.usage.average -maxsamples 1 -Realtime
# How can we put this into a consolidated report?
get-vm | Select Name, { ($_ | Get-Stat -stat cpu.usage.average -maxsamples 1 -Realtime).Value }
# The column name is really ugly and limits our ability to sort.
# Let's use an advanced feature of Select to fix that.
Get-VM | Select Name, @{ N="Average"; E={($_ | Get-Stat -stat cpu.usage.average -maxsamples 1 -Realtime).Value} }
# Now we can sort with ease.
Get-VM | Select Name, @{ N="Average"; E={($_ | Get-Stat -stat cpu.usage.average -maxsamples 1 -Realtime).Value} } | Sort -property Average -Descending

# Let's look at some disk utilization.
get-vm vCenter | get-stat -stat disk.usage.average
# How can we average that? Again, PowerShell helps.
get-vm vCenter | get-stat -stat disk.usage.average | measure-object -property value -Average
# Can we rank all our VMs this way? Yes!
Get-VM | Select Name, @{ N="DiskUseKbps"; E={($_ | Get-Stat -stat disk.usage.average | Measure-Object -property value -Average).Average} } | Sort -property DiskuseKbps -Descending

# We can do the same with hosts. But there is something to be careful about.
Get-VMHost | Get-Stat -Start cpu.usage.average -MaxSamples 1 -Realtime
# We can filter to only get the aggregate instance.
# This is done by testing instance against the empty string.
Get-VMHost | Select Name, @{ N="Average"; E={($_ | Get-Stat -stat cpu.usage.average -maxsamples 1 -Realtime | Where { $_.Instance -eq "" }).Value} } | Sort -property Average -Descending

# Some interesting stats to look for:
# Find CPU wait time (helps identify contention).
Get-VM | Select Name, @{ N="Summation"; E={($_ | Get-Stat -stat cpu.ready.summation -maxsamples 1 -Realtime | select -first 1).Value} } | Sort -property Summation -Descending