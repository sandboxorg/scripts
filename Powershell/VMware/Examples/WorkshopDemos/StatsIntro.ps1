# Here's how to find out what stats you have.
Get-StatType

# Different objects have different types.
Get-VM | Select -first 1 | Get-StatType
get-resourcepool | select -first 1 | get-stattype

# Here's how you can get a description of stats in PowerCLI.
Get-VMHost | Get-Stat | select MetricId, Description -Unique | Format-List *
Get-VM vCenter | Get-Stat | select MetricId, Description -Unique | Format-List *

# It's very important to understand instances.
Get-VMHost | get-stat -stat cpu.usage.average -realtime | Group Instance

# The stats in vCenter depend on the stat level.
# If you connect directly to ESX you get a different picture.