' #####################################################################################################
' This script will search AD for all accounts & print the status of below items into a CSV file
' 1) Account Status - Enabled or Disabled
' 2) Username
' 3) Display Name
' 4) Password Expiry - Never or Policy
' 5) Last Logged on Time
' 6) Password Last Set
' 7) Considered inactive (Last Logged on time older that iDaysOld)
'
' Log file (AccountStatus.Log) will output:
'		1) Date & Time the script was run
'		2) Total number of user accounts
'		3) Total number of user accounts that have never logged into the domain
'		4) Total number of disabled user accounts
'		5) Total number of inactive user accounts
'		6) Total number of user accounts that have never changed password
'		7) Total number of user accounts that have password set to never expire
'
' Change Record
' ====================
' v1.0 - 01/01/2010 - Initial Version
' v1.1 - 13/02/2011 - Added Password Expiry status
' v1.2 - 14/01/2011 - Added Lastlogon & Password Last Set
' v1.3 - 17/01/2011 - Updated Lastlogon to check all DCs
' v1.4 - 01/07/2011 - Change order that items are piped into Output File and added log file for totals
'
' #####################################################################################################


Option Explicit

Const ADS_UF_ACCOUNTDISABLE = &H02
Const ADS_UF_DONT_EXPIRE_PASSWD = &H010000

Dim sScriptPath		' *** Path that script is run from
Dim oRootDSE		' *** Root DSA Specific Entry
Dim oFSO			' *** FileSystemObject
Dim tsOutputFile	' *** Results output file
Dim sDNSDomainName	' *** DNS root
Dim sDomainConfig	' *** Domain configuration path
Dim sStatus			' *** Account status
Dim sPStatus		' *** Password status
Dim sDescription	' *** Account description
Dim sBase			' *** Base of LDAP query
Dim sFilter			' *** Filter for LDAP query
Dim sQuery			' *** Query string
Dim arDescription	' *** Account description array
Dim adoConn			' *** Active Directory connection
Dim adoCmd			' *** Active Directory connection command
Dim rsDCs			' *** Domain Controller Record Set
Dim rsUser			' *** Users Record Set
Dim iFlag			' *** Integer to compare against
Dim oDate			' *** Date object
Dim iHigh			' *** High part of date
Dim iLow			' *** Low part of date
Dim sDate			' *** Date as string
Dim oShell			' *** WScript Shell
Dim iBiasKey		' *** Time offset from registry
Dim iBias			' *** Time offset after registry comparison
Dim k				' *** Count
Dim oDC				' *** Domain Controller object
Dim arDCs()			' *** Domain Controller array
Dim sPDate			' *** Date password changed
Dim sText			' *** Name of CSV file to output to
Dim sLine			' *** Temp string for Account description
Dim sUser			' *** Username
Dim oList			' *** Scripting dictionary
Dim iDaysOld		' *** Number of days over which the account is deemed inactive
Dim tsLogFile		' *** TextStream log file
Dim iTotal			' *** Total user accounts
Dim iInactive		' *** Total inactive user accounts
Dim iDisabled		' *** Total disabled user accounts
Dim iNever			' *** Total user accounts that have never logged into the domain
Dim iPNever			' *** Total user accounts that have never changed password
Dim iPSNever		' *** Total user accounts with password set to not expire

' *** Set Variables
sText = "CSF - Accounts"
iDaysold = 180

'*** Create a csv file to save results
sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set tsOutputFile = oFSO.CreateTextFile(sScriptPath & sText & ".csv", True)
tsOutputFile.WriteLine "A/C Status" & ", " & "Username" & ", " & "Display Name" & _
	", " & "Password Expiry" & ", " & "Last Logged On Time" & ", " & "Password Last Changed" & _
	", " & "Description"

Set oList = CreateObject("Scripting.Dictionary")
oList.CompareMode = vbTextCompare

' *** Open log file for appending (if it doesn't already exist it will be created)
Set tsLogFile = oFSO.OpenTextFile(sScriptPath & "AccountStatus.log", 8, True, 0)

' *** Write initial section of log file
With tsLogFile
	.WriteBlankLines(1)
	.WriteLine "============================================================================================"
	.WriteLine "AccountStatus.vbs Started at: " & Now()
	.WriteLine "Computer account classed as inactive if user not logged in for " & iDaysOld & " days"
	.WriteBlankLines(1)
End With

' *** Set initial totals
iTotal = 0
iInactive = 0
iDisabled = 0
iNever = 0
iPNever = 0
iPSNever = 0

' *** Get local time bias from registry
Set oShell = CreateObject("WScript.Shell")
iBiasKey = oShell.RegRead("HKLM\System\CurrentControlSet\Control\TimeZoneInformation\ActiveTimeBias")
If (UCase(TypeName(iBiasKey)) = "LONG") Then
	iBias = iBiasKey
ElseIf (UCase(TypeName(iBiasKey)) = "VARIANT()") Then
	iBias = 0
	For k = 0 To UBound(iBiasKey)
		iBias = iBias + (iBiasKey(k) * 256^k)
	Next
End If

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
sDomainConfig = oRootDSE.Get("configurationNamingContext")

' *** Search for DCs
' *** Base of query
sBase = "<LDAP://" & sDomainConfig & ">"

' *** Filter for query
sFilter = "(objectClass=nTDSDSA)"

' *** Set query string
sQuery = sBase & ";" & sFilter & ";AdsPath;subtree"

