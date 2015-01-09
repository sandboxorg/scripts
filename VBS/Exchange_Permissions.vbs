' #####################################################################################################
' This script will search AD for all accounts & print the mailbox rights into a CSV file
' 1) Account Status - Enabled or Disabled
' 2) Username
' 3) Display Name
' 4) Users with rights
'
' Change Record
' ====================
' v1.0 - 19/01/2011 - Initial Version
'
' #####################################################################################################

Option Explicit

Const RIGHT_DS_DELETE = &H10000
Const RIGHT_DS_READ = &H20000
Const RIGHT_DS_CHANGE = &H40000
Const RIGHT_DS_TAKE_OWNERSHIP = &H80000
Const RIGHT_DS_MAILBOX_OWNER = &H1
Const RIGHT_DS_SEND_AS = &H2
Const RIGHT_DS_PRIMARY_OWNER = &H4

Const ADS_ACETYPE_ACCESS_ALLOWED = 0
Const ADS_ACETYPE_ACCESS_DENIED = 1
Const ADS_ACEFLAG_INHERIT_ACE = 2
Const ADS_ACEFLAG_INHERIT_ONLY_ACE = 8
Const ADS_ACEFLAG_SUB_NEW = 9

Const ADS_UF_ACCOUNTDISABLE = &H02

Dim sText
Dim sScriptPath
Dim oRootDSE
Dim oFSO
Dim tsOutputFile
Dim sDNSDomainName
Dim sBase
Dim sFilter
Dim sQuery
Dim adoConn
Dim adoCmd
Dim rsUser
Dim oSecurity
Dim dacl
Dim ace
Dim sOtherUser
Dim oUser
Dim oSD
Dim sUser
Dim iFlag
Dim sStatus


' *** Set Variables
' *** sText is the name of the CSV file

sText = "BMSGroup - Exchange Permissions"

'*** Create a csv file to save results

sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set tsOutputFile = oFSO.CreateTextFile(sScriptPath & sText & ".csv", True)
tsOutputFile.WriteLine "A/C Status" & ", " & "Username" & ", " & "Display Name" & _
	", " & "Permissions"

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

' *** Filter for query

sFilter = "(&(objectCategory=person)(objectClass=user)(mail=*)(homeMDB=*))"

' *** Set query string

sQuery = sBase & ";" & sFilter & _
		";AdsPath, sAMAccountName, userAccountControl, name" & ";subtree"

' *** Set the command to the query string
With adoCmd
	.CommandText = sQuery
	.Properties("Page Size") = 100
	.Properties("Timeout") = 30
	.Properties("Cache Results") = False
End With

' *** Execute the command

Set rsUser = adoCmd.Execute


Do Until rsUser.EOF

	Set oUser = GetObject(rsUser.Fields("ADsPath").Value)
	Set oSD = oUser.Get("msExchMailboxSecurityDescriptor")
	Set dacl = oSD.DiscretionaryAcl
	Set ace = CreateObject("AccesscontrolEntry")
	sUser = rsUser.Fields("sAMAccountName").Value
	iFlag = rsUser.Fields("userAccountControl").Value

	If (iFlag And ADS_UF_ACCOUNTDISABLE) <> 0 Then
		sStatus = "Disabled"
	Else
		sStatus = "Enabled"
	End If

	tsOutputFile.Write sStatus & ", " & sUser & ", " & _
		rsUser.fields("Name") & ", "       

	For Each ace in dacl
		
		sOtherUser = ace.Trustee
		tsOutputFile.Write sOtherUser

		If (ace.AceType = ADS_ACETYPE_ACCESS_ALLOWED) Then
			tsOutputFile.Write ":ALLOWED - "
			If (ace.AccessMask = RIGHT_DS_MAILBOX_OWNER) Then
				tsOutputFile.Write "Owner;"
			End If
		
			If (ace.AccessMask And RIGHT_DS_SEND_AS) Then
				tsOutputFile.Write "SendAs;"
			End If

			If (ace.AccessMask And RIGHT_DS_CHANGE) Then
				tsOutputFile.Write "Modify;"
			End If

			If (ace.AccessMask And RIGHT_DS_DELETE) Then
				tsOutputFile.Write "DeleteStorage;"
			End If

			If (ace.AccessMask And RIGHT_DS_READ) Then
				tsOutputFile.Write "Read;"
			End If

			If (ace.AccessMask And RIGHT_DS_PRIMARY_OWNER) Then
				tsOutputFile.Write "Full;"
			End If

			tsOutputFile.Write ", "

		ElseIf (ace.AceType = ADS_ACETYPE_ACCESS_DENIED) Then
			tsOutputFile.Write ":DENIED - "
			If (ace.AccessMask = RIGHT_DS_MAILBOX_OWNER) Then
				tsOutputFile.Write "Owner;"
			End If
		
			If (ace.AccessMask And RIGHT_DS_SEND_AS) Then
				tsOutputFile.Write "Sendas;"
			End If

			If (ace.AccessMask And RIGHT_DS_CHANGE) Then
				tsOutputFile.Write "Modify;"
			End If

			If (ace.AccessMask And RIGHT_DS_DELETE) Then
				tsOutputFile.Write "DeleteStorage;"
			End If

			If (ace.AccessMask And RIGHT_DS_READ) Then
				tsOutputFile.Write "Read;"
			End If

			If (ace.AccessMask And RIGHT_DS_PRIMARY_OWNER) Then
				tsOutputFile.Write "Full;"
			End If
			
			tsOutputFile.Write ", "
		End If
	
	Next
	rsUser.MoveNext
	tsOutputFile.WriteBlankLines(1)

Loop

