' #####################################################################################################
' Install Communicator 
' No real error checking at this time
'
'
' Change Record
' ====================
' v1.0 - 12/11/2012 - Initial Version
'
' #####################################################################################################

Option Explicit

Const HKEY_LOCAL_MACHINE = &H80000002

Dim oFSO			' FileSystemObject
Dim tsLogFile		' Log File
Dim sScriptPath		' Path script is run from
Dim oNTInfo			' WinNTSystemInfo
Dim sHostname		' Hostname
Dim oShell			' Windows Scripting
Dim oReg			' Windows Registry
Dim sOrigRegPath	' Original registry path to search from
Dim sOrigRegValue	' Original registry value to search for
Dim sRegPath		' Registry path
Dim sRegValue		' Registry value
Dim sNewRegPath		' New registry path
Dim sNewRegValue	' New registry value
Dim sValue			' Resultant registry value
Dim errorCheck		' Result of command, no errors = 0
Dim sOSType			' 32 or 64 bit OS
Dim sSetupCmd		' Setup Command String
Dim oSetup			' Run Setup
Dim sResult			' Results of registry query
Dim sTemp			' Temporary variable


sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = CreateObject("WScript.Shell")
Set tsLogFile = oFSO.OpenTextFile(sScriptPath & "\Communicator.log", 8)

Set oNTInfo = CreateObject("WinNTSystemInfo")
sHostname = lcase(oNTInfo.ComputerName)
sRegValue = "Communicator"

' *** Check whether OS is 32 or 64 bit
Set oReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & sHostname & "\root\default:StdRegProv")
sRegPath = "HARDWARE\DESCRIPTION\System\CentralProcessor\0"
sRegValue = "Identifier"

oReg.GetStringValue HKEY_LOCAL_MACHINE,sRegPath,sRegValue,sValue

If (Instr(sValue,"64")) Then
	sOSType = "64"
Elseif (Instr(sValue,"x86")) Then
	sOSType = "32"
End If

' *** Set registry path dependant on OS Type
If sOSType = "64" Then
	sOrigRegPath = "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
Elseif sOSType = "32" Then
	sOrigRegPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
End If
sOrigRegValue = "DisplayName"

Call FindKeyValue(sOrigRegPath,sOrigRegValue)

If (sTemp = "Not Installed") Then
	InstallCommunicator(sTemp)
Elseif (sTemp = "Installed") Then
	tsLogFile.WriteLine sHostname & "," & "Already installed"
End If

' *** Check to see if Communicator is installed
Function FindKeyValue(sRegPath,sRegValue)

Dim arSubkeys		' Registry subkeys
Dim subkey			' Individual subkey

Set oReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & sHostname & "\root\default:StdRegProv")

errorCheck = oReg.EnumKey(HKEY_LOCAL_MACHINE,sRegPath,arSubKeys)

' *** Enumerate subkeys to search for Communicator
If (errorCheck=0 and IsArray(arSubKeys)) Then
	For each subkey In arSubKeys
		sNewRegPath = sRegPath & "\" & subkey
		Call FindKeyValue(sNewRegPath,sOrigRegValue)
	Next
End If

oReg.GetStringValue HKEY_LOCAL_MACHINE,sRegPath,sRegValue,sValue

If (Instr(sValue,"Communicator")) Then
	sResult = "Installed"
	sTemp = sResult
Else
	sResult = "Not Installed"
	If (sTemp = "Installed") Then
	Else
		sTemp = sResult
	End If
End If

End Function

Function InstallCommunicator(sTemp)
	tsLogFile.WriteLine sHostname & "," & "Installed at: " & now()
	sSetupCmd = sScriptPath & "\OFCOMF07.R01-Install.bat"
	oSetup = oShell.Run (sSetupCmd, 0, True)
End Function
