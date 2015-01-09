' #####################################################################################################
' Script to update risklink.exe.config line with the correct hostname.  No error checking at this time
'
'
' Change Record
' ====================
' v1.0 - 01/12/2011 - Initial Version
'
' #####################################################################################################

Option Explicit

Dim oFSO			' FileSystemObject
Dim sLines			' Line to be read
Dim tsFile			' Config File
Dim sScriptPath		' Path script is run from
Dim oNTInfo			' WinNTSystemInfo
Dim sHostname		' Hostname
Dim i				' Random count integer
Dim sReplace		' Replaced text for file

sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set tsFile = oFSO.OpenTextFile("C:\Program Files\RMS\RiskLink\Bin64\RiskLink.exe.config", 1)

Set oNTInfo = CreateObject("WinNTSystemInfo")
sHostname = lcase(oNTInfo.ComputerName)

sLines = tsFile.ReadAll
tsFile.Close
sReplace = Replace(sLines, "bms-rms-gold", sHostname, 1, -1, vbTextCompare)

Set tsFile = oFSO.OpenTextFile("C:\Program Files\RMS\RiskLink\Bin64\RiskLink.exe.config", 2)
tsFile.WriteLine sReplace
tsFile.Close