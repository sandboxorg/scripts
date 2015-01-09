function Explain-Event {
	param ($Event)
	$indent = "`n    "

	$explanation = "On " + $Event.CreatedTime + " "
	switch ($Event.GetType().Name) {
		"VmReconfiguredEvent" {
			$explanation += $Event.FullFormattedMessage
			foreach ($change in $Event.ConfigSpec.DeviceChange) {
				$explanation += $indent + $change.Operation + " " + $change.Device
			}
		}
		"VmCreatedEvent" {
			$explanation += $Event.FullFormattedMessage
		}
		default { return }
	}

	Write-Output $explanation
}


# Events with Get-VIEvent.
Get-VIEvent -MaxSamples 100
Get-VIEvent -MaxSamples 100 | Select UserName, FullFormattedMessage
Get-VMHost | Select -first 1 | New-VM -Name Reconfig -DiskMB 1
Get-VM Reconfig | Set-VM -MemoryMB 2048
Get-VM Reconfig | Get-VIEvent | Select UserName, FullFormattedMessage

# What has changed?
Get-VM Reconfig | Get-VIEvent | Foreach { Explain-Event -Event $_ }
