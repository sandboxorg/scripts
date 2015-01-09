function Get-UnShareableDatastore {
	Foreach ($datastore in (Get-Datastore)){
		If (($datastore | get-view).summary.multiplehostaccess -eq $false) {
			Write-Output $datastore
		}
	}
}

# Find all VMs on local storage.
Get-UnSharableDatastore | Get-VM