    ###Network Policy Server Synchronization Script
    #This script copies the configuration from the NPS Master Server and imports it on this server.
    #The Account that this script runs under must have Local Administrator rights to the NPS Master.
    #This was designed to be run as a scheduled task on the NPS Secondary Servers on an hourly,daily, or as-needed basis.
    #Last Modified 01 Dec 2009 by JGrote <jgrote AT enpointe NOSPAM-DOTCOM>
     
    ###Variables
    #NPSMaster - Your Primary Network Policy Server you want to copy the config from.
    $NPSMaster = "Server1"
    #NPSConfigTempFile - A temporary location to store the XML config. Use a UNC path so that the primary can save the XML file across the network. Be sure to set secure permissions on this folder, as the configuration including pre-shared keys is temporarily stored here during the import process.
    $NPSConfigTempFile = "\\server2\C$\Temp\NPSConfigTemp\NPSConfig-$NPSMaster.xml"
     
     
    #Create an NPS Sync Event Source if it doesn't already exist
    if (!(get-eventlog -logname "System" -source "NPS-Sync")) {new-eventlog -logname "System" -source "NPS-Sync"}
     
    #Write an error and exit the script if an exception is ever thrown
    trap {write-eventlog -logname "System" -eventID 1 -source "NPS-Sync" -EntryType "Error" -Message "An Error occured during NPS Sync: $_. Script run from $($MyInvocation.MyCommand.Definition)"; exit}
     
    #Connect to NPS Master and export configuration
    $configExportResult = invoke-command -ComputerName $NPSMaster -ArgumentList $NPSConfigTempFile -scriptBlock {param ($NPSConfigTempFile) netsh nps export filename = $NPSConfigTempFile exportPSK = yes}
     
    #Verify that the import XML file was created. If it is not there, it will throw an exception caught by the trap above that will exit the script.
    $NPSConfigTest = Get-Item $NPSConfigTempFile
     
    #Clear existing configuration and import new NPS config
    $configClearResult = netsh nps reset config
    $configImportResult = netsh nps import filename = $NPSConfigTempFile
     
    #Delete Temporary File
    remove-item -path $NPSConfigTempFile
     
    #Compose and Write Success Event
    $successText = "Network Policy Server Configuration successfully synchronized from $NPSMaster.
     
    Export Results: $configExportResult
     
    Import Results: $configImportResult
     
    Script was run from $($MyInvocation.MyCommand.Definition)"
     
    write-eventlog -logname "System" -eventID 1 -source "NPS-Sync" -EntryType "Information" -Message $successText
