# See cmdlets related to logs.
help *log*

# The log types on ESX and vCenter are different. We can see both.
Get-LogType
Get-VMHost esx01a.vmworld.com | Get-LogType

# What happens when we get hostd logs?
Get-VMHost esx01a.vmworld.com | Get-Log hostd

# What is this??? Let's look at the actual stuff within the object.
Get-VMHost esx01a.vmworld.com | Get-Log hostd -NumLines 1000 | Select -expand Entries

# How many lines is the log in total?
Get-VMHost esx01a.vmworld.com | Get-Log hostd | Select -expand Entries | Measure-Object

# We can do some simple filtering.
Get-VMHost esx01a.vmworld.com | Get-Log hostd -NumLines 1000 | Select -expand Entries | Select-String warning
Get-VMHost esx01a.vmworld.com | Get-Log hostd -NumLines 1000 | Select -expand Entries | Select-String -notmatch warning
Get-VMHost esx01a.vmworld.com | Get-Log hostd -NumLines 1000 | Select -expand Entries | Select-String -notmatch warning,verbose
Get-VMHost esx01a.vmworld.com | Get-Log hostd -NumLines 1000 | Select -expand Entries | Select-String -notmatch warning,verbose,info

# Checking other log streams for errors.
Get-VMHost esx01a.vmworld.com | get-log vpxa -NumLines 1000 | Select -expand Entries | select-string -notmatch verbose

# A nice little report.
Get-VMHost esx01a.vmworld.com | Get-Log vmksummary | Select -expand Entries

# Careful! Logs like vmkwarning can grow out of control.
# You can limit the number of entries with -StartLineNum and -LastLineNum
Get-VMHost esx01a.vmworld.com | Get-Log vmkwarning -StartLineNum 1 -NumLines 1000 | Select -expand Entries
Get-VMHost esx01a.vmworld.com | Get-Log vmkwarning -StartLineNum 1001 -NumLines 1000 | Select -expand Entries

# The logs on VC are completely different.
Get-LogType

# Get a vpxd log.
$logType = Get-LogType | Where { $_.Key -like "vpxd:vpxd-??.log" } | Select -first 1
Get-Log $logType.Key -NumLines 1000 | Select -Expand Entries

# There is interesting stuff in the errors here.
Get-Log $logType.Key -NumLines 1000 | Select -Expand Entries | Select-String error

# Let's look inside a profiling log.
$logType = Get-LogType | Where { $_.Key -like "vpxd:vpxd-profile*.log" } | Select -first 1
Get-Log $logType.Key -NumLines 1000 | Select -Expand Entries
