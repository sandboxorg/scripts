# For this demo, pick a particular host.
$h = get-vmhost 10.91.246.2

# Let's take a look at advanced configuration options.
$h | Get-VMHostAdvancedConfiguration

# That's a lot of stuff! How many options are there exactly?
$h | Get-VMHostAdvancedConfiguration | Measure-Object

# That's not right??? Something is funny about the object. Let's take a closer look at it.
$config = $h | Get-VMHostAdvancedConfiguration
$config | Get-Member

# This thing is a hash table. How do we deal with it?
# Let's list the values.
$config

# How do we get a specific value?
$config."Cpu.MoveCurrentRunnerPcpus"

# Let's count the number of advanced options.
$config.Keys | measure-object

# That's a lot!!! How can we start to understand it all?
$config.Keys | Foreach { $_.Split(".")[0] } | group

# Use case: NFS tuning.
# Let's set the max NFS heartbeat failures to 20 across all our hosts.
$h | Get-VMHostAdvancedConfiguration | select -expand Keys | Where { $_ -like "NFS*" }

# Let's look at some current values.
# First let's add a function to help things out.
Get-Content getAdvancedSetting.ps1
. .\getAdvancedSetting.ps1
Get-VMHost | Select Name, { Get-AdvancedSetting $_ "NFS.HeartbeatMaxFailures" }

# Now let's change some settings.
# Set-VMHostAdvancedConfiguration is easy compared to Get-
# Get-VMHost | Set-VMHostAdvancedConfiguration -name NFS.HeartbeatMaxFailures -Value 10

# If you use a lot of NFS, you will probably need to increase the TCP/IP heap size.
Get-VMHost | Select Name, { Get-AdvancedSetting $_ "Net.TcpipHeapSize" }

# Increase the heap size to 30mb.
Get-VMHost | Set-VMHostAdvancedConfiguration -name Net.TcpipHeapSize -Value 30