# VMotion and Storage VMotion are both controlled by Move-VM.

# VMotion.
Get-VM Test*
Get-VM Test* | Get-VMHost

# The tricky bit is we have to use -Destination
Get-VM Test* | Move-VM -Destination esx01b.vmworld.com
# All the usual rules about selection apply.

# Storage VMotion.
Get-VM Test*
Get-VM Test* | Get-Datastore
Get-Datastore
Get-VM Test* | Move-VM -Datastore FC_LUN01_PMG01