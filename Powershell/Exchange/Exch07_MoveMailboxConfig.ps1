##########################################################################
#	Exchange 2007 
#	Move Mailboxes to Dial-Tone Database
#	Only moves configuration data
#	
#	Input file needs to have a list of Exchange alias' in a single column
##########################################################################

# Set PS Execution policy so the script will run
"Set-ExecutionPolicy unrestricted"

$sMbxServer = "JMC-EXC-01"
$sMbxSG = "First Storage Group"
$sMbxDB = "Mailbox Database"
$sImport = "C:\restore.csv"
$sExport

# Import users into script
$alias = get-content $sImport

# Move mailboxes
$_alias | Move-Mailbox -ConfigurationOnly -TargetDatabase "$sMbxServer\$sMbxSG\$sMbxDB" -MaxThreads 10 -Confirm:$false