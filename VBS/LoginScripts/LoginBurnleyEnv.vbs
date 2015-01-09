' #####################################################################################################
' Login script for Aircelle @ Burnley to set Environment Variables
' Global Settings
' ------------------------------------
' Set SNC_LIB for Business Warehouse
'
' Change Record
' ====================
' v1.0 - 09/01/2014 - Initial Version
'
' #####################################################################################################

Option Explicit

Dim sScriptPath		' *** Path script is run from
Dim oShell			' *** WScript Shell
Dim oNetwork		' *** WScript Network
Dim oEnv			' *** Shell Environment

' *** Global objects and strings
sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oShell = CreateObject("WScript.Shell")
Set oNetwork = CreateObject("WScript.Network")
Set oEnv = oShell.Environment("User")

' *** Set SNC_LIB for Business Warehouse
oEnv("SNC_LIB") = "sncgss32.dll"