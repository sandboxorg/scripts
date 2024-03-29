#===============================================================================
# Script information
#===============================================================================
# NAME: logon
# VERSION: 1.0
# DESCRIPTION: logon script
# AUTHOR: 
# OWNER: 
#-------------------------------------------------------------------------------
 
#===============================================================================
# Change history log
#===============================================================================
# DATE : 
# AUTHOR: 
# Purpose:
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
 
 
#===============================================================================
# Parameters
#===============================================================================
#   By default look for an xml .config file with the same name as the script
#   in the current execution directory
#
# Parameter management examples:
#   param([string] $optional) 
#      Optional string parameter
#   param([string] $optional = "default") 
#      Optional string parameter with default value
#   param([string] $required = $(throw "Required Parameter")) 
#      Required string parameter / throw exception if not provided
#   param([string] $required = $(Read-Host -Prompt "Parameter")) 
#      Required string parameter / prompt user to fill if not provided 
#   param([switch] $switch)
#      Flag type parameter
#-------------------------------------------------------------------------------

param(
    [string] $ConfigFile
    )


#===============================================================================
# Functions
#===============================================================================
# Function Write-Log
# Log a message in log file and on the screen
#-------------------------------------------------------------------------------
function Write-Log {
    param ($Message, $Status = $LogDisplay)   
    trap [Exception] {Write-Host "Critical - Unable to use logging system: " + $_.Exception.Message; Stop }
    trap [Exception] {Write-Host "Critical - Unable to use logging system: "}
	$timestamp = get-date -uformat "%Y%m%d-%T"
    Write-Host "$timestamp " -NoNewline    
    switch($Status) {
        "DISP" { 
            Write-Host -ForegroundColor Green "[OK] " -NoNewline
            }
        "INFO" { 
            Write-Host -ForegroundColor Green "[OK] " -NoNewline
            Add-Content $LogFile "$timestamp [OK] $Message"
            }
        "WARN" { 
            Write-Host -ForegroundColor Yellow "[WARNING] " -NoNewline
            Add-Content $LogFile "$timestamp [WARNING] $Message"
            } 
        "ERROR" { 
            Write-Host -ForegroundColor Red "[ERROR] " -NoNewline
            Add-Content $LogFile "$timestamp [ERROR] $Message"
            } 
         default { 
            Write-Host -ForegroundColor Green "[$Status] " -NoNewline
            Add-Content $LogFile "$timestamp [$Status] $Message"
            }
        }
    Write-Host $Message
    }

#-------------------------------------------------------------------------------
# Function Run
# Execute a command line
#-------------------------------------------------------------------------------
function Run {
    param(
        $CommandLine=$(throw "A command line parameter must be specified"),
        $DisplayOutput = $true, 
        [switch]$DirectOutput,
        [switch]$IgnoreReturnCode
        )
    
    Write-Log "Start executing: $CommandLine" $LogInfo        
    $psi = New-Object System.Diagnostics.ProcessStartInfo ("cmd.exe")
    $psi.WorkingDirectory = "C:\"
    $psi.UseShellExecute = $false
    if ($DirectOutput) {
        $psi.RedirectStandardOutput = $false
        $psi.RedirectStandardError = $false
        $DisplayOutput = $false
        }
    else {
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        }

    $psi.Arguments = "/c $CommandLine"
    
    $process = [System.Diagnostics.Process]::Start($psi) 
    $process.WaitForExit()
    if ($DirectOutput) {
        $stdout = ""
        $stderr = ""
        }
    else {
        $stdout = $process.StandardOutput.ReadToEnd() 
        $stderr = $process.StandardError.ReadToEnd() 
        }
    $returncode = $process.ExitCode

    if ($DisplayOutput) {
        if ($stdout.Length -gt 1) {
            Write-Host $stdout.Trim()
            Add-Content $LogFile $stdout.Trim()
            }
        if ($stderr.Length -gt 1) {
            Write-Host $stderr.Trim()
            Add-Content $LogFile $stderr.Trim()
            }
        }
        
    if (($returncode -eq 0) -or $IgnoreReturnCode) {
        Write-Log "Successfully executed: $CommandLine" $LogInfo
        }
    else {
        Write-Log "Error executing: $CommandLine" $LogError
        }
    }

