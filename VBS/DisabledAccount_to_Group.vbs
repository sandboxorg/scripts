' #####################################################################################################
' This script will search AD for all account that match the below criteria
' then add them to the specified AD group & write the list of accounts added to a CSV file
'  
' 
' Criteria:
' 1) Account Disabled
' 2) Account has a mail attribute (Email address)
' 3) Account has a homeMDB attribute (Database containing it's mailbox)
' 4) Account is NOT a System Mailbox
' 5) Account's Exchange Mailbox is Disabled
' 
' Change Record
' ====================
' v1.0 - 14/01/2011 - Initial Version
' v1.1 - 17/01/2011 - Added error check to check if user is already a member of group
'
' #####################################################################################################


Option Explicit

Const ADS_UF_ACCOUNTDISABLE = &H02

Dim sScriptPath
Dim oRootDSE
Dim oFSO
Dim tsOutputFile
Dim sDNSDomainName
Dim sStatus
Dim sBase
Dim sFilter
Dim sQuery
Dim adoConn
Dim adoCmd
Dim rsUser
Dim sGroup
Dim sGroupOU
Dim iFlag
Dim sUser
Dim oGroup
Dim oUser
Dim sText
Dim sGroupStatus


' *** Set Variables
' *** sGroup is group to add accounts to
' *** sGroupOU is the OU that contains the Group
' *** sText is the name of the CSV file

sGroup = "CN=EV_Archive_All"
sGroupOU = "OU=EXCHANGE,OU=GROUPS,OU=BMS"
sText = "BMSGroup - Disabled Accounts"

'*** Create a CSV file to save results

sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set tsOutputFile = oFSO.CreateTextFile(sScriptPath & sText & ".csv", True)
tsOutputFile.WriteLine "A/C Status" & ", " & "Username" & ", " & "Display Name" & ", " & "Group Status"


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

sFilter = "(&(objectCategory=person)(objectClass=user)(mail=*)(homeMDB=*)(!Name=SystemMailbox*)(msExchUserAccountControl=2))"

' *** Set query string

sQuery = sBase & ";" & sFilter & _
	";distinguishedName, sAMAccountName, userAccountControl, name" & ";subtree"
    
' *** Set the command to the query string

With adoCmd
	.CommandText = sQuery
	.Properties("Page Size") = 100
	.Properties("Timeout") = 30
	.Properties("Cache Results") = False
End With

' *** Execute the command

Set rsUser = adoCmd.Execute

' *** Loop through the record set to find disabled accounts

Do Until rsUser.EOF

	iFlag = rsUser.Fields("userAccountControl")
	sUser = rsUser.Fields("distinguishedName") 

	If (iFlag And ADS_UF_ACCOUNTDISABLE) <> 0 Then
		sStatus = "Disabled"
	Else
		sStatus = "Enabled"
	End If

	' *** Cancel out any "/" with escape character "\"

	sUser = Replace(sUser, "/", "\/")
	
	' *** If AD account is disabled & Exchange account is disabled then add user to group
	On Error Resume Next

	If sStatus = "Disabled" Then

		Set oGroup = GetObject("LDAP://" & sGroup & "," & sGroupOU & "," & sDNSDomainName)
		Set oUser = GetObject("LDAP://" & sUser)
		oGroup.Add(oUser.ADsPath)
		oGroup.SetInfo

		Select Case Err.Number
			Case 0
				sGroupStatus = "Added to group"
			Case -2147019886
				sGroupStatus = "Already a member"
			Case Else
				sGroupStatus = Err.Number & " - " & Err.Description
		End Select

		tsOutputFile.WriteLine sStatus & ", " & rsUser.Fields("sAMAccountName") & ", " & _
			rsUser.fields("Name") & ", " & sGroupStatus

	
	End If

	On Error GoTo 0

	rsUser.MoveNext
Loop

    
' *** Close connections

Set adoConn = Nothing
Set adoCmd = Nothing
Set oRootDSE = Nothing
Set rsUser = Nothing

WScript.Echo "Script Complete"