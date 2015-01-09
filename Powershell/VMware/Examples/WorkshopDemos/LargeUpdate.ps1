# Large-scale updates are easy with PowerCLI.
# Note there is hardly any difference between updating 1 and updating many.
Get-VM "Test 1" | Set-VM -MemoryMB 1024
Get-VM Test* | Set-VM -MemoryMB 1024

# -WhatIf will let you do a dry run.
Get-VM Test* | Set-VM -MemoryMB 1024 -WhatIf