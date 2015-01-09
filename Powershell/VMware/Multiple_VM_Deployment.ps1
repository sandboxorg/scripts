##########################################################
# cloneandsetip.ps1
# Jase McCarty 6/5/2010
# Posh Script to clone VM's and set appropriate
# IP addresses in Windows Virtual Machines
##########################################################
add-PSSnapin vmware.vimautomation.core

Connect-VIServer fsctfxsvvc01
 
$vmlist = Import-CSV C:vms.csv
 
foreach ($item in $vmlist) {
 
    # I like to map out my variables
    $basevm = $item.basevm
    $datastore = $item.datastore
    $vmhost = $item.vmhost
    $custspec = $item.custspec
    $vmname = $item.vmname
    $ipaddr = $item.ipaddress
    $subnet = $item.subnet
    $gateway = $item.gateway
    $pdns = $item.pdns
    $sdns = $item.sdns
    $vlan = $item.vlan
 
    #Get the Specification and set the Nic Mapping (Apply 2 DNS/WINS if 2 are present)
    If ($Varable) {
        Get-OSCustomizationSpec $custspec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $ipaddr -SubnetMask $subnet -DefaultGateway $gateway -Dns $pdns,$sdns -Wins $pwins,$swins
    } else {
        Get-OSCustomizationSpec $custspec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $ipaddr -SubnetMask $subnet -DefaultGateway $gateway -Dns $pdns -Wins $pwins
    }
 
    #Clone the BaseVM with the adjusted Customization Specification
    New-VM -Name $vmname -VM $basevm -Datastore $datastore -VMHost $vmhost | Set-VM -OSCustomizationSpec $custspec -Confirm:$false
 
    #Set the Network Name (I often match PortGroup names with the VLAN name)
    Get-VM -Name $vmname | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $vlan -Confirm:$false
 
    #Remove the NicMapping (Don't like to leave things unkept)
    Get-OSCustomizationSpec $custspec | Get-OSCustomizationNicMapping | Remove-OSCustomizationNicMapping -Confirm:$false
}