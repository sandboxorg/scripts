# To increase queue depth, we have to change and advanced option AND a kernel module parameter.
# You have to connect directly to ESX to change kernel module settings.
Connect-VIServer 10.91.246.5
Get-VMHost 10.91.246.5 | Set-VMHostAdvancedConfiguration -Name Disk.SchedNumReqOutstanding -Value 64
Set-VMHostModule -Server 10.91.246.5 lpfc820 -Options lpfc0_lun_queue_depth=64

# You have to reboot the host for this to take effect.
Get-VMHost 10.91.246.5 | Restart-VMHost
Disconnect-VIServer 10.91.246.5

# Read this before tweaking your queue depth:
# http://frankdenneman.wordpress.com/2009/03/04/increasing-the-queue-depth/
