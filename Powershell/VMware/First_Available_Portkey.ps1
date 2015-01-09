#################
# Gets first available portkey on dvSwitch
# Doesn't seem to be required on v5.0
#################

$nicTypes = "VirtualE1000","VirtualE1000e","VirtualPCNet32","VirtualVmxnet","VirtualVmxnet2","VirtualVmxnet3" 
$ports = @{}
$pgName = "MyPG"

# Get all the portkeys on the portgroup 
$pg = Get-VirtualPortGroup -Distributed -Name $pgName 
$pg.ExtensionData.PortKeys | %{$ports.Add($_,$pg.Name)}

# Remove the portkeys in use 
Get-View $pg.ExtensionData.Vm | %{$nic = $_.Config.Hardware.Device | where {$nicTypes -contains $_.GetType().Name -and $_.Backing.GetType().Name -match "Distributed"} $nic | %{$ports.Remove($_.Backing.Port.PortKey)}}

# Assign the first free portkey
 $key = ($ports.Keys | Sort-Object)[0]