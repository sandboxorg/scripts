#VM Deployment script by David Chung 8/12/2011
#This script is multithreaded VM deployment script using spreadsheet across multiple vsphere servers.
#
#It will log the result in C:\scripts\log\ folder
#Copy autobuildv2.xls to C:\scripts folder.

# --- Note that our windows standard template has two hard drives and two network (lan and backup) ---
# --- Depending on customer requirement, CPU, RAM, Disk size, and Network VLAN connection changes. ---

# Spreadsheet file should be:
# VM name | Host name | CPU | RAM (GB) | DISK 2 (GB) | DISK 3 (GB) | NIC1 Connection | Template name | DataStore | Notes

#Use following command to launch the script
#./autobuild [spreadsheetname]


param( [string] $file)

#Update User ID and Password
$user = 'username'
$password = 'password'

if ($file -eq ""){
    Write-Host
    Write-Host "Please specify spreadsheet file name eg...."
    Write-Host "./autobuildv2.ps1 spreadsheetname.xls" -ForegroundColor yellow
    Write-Host ""
    Write-Host ""
    exit
}
# Replace with your virtual center name
$v1 = 'labvirutalcenter'
$v2 = 'testvirtualcenter'
$v3 = 'productionvirtualcenter'
$v4 = 'drvirtualcenter'

$dt = Get-Date -Format d

#Connect to VI server using saved credentials

#$credlb = Get-VICredentialStoreItem -Host $v1 -File C:\labcredential.xml
#Connect-VIServer $credlb.Host -User $credlb.User -Password $credlb.Password

#$credpd = Get-VICredentialStoreItem -Host $v3 -File C:\pdcredential.xml
#Connect-VIServer $credpd.Host -User $credpd.User -Password $credpd.Password

#$credts = Get-VICredentialStoreItem -Host $v2 -File C:\tscredential.xml
#Connect-VIServer $credts.Host -User $credts.User -Password $credts.Password

#$creddn = Get-VICredentialStoreItem -Host $v4 -File C:\dncredential.xml
#Connect-VIServer $creddn.Host -User $creddn.User -Password $creddn.Password

#open excel and read values
$xls = new-object -com Excel.Application
$path = "C:\scripts\" + $file
$xls.Workbooks.Open($path) | Out-Null

# Removes any existing jobs
Remove-Job *

# Starts from Row 6 on the spreadsheet
$Row = 6

