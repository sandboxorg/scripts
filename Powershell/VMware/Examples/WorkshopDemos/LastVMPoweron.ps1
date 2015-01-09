function Get-vCenterRetentionPolicy {
	$settings = get-view -id OptionManager-VpxSettings
	if ($settings) {
		$maxAge = ($settings.Setting | where { $_.Key -eq "task.maxAge" }).Value
		$maxAgeEnabled = ($settings.Setting | where { $_.Key -eq "task.maxAgeEnabled" }).Value

		$obj = New-Object -TypeName PSObject
		$obj | Add-Member -MemberType NoteProperty -Name "MaxAge (Days)" -Value $maxAge
		$obj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value $maxAgeEnabled
		Write-Output $obj
	}
}

# Get a VM's last power on date based on the VM's events.
function Get-LastPowerOn {
	param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            HelpMessage="VM"
        )]
        [VMware.VimAutomation.Types.VirtualMachine]
        $VM
	)

	Process {
		# Patterns that indicate an attempt to power a VM on. This differ
		# across versions and likely across language. Please add your own
		# if you find one missing.
		$patterns = @(
			"*Power On virtual machine*",	# vCenter 4 English
			"*is starting*"					# ESX 4/3.5 English
		)

		$events = $VM | Get-VIEvent
		$qualifiedEvents = @()
		foreach ($pattern in $patterns) {
			$qualifiedEvents += $events | Where { $_.FullFormattedMessage -like $pattern }
		}
		$qualifiedEvents = $qualifiedEvents | Where { $_ -ne $null }
		$sortedEvents = Sort-Object -InputObject $qualifiedEvents -Property CreatedTime -Descending
		$event = $sortedEvents | select -First 1

		$obj = New-Object PSObject
		$obj | Add-Member -MemberType NoteProperty -Name VM -Value $_
		$obj | Add-Member -MemberType NoteProperty -Name PowerState -Value $_.PowerState
		$obj | Add-Member -MemberType NoteProperty -Name LastPoweron -Value $null
		if ($event) {
			$obj.LastPoweron = $event.CreatedTime
		}

		Write-Output $obj
	}
}

# This function shows the last poweron.
Get-VM vCenter | Get-LastPoweron

# We can also have a look at vCenter's retention policies.
Get-vCenterRetentionPolicy

# This policy can be changed via the OptionManager-VpxSettings object.