' #####################################################################################################
' This script will enumerate all members of the group specified in sGroup, including nested groups.
' It will output to a CSV file that will contain the username & the group name of any nested groups.
' The output file is specified by the variable sText
'
'
' Log file (Group_Membership.Log) will output:
'		1) Date & Time the script was run
'		2) The name of the group searched
'		3) Total number of nested groups
'		4) Total number of users
'
' Change Record
' ====================
' v1.0 - 04/07/2011 - Initial Version
'
' #####################################################################################################

Option Explicit

Dim sText			' *** Name of output file
Dim oFSO			' *** FileSystemObject
Dim sScriptPath		' *** Path script is run from
Dim tsOutputFile	' *** TextStream output file
Dim tsLogFile		' *** TextStream log file
Dim adoConn			' *** AD Connection
Dim adoCmd			' *** AD Command
Dim oRootDSE		' *** Root Directory Service Entry
Dim sDNSDomainName	' *** Root Domain Name
Dim sBase			' *** Base of LDAP query
Dim iGroups			' *** Total number of nested groups
Dim iUsers			' *** Total number of users
Dim sGroup			' *** Group String

' *** Set Variables
sText = "Anxmgmt - Group Membership"
sGroup = "Administrators"

' *** Create a CSV file to save results
Set oFSO = CreateObject("Scripting.FileSystemObject")
sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set tsOutputFile = oFSO.CreateTextFile(sScriptPath & sText & ".csv", True)
tsOutputFile.WriteLine "A/C Type" & "," & "Username" & "," & "Name" & "," & "Membership From"
Set tsLogFile = oFSO.OpenTextFile(sScriptPath & "Group_Membership_Domain.Log", 8, True, 0)

' *** Write log start
With tsLogFile
	.WriteBlankLines(1)
	.WriteLine "============================================================================================"
	.WriteLine "Group_Membership_Domain.vbs Started at: " & Now()
	.WriteLine "Group searched: " & sGroup
	.WriteBlankLines(1)
End With

' *** Set initial totals
iGroups = 0
iUsers = 0

' *** Create and open connection
Set adoConn = CreateObject("ADODB.Connection")
Set adoCmd = CreateObject("ADODB.Command")
With adoConn
	.Provider = "ADsDSOObject"
	.Open "Active Directory Provider"
End With

Set adoCmd.ActiveConnection = adoConn

'*** Get the current domain details to query against
Set oRootDSE = GetObject("LDAP://RootDSE")
sDNSDomainName = oRootDSE.Get("DefaultNamingContext")

' *** Base of query
sBase = "<LDAP://" & sDNSDomainName & ">"

Call GroupMembership(sGroup)

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
				iUsers = iUsers + 1
			ElseIf (lcase(oMember.Class) = "group") Then
				tsOutputFile.WriteLine "Group," & oMember.sAMAccountName & "," & oMember.displayName & "," & sGroup
				iGroups = iGroups + 1
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

With tsLogFile
	.WriteLine "Total number of users:" & vbtab & vbtab & vbtab & iUsers
	.WriteLine "Total number of nested groups:" & vbtab & vbtab & iGroups
	.WriteLine "============================================================================================"
End With

' *** Clean Up
Set oFSO = Nothing
Set tsOutputFile = Nothing
Set tsLogFile = Nothing
Set iUsers = Nothing
Set iGroups = Nothing
Set adoConn = Nothing
Set adoCmd  = Nothing
Set oRootDSE = Nothing

WScript.Echo "Script Complete"