# Loop starts
for ($name -ne $null)
{
    $name = $xls.Cells.Item($Row,1).Value()
    $vhost = $xls.Cells.Item($Row,2).Value()
    $cpu = $xls.Cells.Item($Row,3).Value()
    $memgb = $xls.Cells.Item($Row,4).Value()
    $dgb = $xls.Cells.Item($Row,5).Value()
    $dgb2 = $xls.Cells.Item($Row,6).Value()
    $net = $xls.Cells.Item($Row,7).Value()
    $temp = $xls.Cells.Item($Row,8).Value()
    $nfs = $xls.Cells.Item($Row,9).Value()
    $desc = $xls.Cells.Item($Row,10).Value()
    $vmdisk = $dgb * 1048576
    $vmdisk2 = $dgb2 * 1048576
    $memmb = $memgb * 1024
    $cp = $Row - 6

# End of the loop when there is no data in the row.
    if ($name -eq $null) 
    { 
        Write-Host ""
        Write-Host ""
        Write-Host "(" $cp ") VM Build in progress.  Please check virtual center for detail." -ForegroundColor Magenta
        Write-Host "The script will end when ALL VMs are completed." -ForegroundColor Magenta
        
        # Waits until all jobs are finished
        while ((Get-Job | where {$_.State -eq "Running"}).getType -ne $null)     
        {     
        Sleep -Seconds 10     
        } 
        
        # Stops Excel process
        Stop-Process -Name "Excel"
        Write-Host ""
        
        # Writes Jobs in to log file
        $Date = Get-Date
        $logfile = "C:\scripts\log\autobuild" + "_" + $Date.Day + "-" + $Date.Month + "-" + $Date.Year + ".txt"
        if (-not (test-path c:\scripts\log\))
            {
            MD c:\scripts\log | Out-Null
            }           
        Receive-Job * | Out-File -Encoding ASCII -FilePath $logfile -Append
        Remove-Job *
        
        Write-Host "Automated VM build is completed." -ForegroundColor Yellow
        Write-Host ""
        Invoke-Item $logfile
        exit
    }
    
            
    # Select the correct customization script
    if ($temp -eq "Win2K3-32")
    {
    # Customization script name
        $cust = "Win2003_32bit"
    }
    elseif ($temp -eq "Win2K3-64")
    {
    # Customization script name
        $cust = "Win2003_64bit"
    }
    
    elseif ($temp -eq "Win2K8R2")
    {
    # Customization script name
        $cust = "Win2008"
    }
            
    #if no customization script is selected, break out of the script
    else
    {
        write "Your Guest Customizations are wrong"
        break
    }
    
#Select Vsphere server name based on ESX host name provided
    if ($vhost -like "ESXLAB*")
    {
        $v = $v1
    }
    
    elseif ($vhost -like "ESXTST*")
    {
        $v = $v2
    }
    
    elseif ($vhost -like "ESXPRD*")
    {
        $v = $v3
    }
    
    elseif ($vhost -like "ESXDR*")
    {
        $v = $v4
    }
    
    #if incorrect host names are selected
    else
    {
        write "Please input correct host name"
        break
    }
    
    # Launch Multi-threaded job (VM build and configure)
    $job = 
    {
    $in = $input.'<>4__this'.read(); 
    
    Add-PSSnapin 'vmware.vimautomation.core'
    
    $vmdisk = $in[5] * 1048576
    $vmdisk2 = $in[6] * 1048576
    $memmb = $in[4]* 1024
    
    #VM note (description, deployed by: username, and build date)
    $onwer = Get-Acl
    $deployed = $onwer.owner
    $note = $in[10] + '  |  Deployed by:' + $deployed + '  |  Created:' + $in[13]
    
    #Connect to VI server
    Connect-VIServer $in[11] -User $in[14] -Password $in[15]
    
    #Build VM and configure
    New-VM -Server $in[11] -vmhost $in[2] -Name $in[1] -Template $in[8] -Datastore $in[9] -DiskStorageFormat thin -OSCustomizationSpec $in[12] -Location "Discovered virtual machine" -Description $note
    Set-VM -Server $in[11] -vm $in[1] -Numcpu $in[3] -MemoryMB $memmb -RunAsync -Confirm:$false
    $disk = Get-VM $in[1] | Get-HardDisk | ? {$_.Name -eq "Hard disk 2"}
    Set-HardDisk -harddisk $disk -CapacityKB $vmdisk -Confirm:$false
    if ($in[6] -gt 0)
        {
        New-HardDisk -Server $in[11] -VM $in[1] -CapacityKB $vmdisk2 -Confirm:$false
        }
    $vmnet = Get-VM $in[1] | Get-NetworkAdapter | where { $_.Name -eq "Network Adapter 1" } 
    $vmnet | Set-NetworkAdapter -NetworkName $in[7] -StartConnected:$true -Confirm:$false
    }
    
    # pass variables in to jobs
    $jobspec=@()
    $jobSpec += $job
    $jobspec += $name
    $jobspec += $vhost 
    $jobspec += $cpu 
    $jobspec += $memgb
    $jobspec += $dgb 
    $jobspec += $dgb2
    $jobspec += $net 
    $jobspec += $temp
    $jobspec += $nfs
    $jobspec += $desc
    $jobspec += $v
    $jobspec += $cust
    $jobspec += $dt
    $jobspec += $user
    $jobspec += $password
    
    #start the job    
    Start-Job -InputObject $jobspec -ScriptBlock $jobspec[0]
    
    Write-Host ""
    Write-Host $name " VM is being deployed on " $v -BackgroundColor Green -ForegroundColor Black
    Write-host ""
    
    
    $Row++
}


     