# First you need to know available adapters.
Get-VMHost
Get-VMHost | Get-VMHostNetworkAdapter

# Now we know enough to create.
Get-VMHost | New-VirtualSwitch -Name "New Switch" -Nic vmnic2,vmnic3

# We can then create portgroups within the switch.
Get-VMHost | Get-VirtualSwitch -Name "New Switch" | New-VirtualPortGroup -Name "New Portgroup"

# We can also update the virtual switch, properties like number of ports.
Get-VMHost | Get-VirtualSwitch -Name "New Switch" | Set-VirtualSwitch -NumPorts 1024
# (This operation would require a reboot)

# Removal is also easy.
Get-VMHost | Get-VirtualPortGroup -Name "New Portgroup" | Remove-VirtualPortGroup
Get-VMHost | Get-VirtualSwitch -Name "New Switch" | Remove-VirtualSwitch

# You can also configure trunking and other attributes of the switch.
# But this will be covered as an advanced topic.