function Get-TkeConfigIssue {
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            HelpMessage="VI Object"
        )]
        [VMware.VimAutomation.Types.VIObject]
        $VIObject
    )

	Process {
		$hView = $VIObject | Get-View -Property configIssue
		if ($hView.ConfigIssue) {
			foreach ($issue in $hView.ConfigIssue) {
				$obj = New-Object PSObject
				$obj | Add-Member -MemberType NoteProperty -Name Object      -Value $VIObject
				$obj | Add-Member -MemberType NoteProperty -Name CreatedTime -Value $issue.CreatedTime
				$obj | Add-Member -MemberType NoteProperty -Name Message     -Value $issue.FullFormattedMessage
				$obj | Add-Member -MemberType NoteProperty -Name EventType   -Value $issue.EventTypeId
				$obj | Add-Member -MemberType NoteProperty -Name Severity    -Value $issue.Severity
				Write-Output $obj
			}
		}
	}
}

# VMs asking questions are frozen.
Get-VMQuestion

# A lot of interesting stuff will appear as "configuration issues".
# This doesn't "bubble up" the way alarms do.
Get-Cluster | Get-TkeConfigIssue

# Any and all types of objects can be used.
Get-Inventory | Get-TkeConfigIssue

# Dead SCSI LUNs are never good.
Get-ScsiLun -vmhost $esxhost | Get-ScsiLunPath
Get-ScsiLun -vmhost $esxhost | Get-ScsiLunPath | Where { $_.State -eq "Dead" }