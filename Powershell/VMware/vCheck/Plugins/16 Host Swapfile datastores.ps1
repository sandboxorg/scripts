# Start of Settings 
# End of Settings 

$cluswap = @()
foreach ($clusview in $clusviews) {
	if ($clusview.ConfigurationEx.VmSwapPlacement -eq "hostLocal") {
		$CluNodes = Get-VMHost -Location $clusview.name
		foreach ($CluNode in $CluNodes) {
			if ($CluNode.ExtensionData.Config.LocalSwapDatastore.Value) {
				$Details = "" | Select-Object Cluster, Host, Message
				$Details.cluster = $clusview.name
				$Details.host = $CluNode.name
				$Details.Message = "Swapfile location NOT SET"
				$cluswap += $Details
			}
		}
	}
}
$cluswap | sort name

$Title = "Host Swapfile datastores"
$Header =  "Host Swapfile datastores not set : $(@($cluswap).count)"
$Comments = "The following hosts are in a cluster which is set to store the swapfile in the datastore specified by the host but no location has been set on the host"
$Display = "Table"
$Author = "Alan Renouf"
$PluginVersion = 1.1
$PluginCategory = "vSphere"
