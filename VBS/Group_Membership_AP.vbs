' #####################################################################################################
' This script will search the domain for all computer accounts.
' For any that have an operating system containing 'Server' it will enumerate the local groups
' contained within the input file specified. 	
'
'
' Log file (Group_Membership_Local.Log) will output:
'		1) Date & Time the script was run
'		2) Computers that are not contactable
'		3) Groups that are not present on each computer	
'
' Change Record
' ====================
' v1.0 - 01/07/2011 - Initial Version
' v1.1 - 08/07/2011 - Added input file to check multiple groups
' v1.2 - 11/07/2011 - Added Check to see if group is present
'
' #####################################################################################################

Option Explicit

Dim oFSO			' *** FileSystemObject
Dim tsOutputFile	' *** Output file text stream
Dim sText			' *** Output file name
Dim sScriptPath		' *** Path script is run from
Dim tsTempFile		' *** Temporary file to save hostnames in
Dim tsLogFile		' *** Log file
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
Dim oGroup			' *** Group object
Dim oUser			' *** User object
Dim tsInputFile		' *** Input file containing groups to search
Dim sGroup			' *** Group to enumerate
Dim sNGroup			' *** Nested Group to enumerate

If (WScript.Arguments.Count <> 2) Then
	WScript.Echo "Usage - cscript Group_Membership_Local.vbs outputfilename inputfilename"
	WScript.Echo "For Example:"
	WScript.Echo "cscript Group_Membership_Local.vbs localaccounts groups"
	WScript.Quit
End If

sText = WScript.Arguments (0)

' *** Create a csv file to save results
sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set tsOutputFile = oFSO.CreateTextFile(sScriptPath & sText & ".csv", True)
tsOutputFile.WriteLine "Hostname" & "," & "Members" & "," & "Type"

' *** Create a temporary file to save computernames in
Set tsTempFile = oFSO.CreateTextFile(sScriptPath & "hostnames.txt", True)

Set tsLogFile = oFSO.OpenTextFile(sScriptPath & "Group_Membership_Local.Log", 8, True, 0)

' *** Write log start
With tsLogFile
	.WriteBlankLines(1)
	.WriteLine "============================================================================================"
	.WriteLine "Group_Membership_Local.vbs Started at: " & Now()
	.WriteBlankLines(1)
End With

'#########################################################
' *** Set Totals
'iError = 0 
'iAvailable = 0
'iCount = 0
'iTotal = 0
'#########################################################

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

' *** Reset temp file to read mode
Set tsTempFile = oFSO.OpenTextFile(sScriptPath & "hostnames.txt", 1)

Do While Not tsTempFile.AtEndOfStream
	sComputer = tsTempFile.ReadLine
	' *** Set the input file
	Set tsInputFile = oFSO.OpenTextFile(sScriptPath & WScript.Arguments(1) & ".txt", 1)
	Do While Not tsInputFile.AtEndOfStream
		sGroup = tsInputFile.ReadLine
		On Error Resume Next
		Set oGroup = GetObject("WinNT://" & sComputer & "/" & sGroup & ", group")
		Select Case Err.Number
		Case 0
			On Error Goto 0
			tsOutputFile.WriteLine sComputer & "," & sGroup
			For Each oUser in oGroup.Members
				If (lcase(oUser.Class) = "group") Then
					tsOutputFile.WriteLine "," & oUser.Name & "," & "Group"
					sNGroup = oUser.Name
					Call GroupMembership(sNGroup)
				ElseIF (lcase(oUser.Class) = "user") Then
					tsOutputFile.WriteLine "," & oUser.Name & "," & "User"
				End If
			Next
		Case -2147024843
			On Error Goto 0
			tsLogFile.WriteLine sComputer & " - " & "Not contactable"
			Exit Do
		Case -2147022676
			On Error Goto 0
			tsLogFile.WriteLine sComputer & ", " & sGroup & " - " & "Group not present"
		Case Else
			On Error Goto 0
			tsLogFile.WriteLine sComputer & ", " & sGroup & " - " & Err.Description
		End Select
	Loop
	tsInputFile.Close
Loop

With tsLogFile
	.WriteLine "Script finished at: " & Now()
	.WriteLine "============================================================================================"
End With


Set tsTempFile = oFSO.GetFile(sScriptPath & "hostnames.txt")
tsTempFile.Delete

Sub GroupMembership(ByVal sGroup)
	
	Dim rsGroup			' *** Group RecordSet
	Dim sDN				' *** Member distinguished name
	Dim sFilter			' *** Filter for LDAP
	Dim sQuery			' *** Query for LDAP
	Dim oMember			' *** Group member object
	
	' *** Filter for query
	sFilter = "(&(objectCategory=group)(ObjectClass=group)(sAMAccountName=" & sGroup & "))"

	' *** Set query string
	sQuery = sBase & ";" & sFilter & ";member;subtree"

	' *** Set the command to the query string
	With adoCmd
		.CommandText = sQuery
		.Properties("Page Size") = 100
		.Properties("Timeout") = 30
		.Properties("Cache Results") = False
	End With

	' *** Execute the command
	Set rsGroup = adoCmd.Execute
	
	' *** Loop through recordset, outputting users & groups to outputfil
	' *** Call subroutine recursively to get all nested users
	Do Until rsGroup.EOF
		For Each sDN in rsGroup.Fields("member").Value
			sDN = Replace(sDN,"/","\/")
			Set oMember = GetObject("LDAP://" & sDN)
			If (lcase(oMember.Class) = "user") Then
				tsOutputFile.WriteLine "User," & oMember.sAMAccountName & "," & oMember.displayName & "," & sGroup
			ElseIf (lcase(oMember.Class) = "group") Then
				tsOutputFile.WriteLine "Group," & oMember.sAMAccountName & "," & oMember.displayName & "," & sGroup
				Call GroupMembership(oMember.sAMAccountName)
			End If
		Next
		rsGroup.MoveNext
	Loop
	rsGroup.Close
	' *** Clean Up
	Set rsGroup = Nothing
	Set sDN = Nothing
	Set oMember = Nothing
	
End Sub


' *** Clean Up
Set tsOutputFile = Nothing
Set tsTempFile = Nothing
Set tsInputFile = Nothing

WScript.Echo "Script Complete"