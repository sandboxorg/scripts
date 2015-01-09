' #####################################################################################################
' Script to update robot.cfg line with the correct IP by reading from a CSV.  
' No error checking at this time
'
'
' Change Record
' ====================
' v1.0 - 12/12/2011 - Initial Version
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
Dim oList			' Scripting Dictionary
Dim tsHostFile		' File containing hostnames & IPs
Dim sTemp			' Temp String
Dim arTemp			' Temp Array
Dim oShell			' Windows Scripting
Dim sSetupCmd		' Setup Command String
Dim oSetup			' Run Setup


sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = CreateObject("WScript.Shell")
Set tsFile = oFSO.OpenTextFile(sScriptPath & "\robot.iss", 1)

Set oList = CreateObject("Scripting.Dictionary")
oList.CompareMode = vbTextCompare

Set tsHostFile = oFSO.OpenTextFile(sScriptPath & "\hostname_ip.csv", 1)

Do Until tsHostFile.AtEndofStream
	sTemp = tsHostFile.ReadLine
	arTemp = Split(sTemp, ",")
	oList.Add arTemp(0), arTemp(1)
	WScript.Echo "arTemp(0) - " & arTemp(0)
	WScript.Echo "arTemp(1) - " & arTemp(1)
Loop

Set oNTInfo = CreateObject("WinNTSystemInfo")
sHostname = lcase(oNTInfo.ComputerName)

sLines = tsFile.ReadAll
tsFile.Close
sReplace = Replace(sLines, "Automatic", oList.Item(sHostname), 1, -1, vbTextCompare)
WScript.Echo oList.Item(sHostname)

Set tsFile = oFSO.OpenTextFile(sScriptPath & "\robot.iss", 2)
tsFile.WriteLine sReplace
tsFile.Close

sSetupCmd = sScriptPath & "\setup.exe -f1" & sScriptPath & "\robot.iss -s -SMS"
oSetup = oShell.Run (sSetupCmd, 0, True)