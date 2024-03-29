$Title = "VMs with CPU or Memory Limits Configured"
$Header =  "VMs with CPU or Memory Limits Configured"
$Comments = "The following VMs have a CPU or Memory Limit configured which may impact the performance of the VM. Note: -1 indicates no limit"
$Display = "Table"
$Author = "Jonathan Medd"
$PluginVersion = 1.1

# Start of Settings 
# End of Settings
@($VM | Get-VMResourceConfiguration | Where-Object {$_.CpuLimitMHZ -ne '-1' -or $_.MemLimitMB -ne �-1�} | Select-Object VM,CpuLimitMhz,MemLimitMB)
$PluginCategory = "vSphere"
