$folder = Get-View (Get-Datacenter -Name DC1 | Get-Folder -Name "vm").ID
$pool = Get-View (Get-ResourcePool -Name "Resources").ID
$guestname = [regex]"^([\w]+).vmx"
 
$esxImpl = Get-VMHost -Name 10.91.246.2
$esx = Get-View $esxImpl.ID 
$dsBrowser = Get-View $esx.DatastoreBrowser

foreach($dsImpl in $dsBrowser.Datastore){
  $ds = Get-View $dsImpl
  $vms = @()
  foreach($vmImpl in $ds.Vm){
    $vm = Get-View $vmImpl
    $vms += $vm.Config.Files.VmPathName
  }
  $datastorepath = "[" + $ds.Summary.Name + "]"
  
  $searchspec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
  $searchSpec.matchpattern = "*.vmx"
 
  $taskMoRef = $dsBrowser.SearchDatastoreSubFolders_Task($datastorePath, $searchSpec) 
  $task = Get-View $taskMoRef 
  while ($task.Info.State -eq "running"){$task = Get-View $taskMoRef}
 
  foreach ($file in $task.info.Result){
    $found = $FALSE
    foreach($vmx in $vms){
      if(($file.FolderPath + $file.File[0].Path) -eq $vmx){
        $found = $TRUE
      }
    }
    if (-not $found -and $file.File -ne $null){
	  Write-Host "$vmx is unregistered, registering"
      $vmx = $file.FolderPath + $file.File[0].Path
      $res = $file.File[0].Path -match $guestname
      $folder.RegisterVM_Task($vmx,$matches[1],$FALSE,$pool.MoRef,$null)	
    }
  }
}