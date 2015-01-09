# Start with the simple Get-VM
Get-VM

# These represent automation objects. They lack most of the server-side properties.
# Get-View loads a full representation of the object.
Get-VM | Select-Object -First 1 | Get-View | Set-Variable x
$x
$x.Network
$x.runtime

# This corresponds exactly to the API documentation.
Explorer http://www.vmware.com/support/developer/vc-sdk/visdk400pubs/ReferenceGuide/vim.VirtualMachine.html

# Get-Member will enumerate all the properties and methods of the object.
$x | Get-Member

# You can restrict the types of things returned by Get-Member.
$x | Get-Member -MemberType Method

# You can call any method given the right arguments.
$x | Get-Member PowerOnVM | Format-List *

# Let's try it out!
$x.PowerOffVM()
$x.PowerOnVM()

# Some views have static names, like ServiceInstance
Get-View ServiceInstance
Get-View ServiceInstance | Set-Variable si

# Within the SserviceInstance there are all types of other managers.
$si.content

# These can be loaded in their own right.
get-view $si.Content.SnmpSystem