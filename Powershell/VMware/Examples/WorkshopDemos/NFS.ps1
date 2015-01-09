# Take a look at the list of datastores before.
Get-Datastore

# Adding NFS datastores is pretty easy.
Get-VMHost | New-Datastore -nfs -name NFS1 -Path "/mnt/nfs1/nfs11/test1" -nfshost 10.91.246.21

# Let's look at the new set of datastores.
Get-Datastore

# We can also verify that each host sees the datastore.
Get-VMHost | Foreach { $_ | Get-Datastore }