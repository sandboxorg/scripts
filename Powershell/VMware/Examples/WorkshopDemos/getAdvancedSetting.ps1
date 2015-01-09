function Get-AdvancedSetting {
	param ($vmhost, $setting)

	$value = ($vmhost | Get-VMHostAdvancedConfiguration).$setting
	return $value
}
