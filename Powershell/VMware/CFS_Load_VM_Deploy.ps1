#######################################################################################################
# Olympic House Virtual Machine Deployment 
#
# Deploy multiple VMs from CSV file - .\VMs_OLY
#
# Current Limitations
# ====================
# 1) NO ERROR CHECKING/LOGS AS YET
# 2) Currently can only add a single additional disk as ThinProvisioned
# 3) No check for port group existing
#
# Change Record
# ====================
# v0.1 - 08/06/2012 - Initial Version
#
#######################################################################################################

# Add VMware PowerCLI Snapin 
Add-PSSnapin vmware.vimautomation.core 
  
# vCenter to connect to 
$vCenter = "pvct000433.regulated.coop" 
  
# Connect to vCenter 
Connect-VIServer $vCenter 
  
# Import VMs from CSV 
$vmlist = Import-Csv .\vms.csv 
  
# Constants 
$pdns = "10.64.89.200" 
$sdns = "10.50.3.151" 
$netmask = "255.255.255.0" 
$gateway = "10.176.45.1" 
$custspec = "temp_load" 
$taskTab = @{} 
$folder = "Load" 
  
# Loop through CSV file 
Foreach ($item in $vmlist) { 
  
    # Map variables to each item in CSV 
    $basevm = $item.basevm 
    $datastore = $item.datastore 
    $resourcepool = $item.resourcepool 
    $vmname = $item.vmname 
    $ipaddr = $item.ipaddress 
  
	# Set IP Address 
	Get-OSCustomizationSpec $custspec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $ipaddr -SubnetMask $netmask -DefaultGateway $gateway -Dns $pdns,$sdns 

	# Create VM, based on template, located in datastore & resource pool 
	$taskTab[(New-VM -Name $vmname -Template $basevm -Datastore $datastore -ResourcePool $resourcepool -Location $folder -OSCustomizationSpec $custspec -Confirm:$false -RunAsync).Id] = $vmname 
  
	#Remove the NicMapping
	Get-OSCustomizationSpec $custspec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseDhcp 
        
} 
  
# Start each VM that is completed 
$runningTasks = $taskTab.Count 
while($runningTasks -gt 0){ 
	Get-Task | % { 
		if($taskTab.ContainsKey($_.Id) -and $_.State -eq "Success"){ 
			Get-VM $taskTab[$_.Id] | Start-VM 
			$taskTab.Remove($_.Id) 
			$runningTasks-- 
		} 
		elseif($taskTab.ContainsKey($_.Id) -and $_.State -eq "Error"){ 
			$taskTab.Remove($_.Id) 
			$runningTasks-- 
		} 
	} 
Start-Sleep -Seconds 15 
}
