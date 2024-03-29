<#
.SYNOPSIS
Install-GFIAA installs GFI Archive Assistant
.DESCRIPTION
Install-GFIAA installs GFI Archive Assistant into the current users profile.  No parameters are required.
.EXAMPLE
Install-GFIAA
.VERSION
1.0
#>

$regpath = "HKCU:\Software\Microsoft\Office\Outlook\Addins\MArc.Outlook.Addon.AddinModule"
$remotepath = "Microsoft.PowerShell.Core\FileSystem::\\blsrutl01\scripts$\Installs\GFI\ArchiveAssistant\MailArchiverAddon\"
$username = [Environment]::UserName
$localpath = "c:\users\$username\AppData\Local\GFI\MailArchiverAddon\"
$regcmd = "c:\users\$username\AppData\Local\GFI\MailArchiverAddon\adxregistrator.exe /install=MARC.Outlook.Addon.dll /privileges=user"

If(-not(Test-Path -Path $regpath))
  {
  Copy-Item $remotepath -Destination $localpath -Recurse
  Invoke-Expression $regcmd
  }

If((Get-ItemProperty -Path $regpath).LoadBehavior -ne 3)
  {
  If(-not(Test-Path -Path $localpath\MailArchiverAddon))
    {
    Copy-Item $remotepath -Destination $localpath -Recurse
    Invoke-Expression $regcmd
    }
  Else
    {
    Invoke-Expression $regcmd
    }
  }