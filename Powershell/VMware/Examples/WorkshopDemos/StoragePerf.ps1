function Get-LunVM {
	param($Lun)

	Get-VM | Where {
		$_ | Get-Stat -stat disk.write.average -realtime -maxsamples 1 `
		    -erroraction SilentlyContinue |
			Where { $_.Instance -eq $Lun } }
}

function Get-LatestStat {
	param($VM, $Stat, $Instance)

	Write-Output ($VM | Get-Stat -Stat $Stat -Realtime -MaxSamples 1 | Where { $_.Instance -eq $Instance }).Value
}

function Get-VMHostLunLatency {
	param($VMHost)

	$luns = $VMHost | Get-ScsiLun
	foreach ($lun in $luns) {
		$stats = $VMHost |
			Get-Stat -stat disk.totalreadlatency.average,disk.totalwritelatency.average -maxsamples 1 -realtime |
			Where { $_.Instance -eq $Lun.CanonicalName }
		if ($stats.length -ne $null) {
			$obj = New-Object PSObject
			$obj | Add-Member -MemberType NoteProperty -Name Lun -Value $lun.CanonicalName
			$obj | Add-Member -MemberType NoteProperty -Name ReadLatency -Value ($stats[0].Value)
			$obj | Add-Member -MemberType NoteProperty -Name WriteLatency -Value ($stats[1].Value)
			Write-Output $obj
		}
	}
}

function Get-LunVMDiskRate {
	param ($Lun)
	Get-LunVM -Lun $Lun | Foreach { $_ | Select Name,
		@{ Name="ReadRate"; E={Get-LatestStat -VM $_ -Stat disk.read.average -instance $Lun }},
		@{ Name="WriteRate"; E={Get-LatestStat -VM $_ -Stat disk.write.average -instance $Lun }} }
}

# Let's switch to storage performance.
Get-VMHost esx01a.vmworld.com | Get-Stat -stat disk.write.average -MaxSamples 2 -Realtime
Get-VMHost | Get-Stat -stat disk.write.average -MaxSamples 1 -Realtime |
	Select Instance

# Those instances map to SCSI LUNs
Get-VMHost esx01a.vmworld.com | Get-ScsiLun | Select CanonicalName, LunType, CapacityMB | `
	Format-Table -AutoSize
Get-VMHost esx01a.vmworld.com | Get-Stat -Stat disk.totalwritelatency.average -MaxSamples 1 -Realtime | `
	Select Value, Unit, Instance | Format-Table -AutoSize
Get-VMHostLunLatency -vmhost (get-vmhost) | Format-Table -Autosize *

# Let's take another look at disk write average.
Get-VM vCenter | get-stat -stat disk.write.average -maxsamples 1 | `
	Format-List *

# We can easily write a function to show all usage on a given LUN.
$lun = "naa.6006016064201900ea2f0528e2c8de11"
Get-LunVM -Lun $lun
Get-LunVMDiskRate -Lun $lun

# Launch one perf test and try again.
Get-VMHostLunLatency -vmhost (get-vmhost) | Format-Table -Autosize *
Get-LunVMDiskRate -Lun $lun

# Launch the other perf test.
Get-VMHostLunLatency -vmhost (get-vmhost) | Format-Table -Autosize *
Get-LunVMDiskRate -Lun $lun