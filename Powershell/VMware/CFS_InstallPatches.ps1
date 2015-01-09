#######################################################################################################
# Olympic House ESXi Host Installation 
#
# Current Limitations
# ====================
# 1) NO ERROR CHECKING/LOGS AS YET
# 2) Disables Admission Control with no check to see if it's enabled
# 3) Only updates if build number is 623860
# 4) Only installs specific patches
# 5) Patch location is hardcoded
# 6) Restarts host regardless of whether patch requires it
#
# Change Record
# ====================
# v0.1 - 11/06/2012 - Initial Version
#
#######################################################################################################

# Add VMware PowerCLI Snapin
Add-PSSnapin vmware.vimautomation.core 

# Define vCenter
$vCenter = "pvct000433.regulated.coop" 

# Connect to vCenter
Connect-VIServer $vCenter 

# Get all Hosts that are connected to vCenter where hostname does not start with 'nesx'
$hosts = Get-VMHost | Where-object -filter {$_.Name -notlike 'nesx*'} 

# Loop through each ESXi host
foreach ($olyvmhost in $hosts) { 

	# Check to see if Build number of ESXi is correct
    If ($olyvmhost.ExtensionData.Config.Product.FullName -like "*623860") { 

		# Get cluster that host is a member of & disable admission control
		Get-Cluster -VMHost $olyvmhost | Set-Cluster -HAAdmission $false -confirm:$false 

		# Put host into maintenance mode
		Set-VMHost $olyvmhost -State Maintenance 

		# Install Patches
		Install-VMHostPatch -VMHost $olyvmhost -HostPath /vmfs/volumes/OLY_vSphere_Infra_01/ESXi500-201204001/metadata.zip 
		Install-VMHostPatch -VMHost $olyvmhost -HostPath /vmfs/volumes/OLY_vSphere_Infra_01/ESXi500-201205001/metadata.zip 

		# Restart host
		Restart-VMHost $olyvmhost -confirm:$false 

		# Wait for host to reboot
		Write-Host "Waiting for $olyvmhost to reboot..." 
		Sleep 180 
		
		# Try to connect to host, if fails keep trying until connection is successful
		Write-Host "Checking to see if $olyvmhost is up yet..." 
		Connect-VIServer -Server $olyvmhost -user root -password V1rtua1isation 
		While ($? -ne $true){ 
			Sleep 60 
			Write-Host "$olyvmhost not responding yet..." 
			Connect-VIServer -Server $olyvmhost -user root -password V1rtua1isation 
		} 

		# Disconnect from host
		Disconnect-VIServer $olyvmhost.name 

		# Exit maintenance mode
		Set-VMHost $olyvmhost -State Connected 

		# Enable admission control
		Get-Cluster -VMHost $olyvmhost | Set-Cluster -HAAdmission $true -confirm:$false 
	} 
}
