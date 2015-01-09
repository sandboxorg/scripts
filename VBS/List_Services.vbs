' #####################################################################################################
' This script will search the domain for all computer accounts.
' For any that have an operating system containing 'Server' it will find all service
' that aren't running under:
'		1) Local Service
'		2) Network Service
'		3) System
' It will then write the hostname, the service name, the account the service is running under 
' and the startup type to a CSV file name sText
'
' Change Record
' ====================
' v1.0 - 01/07/2011 - Initial Version
'
' #####################################################################################################

Option Explicit

Dim oFSO			' *** FileSystemObject
Dim tsOutputFile	' *** Output file text stream
Dim sText			' *** Output file name
Dim sScriptPath		' *** Path script is run from
Dim tsTempFile		' *** Temporary file to save hostnames in
Dim adoConn			' *** Active Directory connection
Dim adoCmd			' *** Active Directory connection command
Dim oRootDSE		' *** Root DSA Specific Entry
Dim sDNSDomainName	' *** distinguishedName, root of the domain
Dim sBase			' *** Base of LDAP query
Dim sFilter			' *** LDAP query filter
Dim sQuery			' *** LDAP query string
Dim rsComputers		' *** Record set containing results of query
Dim sOS				' *** Computer operating system 
Dim oShell			' *** Shell object
Dim sComputer		' *** Computer to run command on
Dim oWMI			' *** WMI object
Dim oService		' *** Service object
Dim env				' *** Environment variables
Dim cItems			' *** Collection of items
Dim tsLogFile		' *** Log File
Dim iError			' *** Total number of servers with unknown errors
Dim iAvailable		' *** Total number of unavailable servers
Dim iCount			' *** Count of non-system services
Dim iTotal			' *** Total computers checked


' *** Declare variables
sText = "CSF - Services"

' *** Create a csv file to save results
sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set tsOutputFile = oFSO.CreateTextFile(sScriptPath & sText & ".csv", True)
tsOutputFile.WriteLine "Hostname" & ", " & "Service" & ", " & "Account" & ", " & "Startup Type"
Set tsLogFile = oFSO.OpenTextFile(sScriptPath & "List_Services.Log", 8, True, 0)

' *** Write log start
With tsLogFile
	.WriteBlankLines(1)
	.WriteLine "============================================================================================"
	.WriteLine "List_Services.vbs Started at: " & Now()
	.WriteBlankLines(1)
End With

' *** Set Totals
iError = 0 
iAvailable = 0
iCount = 0
iTotal = 0

' *** Create a temporary file to save computernames in
Set tsTempFile = oFSO.CreateTextFile(sScriptPath & "hostnames.txt", True)

' *** Create and open a connection to Active Directory
Set adoConn = CreateObject("ADODB.Connection")
Set adoCmd = CreateObject("ADODB.Command")
With adoConn
	.Provider = "ADsDSOObject"
	.Open = "Active Directory Provider"
End With

Set adoCmd.ActiveConnection = adoConn

' *** Get the current domain details to query against
Set oRootDSE = GetObject("LDAP://RootDSE")
sDNSDomainName = oRootDSE.Get("DefaultNamingContext")

' *** Base of query
sBase = "<LDAP://" & sDNSDomainName & ">"

' *** Filter for query
sFilter = "(&(objectCategory=computer)(objectClass=computer))"

' *** Set query string
sQuery = sBase & ";" & sFilter & ";name, operatingSystem" & ";subtree"

' *** Set the command to the query string & reduce size of results
With adoCmd
	.CommandText = sQuery
	.Properties("Page Size") = 100
	.Properties("Timeout") = 30
	.Properties("Cache Results") = False
End With

' *** Execute the command
Set rsComputers = adoCmd.Execute

Do Until rsComputers.EOF
	sOS = rsComputers.Fields("operatingSystem")
	If Instr(sOS, "Server") Then
		tsTempFile.WriteLine rsComputers.Fields("name")
	End If
	rsComputers.MoveNext
Loop

' *** Create Shell object
Set oShell = CreateObject("WScript.Shell")
Set env = oShell.Environment("process")

Set tsTempFile = oFSO.OpenTextFile(sScriptPath & "hostnames.txt", 1)

Do While Not tsTempFile.AtEndOfStream
	sComputer = tsTempFile.ReadLine
	' *** Create WMI Service
	On Error Resume Next
	iCount = 0
	Set oWMI = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & sComputer & "\root\cimv2")
	Set cItems = oWMI.ExecQuery("Select * from Win32_Service",,48)
	Select Case Err.Number
		Case 0
			iTotal = iTotal + 1
			For Each oService in cItems
				If (LCase(oService.StartName) <> "localsystem") And (LCase(oService.StartName) <> "nt authority\networkservice") And _
							(LCase(oService.StartName) <> "nt authority\localservice") And _
							(LCase(oService.StartName) <> "nt authority\local service") Then
				tsOutputFile.WriteLine sComputer & ", " & oService.DisplayName & ", " & oService.StartName & ", " & oService.StartMode
				iCount = iCount + 1
				End If
			Next
		Case 462
			tsLogFile.WriteLine sComputer & " - is not available"
			iAvailable = iAvailable + 1
			iCount = iCount + 1
		Case Else
			tsLogFile.WriteLine sComputer & " - " & Err.Description
			iError = iError + 1
			iCount = iCount + 1
	End Select
	On Error GoTo 0
	If iCount = 0 Then
		tsLogFile.WriteLine sComputer & " - All services running under system accounts"
	End If
Loop

With tsLogFile
	.WriteLine "Total number of servers with unknown errors:" & vbtab & vbtab & iError
	.WriteLine "Total number of servers that are unavailable:" & vbtab & vbtab & iAvailable
	.WriteLine "Total number of servers checked:" & vbtab & vbtab & vbtab & iTotal
	.WriteLine "============================================================================================"
End With

Set tsTempFile = oFSO.GetFile(sScriptPath & "hostnames.txt")
tsTempFile.Delete

' *** Clean Up
Set oService = Nothing
Set oShell = Nothing
Set oWMI = Nothing
Set env = Nothing
Set tsOutputFile = Nothing
Set tsTempFile = Nothing
Set tsLogFile = Nothing

WScript.Echo "Script Complete"