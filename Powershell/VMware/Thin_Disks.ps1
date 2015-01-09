$vmtp = Get-VM
$vmtp += Get-Template
 
foreach($vm in $vmtp | Get-View){
  foreach($dev in $vm.Config.Hardware.Device){
    if(($dev.GetType()).Name -eq "VirtualDisk"){
      if($dev.Backing.ThinProvisioned -eq $true) {
        $vm.Name + "`t" + $dev.Backing.FileName
      }
    }
  }
}