#######################################################################################################
# Olympic House Virtual Machine Deployment 
#
# Deploy multiple VMs from CSV file - .\VMs_OLY
#
# Current Limitations
# ====================
# 1) NO ERROR CHECKING/LOGS AS YET
# 2) Currently can only add a single additional disk as ThinProvisioned
# 3) VMs created sequentially
# 4) No check for port group existing
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
$vmlist = Import-Csv .\vms_OLY.csv 

# Loop through CSV file
Foreach ($item in $vmlist) { 

	# Map variables to each item in CSV
    $basevm = $item.basevm 
    $datastore = $item.datastore 
    $resourcepool = $item.resourcepool 
    $vmname = $item.vmname 
    $vlan = $item.vlan 
    $memory = $item.memory 
    $numcpu = $item.numcpu 
    $diskd = $item.diskd 
    $notes = $item.notes

	# Create VM, based on template, located in datastore & resource pool
	New-VM -Name $vmname -Template $basevm -Datastore $datastore -ResourcePool $resourcepool 
    
	# Change port group
    Get-VM -Name $vmname | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $vlan -Confirm:$false 

	# Change number of vCPUs, Memory & Notes
	Set-VM -VM $vmname -numcpu $numcpu -memoryMB ([int]$memory * 1024) -description $notes -confirm:$false 

	# Add additional hard disk
    New-HardDisk -VM $vmname -capacityKB ([int]$diskd * 1024 * 1024) -storageformat thin 

	# Power on VM
    Get-VM $vmname | Start-VM 

}
