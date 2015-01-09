# Get all services 
Get-WmiObject Win32_Service |
Format-Table -AutoSize @(
    'Name'
    'DisplayName'
    @{ Expression = 'State'; Width = 9 }
    @{ Expression = 'StartMode'; Width = 9 }
    'StartName'
)

# Get all services that are stopped and set to auto

Get-WmiObject Win32_Service |
Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' } |
# process them; in this example we just show them:
Format-Table -AutoSize @(
    'Name'
    'DisplayName'
    @{ Expression = 'State'; Width = 9 }
    @{ Expression = 'StartMode'; Width = 9 }
    'StartName'
)