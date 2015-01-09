# Virtual Center Details
$server_address = "vCenterServer"
$username = "Administrator"
$password = "password"
# Vm Details
$destination_host = "AnyVMHost.network.LOCAL"
$template_name = "Template1"
$datastore_name = "DataStore1"
$customization = "Customization1"
$location = "vCenter folder location"
# Name the VMs in this array
$array = "Server1", "Server1"
$iparray = "10.1.1.10", "10.1.1.11"
$a= 0

Connect-VIServer -Server $server_address -Protocol https
-User $username -Password $password
foreach ($vm in $array)
{
Get-OSCustomizationSpec $customization | Get-OSCustomizationNicMapping |
Set-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $IParray[$a]
-SubnetMask 255.255.255.0 -DefaultGateway 10.1.1.1 -Dns 10.1.1.2,10.1.1.3
$vm=New-VM -Name $vm -Location $location -Template $template_name
-Host $destination_host -Datastore $datastore_name -OSCustomizationSpec
$customization -Confirm:$false $a = $a + 1
}