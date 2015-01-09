# Report on HD file and device names.
# If you have any RDMs they will display as HDDeviceName

$report = @() 
$vms = Get-VM | Get-View 
foreach($vm in $vms) {
			foreach($dev in $vm.Config.Hardware.Device)	{
				if(($dev.gettype()).Name -eq "VirtualDisk")	{ 
						$row = "" | select VMName, HDDeviceName, HDFileName 
						$row.VMName = $vm.Name 
						$row.HDDeviceName = $dev.Backing.DeviceName 
						$row.HDFileName = $dev.Backing.FileName 
						$report += $row 
					}
			}
} 
$report
