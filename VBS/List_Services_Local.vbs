' #####################################################################################################
' This script will list the local machines services that aren't running under:
'		1) Local Service
'		2) Network Service
'		3) System
' It will then write the hostname, the service name, the account the service is running under 
' and the startup type to a CSV file named by the computer's hostname
'
' Change Record
' ====================
' v1.0 - 05/07/2011 - Initial Version
'
' #####################################################################################################

Option Explicit

Dim oFSO			' *** FileSystemObject
Dim tsOutputFile	' *** Output file text stream
Dim sScriptPath		' *** Path script is run from
Dim oShell			' *** Shell object
Dim sComputer		' *** Computer to run command on
Dim oWMI			' *** WMI object
Dim oService		' *** Service object
Dim env				' *** Environment variables
Dim cItems			' *** Collection of items
Dim oNTInfo			' *** Local machine NT Information
Dim sHostname		' *** Local hostname

' *** Declare variables
sComputer = "."

' *** Get local machine hostname
Set oNTInfo = CreateObject("WinNTSystemInfo")
sHostname = oNTInfo.ComputerName

' *** Create a csv file to save results
sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set tsOutputFile = oFSO.CreateTextFile(sScriptPath & sHostname & ".csv", True)
tsOutputFile.WriteLine "Hostname" & ", " & "Service" & ", " & "Account" & ", " & "Startup Type"

' *** Create Shell object
Set oShell = CreateObject("WScript.Shell")
Set env = oShell.Environment("process")

' *** Create WMI Service
Set oWMI = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & sComputer & "\root\cimv2")
Set cItems = oWMI.ExecQuery("Select * from Win32_Service",,48)
For Each oService in cItems
	If (LCase(oService.StartName) <> "localsystem") And (LCase(oService.StartName) <> "nt authority\networkservice") And _
							(LCase(oService.StartName) <> "nt authority\localservice") And _
							(LCase(oService.StartName) <> "nt authority\local service") Then
	tsOutputFile.WriteLine sHostname & ", " & oService.DisplayName & ", " & oService.StartName & ", " & oService.StartMode
	End If
Next

' *** Clean Up
Set oService = Nothing
Set oShell = Nothing
Set oWMI = Nothing
Set env = Nothing
Set tsOutputFile = Nothing

WScript.Echo "Script Complete"