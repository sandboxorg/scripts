$serviceInstance = get-view ServiceInstance
$alarmMgr = get-view $serviceInstance.Content.alarmManager
$alarms = $alarmMgr.GetAlarm($null)
$alarms | ForEach-Object {
	$alarm = Get-View -Id $_
	$alarmname = $alarm.Info.Name
	Write-Host "Updating Alarm $alarmname"
	if ($predefined -contains $alarm.Info.Name) {
		$spec = New-Object VMware.Vim.AlarmSpec
		$spec.Action = New-Object VMware.Vim.GroupAlarmAction
		$spec.Action.Action = @(New-Object VMware.Vim.AlarmTriggeringAction)
		$spec.Action.Action[0].Action = New-Object VMware.Vim.SendSNMPAction
		$spec.Action.Action[0].Green2yellow = $false
		$spec.Action.Action[0].Red2yellow = $true
		$spec.Action.Action[0].Yellow2green = $false
		$spec.Action.Action[0].Yellow2red = $true
		$spec.Name = $alarm.Info.Name
		$spec.Description = $alarm.Info.Description
		$spec.Expression = $alarm.Info.Expression
		$spec.Enabled = $alarm.Info.Enabled
		$spec.Setting = $alarm.Info.Setting

		$alarm.ReconfigureAlarm($spec)
	}
}