' *** Set the command to the query string
With adoCmd
	.CommandText = sQuery
	.Properties("Page Size") = 100
	.Properties("Timeout") = 30
	.Properties("Cache Results") = False
End With

' *** Execute the command
Set rsDCs = adoCmd.Execute

' *** Enumerate DCs into Array
k = 0
Do Until rsDCs.EOF
	Set oDC = GetObject(GetObject(rsDCs.Fields("AdsPath").Value).Parent)
	ReDim Preserve arDCs(k)
	arDCs(k) = oDC.DNSHostName
	k = k + 1
	rsDCs.MoveNext
Loop

' *** Close Recordset
rsDCs.Close

For k = 0 To UBound(arDCs)
	' *** Base of query
	sBase = "<LDAP://" & arDCs(k) & "/" & sDNSDomainName & ">"

	' *** Filter for query
	sFilter = "(&(objectCategory=person)(objectClass=user))"

	' *** Set query string
	sQuery = sBase & ";" & sFilter & ";sAMAccountName, lastLogon" & ";subtree"
    
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
	
	If (Err.Number <> 0) Then
		On Error GoTo 0		
		WScript.Echo "DC not available: " & arDCs(k)
	Else
		On Error GoTo 0
		Do Until rsUser.EOF
			sUser = rsUser.Fields("sAMAccountName").Value
			On Error Resume Next
			
			Set oDate = rsUser.Fields("lastLogon").Value
			iHigh = oDate.HighPart
			iLow = oDate.LowPart

			If (iLow < 0) Then
				iHigh = iHigh + 1
			End If
	
			If (iHigh = 0) And (iLow = 0) Then
				sDate = #1/1/1601#
			Else
				sDate = #1/1/1601# + (((iHigh * (2 ^ 32)) + iLow)/600000000 - iBias)/1440
			End If

			If sDate = #1/1/1601# Then
				sDate = "Never"
			End If

			If (oList.Exists(sUser) = True) Then
				If (sDate > oList(sUser)) Then
					oList.Item(sUser) = sDate
				End If
			Else
				oList.Add sUser, sDate
			End If
			rsUser.MoveNext
		Loop
	End If
		
Next

' *** Base of query
sBase = "<LDAP://" & sDNSDomainName & ">"

' *** Filter for query
sFilter = "(&(objectCategory=person)(objectClass=user))"

' *** Set query string
sQuery = sBase & ";" & sFilter & _
	";sAMAccountName, userAccountControl, name, description, pwdLastSet" & ";subtree"

' *** Set the command to the query string
With adoCmd
	.CommandText = sQuery
	.Properties("Page Size") = 100
	.Properties("Timeout") = 30
	.Properties("Cache Results") = False
End With
	
' *** Execute the command
Set rsUser = adoCmd.Execute

' *** Loop through the record set putting the fields into the CSV file
Do Until rsUser.EOF
	arDescription = rsUser.Fields("Description").Value
	iFlag = rsUser.Fields("userAccountControl")
	sUser = rsUser.Fields("sAMAccountName")
	iTotal = iTotal + 1
	If IsNull(arDescription) Then
		sDescription = ""
	Else
		For Each sLine In arDescription
			sDescription = sLine
		Next
	End If

	If (iFlag And ADS_UF_DONT_EXPIRE_PASSWD) <> 0 Then
		iPSNever = iPSNever + 1
		sPStatus = "Never"
	Else
		sPStatus = "Policy"
	End If

	If (iFlag And ADS_UF_ACCOUNTDISABLE) <> 0 Then
		iDisabled = iDisabled + 1
		sStatus = "Disabled"
	Else
		sStatus = "Enabled"
	End If
	
	' *** Dates are Integer8 & need to be split into 2
	Set oDate = rsUser.Fields("pwdLastSet").Value
	iHigh = oDate.HighPart
	iLow = oDate.LowPart

	If (iLow < 0) Then
		iHigh = iHigh + 1
	End If
	
	If (iHigh = 0) And (iLow = 0) Then
		iPNever = iPNever + 1
		sPDate = #1/1/1601#
	Else
		sPDate = #1/1/1601# + (((iHigh * (2 ^ 32)) + iLow)/600000000 - iBias)/1440
	End If

	If sPDate = #1/1/1601# Then
		iNever = iNever + 1
		sPDate = "Never"
	End If
        
	tsOutputFile.WriteLine sStatus & ", " & sUser & ", " & _
		rsUser.fields("Name") & ", " & sPStatus & ", " & oList.Item(sUser) & ", " & sPDate & ", " & sDescription
       
       	rsUser.MoveNext
Loop

With tsLogFile
	.WriteLine "Total number of user accounts: " & vbtab & vbtab & vbtab & vbtab & vbtab & iTotal
	.WriteLine "Total number of user accounts never logged into the domain:" & vbtab & iNever
	.WriteLine "Total number of user accounts never changed password:" & vbtab & vbtab & iPNever
	.WriteLine "Total number of user accounts that are disabled:" & vbtab & vbtab & iDisabled
	.WriteLine "Total number of inactive user accounts:" & vbtab & vbtab & vbtab & vbtab & iInactive
	.WriteLine "Total number of user's passwords set to never expire:" & vbtab & vbtab & iPSNever
	.WriteLine "============================================================================================"
End With

' *** Close connections
Set adoConn = Nothing
Set adoCmd = Nothing
Set oRootDSE = Nothing
Set rsUser = Nothing

WScript.Echo "Script Complete"