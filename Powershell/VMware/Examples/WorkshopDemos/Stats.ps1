# Let's look at stats.
Get-StatType
Get-VMHost | Get-StatType
# Some stat types are displayed twice. We can deal with this pretty easily.
Get-VMHost | Get-StatType | Sort -Unique

# Intervals are independent of object.
Get-StatInterval

# The "instance" property is not shown in the default output, but is very important.
Get-VMHost | Get-Stat -stat cpu.usage.average
Get-VMHost | Get-Stat -stat cpu.usage.average | select TimeStamp, Value, Instance

# Use group to find out what instances exist.
Get-VMHost | Get-Stat -stat cpu.usage.average | Group Instance

# A bug to watch out for, -maxsamples does not give you per-instance samples.
# You can work around it client-side.
Get-VMHost | Get-Stat -stat cpu.usage.average | Group Instance | Foreach { $_.Group | Select -first 5 }
Get-VMHost | Get-Stat -stat cpu.usage.average | Group Instance | Foreach { $_.Group | Select -first 5 } | select TimeStamp, Value, Instance

# Compute average CPU utilization over the period on a per-CPU basis.
Get-VMHost | Get-Stat -stat cpu.usage.average | Group Instance
Get-VMHost | Get-Stat -stat cpu.usage.average | Group Instance | Foreach { $_.Group | Measure-Object }
Get-VMHost | Get-Stat -stat cpu.usage.average | Group Instance | Foreach { $_.Group | Measure-Object -Average -property Value } | Select Average

# Sort VMs in order of utilization over the last 5 minutes.
# Let's start by identifying what we need.
get-vm Ubuntu | Get-Stat -stat cpu.usage.average -maxsamples 1 -intervalmins 5
# How can we put this into a consolidated report?
get-vm | Select Name, { ($_ | Get-Stat -stat cpu.usage.average -maxsamples 1 -intervalmins 5).Value }
# The column name is really ugly and limits our ability to sort.
# Let's use an advanced feature of Select to fix that.
Get-VM | Select Name, @{ N="Average"; E={($_ | Get-Stat -stat cpu.usage.average -maxsamples 1 -intervalmins 5).Value} }
# Now we can sort with ease.
Get-VM | Select Name, @{ N="Average"; E={($_ | Get-Stat -stat cpu.usage.average -maxsamples 1 -intervalmins 5).Value} } | Sort -property Average -Descending

# Some interesting stats to look for:
# Find CPU wait time (helps identify contention).
Get-VM | Select Name, @{ N="Summation"; E={($_ | Get-Stat -stat cpu.ready.summation -maxsamples 1 -intervalmins 5 | select -first 1).Value} } | Sort -property Summation -Descending

# Let's look at some disk utilization.
get-vm ubuntu | get-stat -stat disk.write.average
# How can we average that? Again, PowerShell helps.
get-vm ubuntu | get-stat -stat disk.write.average | measure-object -property value -Average
# Can we rank all our VMs this way? Yes!
Get-VM | Select Name, @{ N="DiskUseKbps"; E={($_ | Get-Stat -stat disk.write.average | Measure-Object -property value -Average).Average} } | Sort -property DiskuseKbps -Descending

# There are also a lot of interesting host stats.
# You can also see how much memory the system is sharing. The more similar your guests are the more you will tend to share.
Get-VMHost | Get-Stat -stat sys.resourceMemShared.latest | Where { $_.Instance -eq "host" }

# Intervals are always independent of object.
Get-StatInterval

# On VC we can see all our hosts.
Get-VMHost

# Depending on your logging level you may see fewer stats.
# You can still get some host stats using the -realtime parameter.
Get-VMHost 192.168.1.11 | Get-StatType

# This does let us get a global picture though.
# Rank hosts in terms of utilization over the past hour.
Get-VMHost | Select Name, @{ N="Average"; E={($_ | Get-Stat -stat cpu.usage.average -maxsamples 1 -intervalmins 60).Value} } | Sort -property Average -Descending

# We can easily restrict the search to a given cluster.
# Find the top 2 most utilized hosts in cluster "mycluster" in the past hour.
Get-Cluster mycluster | Get-VMHost | Select Name, @{ N="Average"; E={($_ | Get-Stat -stat cpu.usage.average -maxsamples 1 -intervalmins 60).Value} } | Sort -property Average -Descending

# You can also get a system's uptime.
Get-VMHost | Select Name, @{ N="Uptime"; E={($_ | Get-Stat -stat sys.uptime.latest -maxsamples 1 -realtime).Value} } | Sort -property Uptime -Descending