#-------------------------------------------------------------------------------
# Function ConvertTo-Name
# Convert a SID to the associated NTAccount name
#-------------------------------------------------------------------------------
function ConvertTo-Name($sid,[switch]$FromByte) {
    if($FromByte)
    {
        $ID = New-Object System.Security.Principal.SecurityIdentifier($sid,0)
    }
    else
    {
        $ID = New-Object System.Security.Principal.SecurityIdentifier($sid)
    }
    if($ID)
    {
        $User = $ID.Translate([System.Security.Principal.NTAccount])
        $User.Value
    }
}	


#-------------------------------------------------------------------------------
# Function Get-groupMembership
# Returns group membership from token sid
#-------------------------------------------------------------------------------
function Get-groupMembership {
	Param(
		$DN
		)
	$UserAccount = [ADSI]"LDAP://$DN"
	$UserAccount.GetInfoEx(@("tokengroups"),0)
	$groups = $UserAccount.Get("tokengroups")
	$listgroups = @()
	foreach($group in $groups)
	{
		$GroupName = ConvertTo-Name $group -FromByte		
		$temp = $groupname.split('\')
		$temp = $temp[1]
		$strGrpFilter = "(&(objectCategory=group)(name=$temp))"
		$objGrpSearcher = New-Object System.DirectoryServices.DirectorySearcher
    	$objGrpSearcher.Filter = $strGrpFilter
    	$objGrpPath = $objGrpSearcher.FindOne()
    	If (!($objGrpPath -eq $Null)){		
    		$objGrp = $objGrpPath.GetDirectoryEntry()
    		$grpDN = $objGrp.distinguishedName
			$listgroups += @($grpDN)
		}
	}
	return $listgroups
}


#-------------------------------------------------------------------------------
# Function Get-Membership
# Return 1 if the user "username" is a member of the group "groupname"
#-------------------------------------------------------------------------------	
function Get-Membership {
    param(
		$username,
        $groupname
		)
	#Define filter
    $strFilter = "(&(objectCategory=User)(samAccountName=$username))"
	$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
	$objSearcher.PageSize = 10000
    $objSearcher.Filter = $strFilter
	$objPath = $objSearcher.FindOne()
	$objUser = $objPath.GetDirectoryEntry()
	$DN = $objUser.distinguishedName
	if (($groupname.length) -ne "0" ){
        $strGrpFilter = "(&(objectCategory=group)(name=$groupname))"
    	$objGrpSearcher = New-Object System.DirectoryServices.DirectorySearcher
    	$objGrpSearcher.Filter = $strGrpFilter
    	$objGrpPath = $objGrpSearcher.FindOne()
    	If (!($objGrpPath -eq $Null)){		
    		$objGrp = $objGrpPath.GetDirectoryEntry()
    		$grpDN = $objGrp.distinguishedName
            $listgroups = get-groupMembership $DN
            $d= ($listgroups -contains $grpDN)
    		if ($d){
				$isMember = 1
    			return $isMember
    		}else{
    			$isMember = 0
    			return $isMember
    		}    	
    	    }else{
    			$isMember = 0
    			return $isMember	
    	   }
        }		
}	
	
#===============================================================================
# Script Configuration
#===============================================================================
Set-PSDebug -strict
#-------------------------------------------------------------------------------
# Global variables and const
#-------------------------------------------------------------------------------
$ErrorActionPreference = "SilentlyContinue"
$LogError = "ERROR"
$LogWarning = "WARN"
$LogInfo = "INFO"
$LogDisplay = "DISP"

$user = $env:username

#-------------------------------------------------------------------------------
# Start error trapping
#-------------------------------------------------------------------------------
trap [Exception] { Write-Log $($_.Exception.GetType().FullName + " - " + $_.Exception.Message) $LogError; continue}

#-------------------------------------------------------------------------------
# Load configuration from the config file
#-------------------------------------------------------------------------------
if ($ConfigFile -eq "") { $ConfigFile = $MyInvocation.InvocationName.Replace(".ps1", ".config") }
[XML]$config = Get-Content $ConfigFile


#-------------------------------------------------------------------------------
# Create log file
#-------------------------------------------------------------------------------
$LogFilePath = $env:userprofile+"\AppData\Roaming\Login\"

if (!(test-path $LogFilePath)){
	New-Item $LogFilePath -type directory
}

$LogFile = $env:userprofile+"\AppData\Roaming\Login\Login.log"
Remove-item $LogFile
Write-Log "Used Configuration file: $ConfigFile" $LogInfo 
#-------------------------------------------------------------------------------
# Get drives,scripts and library definition from XML file
#-------------------------------------------------------------------------------
$drives = $config.configuration.map_list.map
$scripts = $config.configuration.ACTION_LIST.ACTION
$libraries = $config.configuration.LIB_LIST.LIB

#===============================================================================
# Script body
#===============================================================================

#===============================================================================
# MAP drives section
#===============================================================================
$shell = New-Object –com Shell.Application
foreach ($drive in $drives)
{
    $drivegroup = $drive.CONDITIONAL_GROUP
    $driveuser = $drive.CONDITIONAL_USER
    $driveletter = $drive.DRIVE_LETTER
	$drivename = $drive.DRIVE_NAME
    $drivepath = $drive.NETWORK_SHARE
	$drivestate = $drive.STATE
    
	[string] $strdrivegroup = $drivegroup
    [StringSplitOptions]$option = "RemoveEmptyEntries"
    
	[string] $struser = $user
    [string] $strdriveuser = $driveuser	
	
	$netdelcmdline = "net use /delete $driveletter /Y"
    $netusecmdline = "net use $driveletter $drivepath"	
	
	#$shell = New-Object –com Shell.Application
	
    $cleandrivegroups = "$strdrivegroup".Split(",", $option)
    $ajoutdrive = 0	
    foreach ($cleandrivegroup in $cleandrivegroups){
		#If the user is a member of one conditional group
        if ((get-membership $user $cleandrivegroup) -and !($ajoutdrive)){
            $ajoutdrive = 1
			run "$netdelcmdline"
			if ($drivestate -eq "1"){
				run "$netusecmdline"
				try
                {
                $shell.NameSpace("$driveletter").Self.Name = $drivename
                }
                catch [Exception]
                {
                }
			}
        }
    }
    
	$cleandriveusers = "$strdriveuser".Split(",", $option)
	foreach ($cleandriveuser in $cleandriveusers){
		$d = $struser.compareto($cleandriveuser) 
		if (( $user -eq $cleandriveuser) -and !($ajoutdrive)){
			$ajoutdrive = 1
			run "$netdelcmdline"
			if ( $drivestate -eq "1"){
				run "$netusecmdline"
				try
                {
                $shell.NameSpace("$driveletter").Self.Name = $drivename
                }
                catch [Exception]
                {
                }
			}
		}
	}
}

#Execute Action

Foreach ($script in $scripts)
{
    $scriptgroups = $script.CONDITIONAL_GROUP
    $scriptuser = $script.CONDITIONAL_USER
	$scriptcmd = $script.cmdline
	$scriptstate = $script.STATE
	
	[string] $strscriptgroups = $scriptgroups
    [StringSplitOptions]$option = "RemoveEmptyEntries"
    	
	[string] $struser = $user
    [string] $strscriptuser = $scriptuser	
	
	$cleanscriptgroups = "$strscriptgroups".Split(",", $option)
	$cleanscriptusers = "$strscriptuser".Split(",", $option)
	
	$execmd = 0
        
	foreach ($cleanscriptgroup in $cleanscriptgroups){
		#If the user is a member of one conditional group
        if ((get-membership $user $cleanscriptgroup) -and !($execmd)-and ($scriptstate -eq "1")){
            $execmd = 1
			run "$scriptcmd"	
        }	    
	}

	foreach ($cleanscriptuser in $cleanscriptusers){
		$d = $struser.compareto($cleanscriptuser) 
		if (( $user -eq $cleanscriptuser)-and !($execmd)-and ($scriptstate -eq "1")){
			$execmd = 1
			run "$scriptcmd"
		}
	}	

}

#Add library
Foreach ($library in $libraries)
{
    $librarygroups = $library.CONDITIONAL_GROUP
    $libraryusers = $library.CONDITIONAL_USER
	$librarystate = $library.STATE
    	
	[string] $strlibrarygroups = $librarygroups
    [StringSplitOptions]$option = "RemoveEmptyEntries"
    	
	[string] $struser = $user
    [string] $strlibraryuser = $libraryusers	
	
	$cleanlibrarygroups = "$strlibrarygroups".Split(",", $option)
	$cleanlibraryusers = "$strlibraryuser".Split(",", $option)
	$addlib = 0
    
	foreach ($cleanlibrarygroup in $cleanlibrarygroups){
        #If the user is a member of one conditional group
        if ((get-membership $user $cleanlibrarygroup) -and !($addlib)){           
            $addlib = 1
			$libraryname = $library.LIB_NAME
			$librarypath = $library.LIB_PATH
			$shlibpathP =(get-location).path+"\"
            $shlibpath =Convert-Path $shlibpathP
			switch ($libraryname)
			{
				"Documents" {
					$libraryroot = "$env:userprofile"+"\AppData\Roaming\Microsoft\Windows\Libraries\Documents.library-ms"
					$removelibrary = "$shlibpath"+"shlib.exe remove $libraryroot $librarypath"
					run "$removelibrary"
					if (($librarystate -eq "1")){
						$addlibrary = "$shlibpath"+"shlib.exe add $libraryroot $librarypath"
						run "$addlibrary"
					}
				}
				"Musique"{
					$libraryroot = "$env:userprofile"+"\AppData\Roaming\Microsoft\Windows\Libraries\Musique.library-ms"
					$removelibrary = "$shlibpath"+"shlib.exe remove $libraryroot $librarypath"
					run "$removelibrary"
					if (($librarystate -eq "1")){
						$addlibrary = "$shlibpath"+"shlib.exe add $libraryroot $librarypath"
						run "$addlibrary"
					}
				}
				"Images"{
					$libraryroot = "$env:userprofile"+"\AppData\Roaming\Microsoft\Windows\Libraries\Images.library-ms"
					$removelibrary = "$shlibpath"+"shlib.exe remove $libraryroot $librarypath"
					run "$removelibrary"
					if (($librarystate -eq "1")){
						$addlibrary = "$shlibpath"+"shlib.exe add $libraryroot $librarypath"
						run "$addlibrary"
					}			
				}
				"Videos"{
					$libraryroot = "$env:userprofile"+"\AppData\Roaming\Microsoft\Windows\Libraries\Videos.library-ms"
					$removelibrary = "$shlibpath"+"shlib.exe remove $libraryroot $librarypath"
					run "$removelibrary"
					if (($librarystate -eq "1")){
						$addlibrary = "$shlibpath"+"shlib.exe add $libraryroot $librarypath"
						run "$addlibrary"
					}
				}
			}
        }	    
	}

	foreach ($cleanlibraryuser in $cleanlibraryusers){
		$d = $struser.compareto($cleanlibraryuser)
		if (( $user -eq $cleanlibraryuser)-and !($addlib)){
            $addlib = 1
			$libraryname = $library.LIB_NAME
			$librarypath = $library.LIB_PATH
            $shlibpathP =(get-location).path+"\"
            $shlibpath =Convert-Path $shlibpathP
			switch ($libraryname)
			{
				"Documents" {
					$libraryroot = "$env:userprofile"+"\AppData\Roaming\Microsoft\Windows\Libraries\Documents.library-ms"
                    $removelibrary = "$shlibpath"+"shlib.exe remove $libraryroot $librarypath"
					run "$removelibrary"
					if (($librarystate -eq "1")){
						$addlibrary = "$shlibpath"+"shlib.exe add $libraryroot $librarypath"
						run "$addlibrary"
					}
				}
				"Musique"{
					$libraryroot = "$env:userprofile"+"\AppData\Roaming\Microsoft\Windows\Libraries\Musique.library-ms"
					$removelibrary = "$shlibpath"+"shlib.exe remove $libraryroot $librarypath"
					run "$removelibrary"
					if (($librarystate -eq "1")){
						$addlibrary = "$shlibpath"+"shlib.exe add $libraryroot $librarypath"
						run "$addlibrary"
					}			
				}
				"Images"{
					$libraryroot = "$env:userprofile"+"\AppData\Roaming\Microsoft\Windows\Libraries\Images.library-ms"
					$removelibrary = "$shlibpath"+"shlib.exe remove $libraryroot $librarypath"
					run "$removelibrary"
					if (($librarystate -eq "1")){
						$addlibrary = "$shlibpath"+"shlib.exe add $libraryroot $librarypath"
						run "$addlibrary"
					}				
				}
				"Videos"{
					$libraryroot = "$env:userprofile"+"\AppData\Roaming\Microsoft\Windows\Libraries\Videos.library-ms"
					$removelibrary = "$shlibpath"+"shlib.exe remove $libraryroot $librarypath"
					run "$removelibrary"
					if (($librarystate -eq "1")){
						$addlibrary = "$shlibpath"+"shlib.exe add $libraryroot $librarypath"
						run "$addlibrary"
					}
				}
			}
        }
	}

}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              