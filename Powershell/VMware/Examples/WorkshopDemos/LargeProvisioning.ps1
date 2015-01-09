# First let's understand the paramters we're dealing with.
Get-VMHost
Get-VMHost esx01a.vmworld.com | Get-VirtualPortGroup
Get-VMHost esx01a.vmworld.com | Get-Datastore

# Basic New-VM.
Get-VMHost esx01a.vmworld.com | New-VM -Name BlankVM1 -NetworkName DHCP-VM02 -DiskMB 1mb -Datastore FC_LUN02_PMG01

# You can also clone running VMs.
Get-VM
Get-VM "XP 1" | New-VM -Name "XP 1 Clone" -VMHost esx01a.vmworld.com

# Basic cloning with templates and specs.
Get-Template
Get-OSCustomizationSpec

# You can see most of the spec's properties.
# But if you want to modify it I recommend using vSphere Client.
Get-OSCustomizationSpec | Format-List *
Get-Template "Thin Template" | `
	New-VM -Name "Cloned 1" -OSCustomizationSpec "Thin Spec" -vmhost esx01a.vmworld.com

# There are two ways to do cloning with static IPs.
Get-OSCustomizationSpec
Get-OSCustomizationSpec "Thin Spec" | New-OSCustomizationSpec -Name Static1
Get-OSCustomizationSpec

Get-OSCustomizationSpec Static1 | Format-List *
Get-OSCustomizationSpec Static1 | Get-OSCustomizationNicMapping
Get-OSCustomizationSpec Static1 | Get-OSCustomizationNicMapping | `
	Set-OSCustomizationNicMapping -IpMode UseStaticIP `
	-IpAddress 10.24.1.10 -DefaultGateway 10.24.1.1 `
	-SubnetMask 255.255.0.0 -Dns 10.24.1.1

Get-Template "Thin Template" | `
	New-VM -Name "Cloned 2" -OSCustomizationSpec Static1 -vmhost esx01a.vmworld.com

# If you want to think big, use a CSV file to define your parameters.
# If you're using static IP, take advantage of client-side profiles.
Invoke-Item provision.csv
$i = 1
Foreach ($ent in (Import-Csv provision.csv)) {
	$i++
	$specName = ("Static" + $i)
	Get-OSCustomizationSpec "Thin Spec" | New-OSCustomizationSpec -Name $specName
	Get-OSCustomizationSpec $specName | Get-OSCustomizationNicMapping | `
		Set-OSCustomizationNicMapping -IpMode UseStaticIP `
		-IpAddress $ent.ipaddr -DefaultGateway $ent.gateway `
		-SubnetMask $ent.subnet -Dns $ent.dns
	Get-Template | New-VM -Name $ent.vmname -OSCustomizationSpec $specName -VMHost $ent.vmhost
}
