# For host profiles start with a host just how you like it.
Get-VMHost 10.91.246.2

# Make that your new profile.
Get-VMHost 10.91.246.2 | New-VMHostProfile -Name Profile1

# You can apply this to your other hosts.
Get-VMHost | Where { $_.Name -ne "10.91.246.2" } | Apply-VMHostProfile -Profile Profile1

# Oops, we need to be in maintenance mode.
Get-VMHost | Where { $_.Name -ne "10.91.246.2" } | Set-VMHost -State Maintenance
Get-VMHost | Where { $_.Name -ne "10.91.246.2" } | Apply-VMHostProfile -Profile Profile1

# If a host gets changed it will be flagged as out of compliance with the profile.
Get-VMHost 10.91.246.5 | New-VirtualSwitch -Name InternalOnly
Get-VMHost 10.91.246.5 | Test-VMHostProfileCompliance | Format-List *

# We can also use profile to duplicate changes to other hosts.
Get-VMHost 10.91.246.2 | New-VirtualSwitch -Name "New Switch"
Set-VMHostProfile -profile Profile1 -ReferenceHost 10.91.246.2

# Apply these changes to everyone.
# XXX: This shows a false-positive bug.
Get-VMHost | Where { $_.Name -ne "10.91.246.2" } | Apply-VMHostProfile -Profile Profile1

# Look for any host that is out of compliance.
Get-VMHost 10.91.246.5 | Test-VMHostProfileCompliance -Profile Profile1