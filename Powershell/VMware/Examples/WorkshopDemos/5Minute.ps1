# To see what PowerCLI can do, start with Get-VICommand
Get-VICommand

# There are more than 150 commands, called "cmdlets".
# That's a lot! You can narrow your search based on something that
# interests you.
Help *VM*

# You can also use "help" to narrow your search.
# Let's say you want to do something with virtual switches.
help *virtualswitch*
help Get-VirtualSwitch

# Or maybe you care about firewall rules.
help *firewall*

# Cmdlets exist to get all your favorite objects.
Get-Datacenter
Get-VMHost
Get-Cluster
Get-VM

# These commands are made to work with each other.
# You can easily use a sequence of them to filter.
Get-VMHost
Get-Cluster mycluster | Get-VMHost

# Or we can restrict VMs to a given host.
Get-VM | Measure-Object
Get-VMHost esx01a.vmworld.com | Get-VM | Measure-Object

# We can easily identify the datastore a VM is on.
Get-VM vCenter
Get-VM vCenter | Get-Datastore

# We can even go the other way.
Get-Datastore FC_LUN01_PMG01 | Get-VM

# Objects are formatted when they are printed to the screen.
# But, there may be more to them than what you see with default output.
Get-Datastore
Get-Datastore | Format-Table *
Get-Datastore | Format-List *

# Some objects are rich with properties.
Get-VM | Format-List *

# Use the Select cmdlet to choose just the stuff you care about.
Get-VM | Select Name, Host, NumCpu, MemoryMB, HARestartPriority | Format-Table