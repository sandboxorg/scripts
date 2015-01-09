' #####################################################################################################
' Will search AD for all mailboxes that are disabled and migrate to a specified storage group
'
' No Log file as yet
' No error checking as yet
'
' Change Record
' ====================
' v1.0 - 16/04/2012 - Initial Version
'
' #####################################################################################################

' !!!SCRIPT INCOMPLETE!!!

Option Explicit

Const ADS_UF_ACCOUNTDISABLE = &H02

Dim sScriptPath		' *** Path that script is run from
Dim oRootDSE		' *** Root DSA Specific Entry
Dim oFSO			' *** FileSystemObject
Dim sDNSDomainName	' *** DNS root
Dim sStatus			' *** Account status
Dim sBase			' *** Base of LDAP query
Dim sFilter			' *** Filter for LDAP query
Dim sQuery			' *** Query string
Dim adoConn			' *** Active Directory connection
Dim adoCmd			' *** Active Directory connection command
Dim rsUser			' *** Users Record Set
Dim iFlag			' *** Integer for comparison
Dim sMDB			' *** Home Mailbox Server
Dim sUser			' *** Username

sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")

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
sFilter = "(&(objectCategory=person)(objectClass=user))"

' *** Set query string
sQuery = sBase & ";" & sFilter & ";sAMAccountName, userAccountControl, homeMDB" & ";subtree"
    
' *** Set the command to the query string
With adoCmd
	.CommandText = sQuery
	.Properties("Page Size") = 100
	.Properties("Timeout") = 30
	.Properties("Cache Results") = False
End With
	
' *** Execute the command
On Error Resume Next
Set rsUser = adoCmd.Execute

' *** Loop through the record set putting the fields into the CSV file
Do Until rsUser.EOF
	sUser = rssUser.Fields("sAMAccountName")
	iFlag = rsUser.Fields("userAccountControl")
	sMDB = rsUser.Fields("homeMDB")
	If (iFlag And ADS_UF_ACCOUNTDISABLE) <> 0 Then
		If (InStr(1,sMDB,"EXCH-CLUSTER",vbTextCompare)) Then
			WScript.Echo sMDB
		End If
	End If
	rsUser.MoveNext
Loop

' *** Clean Up
Set adoConn = Nothing
Set adoCmd = Nothing
Set oRootDSE = Nothing
Set rsUser = Nothing