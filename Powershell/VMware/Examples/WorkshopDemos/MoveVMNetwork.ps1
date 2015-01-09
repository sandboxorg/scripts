# Moving networks is easy.
# But! It doesn't use Set-VM.
# Instead we drill down to the NetworkAdapter object.
Get-VM | Get-NetworkAdapter

# The choices we have are based on VirtualPortGroup.
Get-VMHost | Get-VirtualPortGroup

# Let's move everything over.
Get-VM Test* | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName DHCP-VM03
Get-VM Test* | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName DHCP-VM02

# Adding a new network adapter works the same way.
Get-VM Test* | New-NetworkAdapter -NetworkName DHCP-VM03