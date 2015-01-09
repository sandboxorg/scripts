# Setting DNS is easy with Set-VMHostNetwork
Get-VMHost | Get-VMHostNetwork | Set-VMHostNetwork -DnsAddress 10.24.1.1,10.24.1.2