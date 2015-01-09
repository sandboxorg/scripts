#####################################################################################################
# Disable all services specified in the input CSV file.
# The input file must have a header row with two columns:
#		1) Name
#		2) displayName
#
# Input file name is specified at $tsInputFile and should be located in the same directory
# as the script.
#
# Change Record
# ====================
# v1.0 - 21/11/2011 - Initial Version
#
#####################################################################################################

$tsInputFile = "disablesvc.csv"

$oSvcs = Import-Csv $tsInputFile

$oSvcs | foreach {
	$sSvcName = $_.Name
	$sSvcdName = $_.displayName
	$oSvc = Get-WmiObject -Class Win32_Service -Property StartMode,Name -Filter "name='$sSvcName'"
	If ($oSvc.StartMode = 'Disabled')
	{
		Set-Service -Name $oSvc.Name -StartupType Automatic
	}

}