' #####################################################################################################
' This script will search the domain for all computer accounts & write the inactive accounts 
' into a CSV file names by the sText variable.
' It will check for inactivity by the pwdLastSet property of the computer account.  It is determined
' as inactive when it hasn't been set in more days than the iDaysOlds variable.
' CSV File will contain:
' 		1) Hostname
'		2) Date password last set
'		3) Type - server/workstation
'
' Log file (Inactive_Computers.Log) will output:
'		1) Date & Time the script was run
'		2) Total number of computer accounts
'		3) Total number of computer accounts that have never logged into the domain
'		4) Total number of disabled computer accounts
'		5) Total number of inactive computer accounts
'
' Change Record
' ====================
' v1.0 - 01/07/2011 - Initial Version
'
' #####################################################################################################

Option Explicit

Const ADS_UF_ACCOUNTDISABLE = &H02

Dim sText			' *** Name of Output File
Dim sScriptPath		' *** Path script is run from
Dim oFSO			' *** FileSystemObject
Dim tsOutputFile	' *** Textstream output file
Dim iDaysOld		' *** Number of days over which the account is deemed inactive
Dim sBase			' *** Base of LDAP query
Dim sFilter			' *** Filter of LDAP query
Dim sQuery			' *** LDAP query text
Dim adoConn			' *** Connection to Active Directory
Dim adoCmd			' *** Command to run with conneciton to AD
Dim oShell			' *** WScript Shell
Dim iBiasKey		' *** Time offset from registry
Dim iBias			' *** Time offset after registry comparison
Dim oRootDSE		' *** Root DSA Specific Entry
Dim sDNSDomainName	' *** distinguishedName, root of the domain
Dim rsComputers		' *** Record set containing results of query
Dim iHigh			' *** High part of the date
Dim iLow			' *** Low part of the date
Dim oDate			' *** Date object
Dim sComputerDN		' *** Computer DN
Dim sComputer		' *** Hostname
Dim sDate			' *** Date password last set
Dim iFlag			' *** User Account Control
Dim sStatus			' *** Account status
Dim sType			' *** Workstation or server
Dim tsLogFile		' *** Textstream log file
Dim iTotal			' *** Total computer accounts
Dim iInactive		' *** Total inactive computer accounts
Dim iDisabled		' *** Total disabled computer accounts
Dim iNever			' *** Total computer accounts that have never logged into the domain

' *** Declare variables
sText = "CSF - Inactive Computers"
iDaysOld = 180

' *** Create a csv file to save results
sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set tsOutputFile = oFSO.CreateTextFile(sScriptPath & sText & ".csv", True)
tsOutputFile.WriteLine "A/C Status" & ", " & "Hostname" & ", " & "Inactive for" & ", " & "Type"
Set tsLogFile = oFSO.OpenTextFile(sScriptPath & "Inactive_Computers.Log", 8, True, 0)

' *** Write log start
With tsLogFile
	.WriteBlankLines(1)
	.WriteLine "============================================================================================"
	.WriteLine "Inactive_Computers.vbs Started at: " & Now()
	.WriteLine "Computer account classed as inactive if password not set in " & iDaysOld & " days"
End With

' *** Set initial totals
iTotal = 0
iInactive = 0
iDisabled = 0
iNever = 0

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

' *** Base of query
sBase = "<LDAP://" & sDNSDomainName & ">"

' *** Filter for query
sFilter = "(objectCategory=computer)"

' *** Set query string
sQuery = sBase & ";" & sFilter & ";distinguishedName, pwdLastSet, Name, userAccountControl, operatingSystem;subtree"

' *** Set the command to the query string
With adoCmd
	.CommandText = sQuery
	.Properties("Page Size") = 100
	.Properties("Timeout") = 30
	.Properties("Cache Results") = False
End With

' *** Execute the command
Set rsComputers = adoCmd.Execute

Do Until rsComputers.EOF
	sComputerDN = rsComputers.Fields("distinguishedName").Value
	sComputer = rsComputers.Fields("Name").Value
	iFlag = rsComputers.Fields("userAccountControl").Value
	iTotal = iTotal + 1
	
	' *** Determine if OS is Server or Workstation Type
	If (InStr(rsComputers.Fields ("operatingSystem").Value, "Server")) Then
		sType = "Server"
	Else
		sType = "Workstation"
	End If
	
	' *** Determine if Account is disabled 
	If (iFlag And ADS_UF_ACCOUNTDISABLE) <> 0 Then
		sStatus = "Disabled"
		iDisabled = iDisabled + 1
	Else
		sStatus = "Enabled"
	End If
	
	' *** Find date that computer last set password (pwdLastSet attribute)
	If (TypeName(rsComputers.Fields("pwdLastSet").Value) = "Object") Then
		Set oDate = rsComputers.Fields("pwdLastSet").Value
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
	Else
		sDate = #1/1/1601#
	End If
	' *** Check sDate against iDaysOld to determine inactivity
	If (DateDiff("d", sDate, Now()) > iDaysOld) Then
		iInactive = iInactive + 1
		If sDate = #1/1/1601# Then
			sDate = "Never"
			iNever = iNever + 1
		End If
		' *** Write details to output file
		tsOutputFile.WriteLine sStatus & ", " & sComputer & ", " & sDate & ", " & sType
	End If
	rsComputers.MoveNext
Loop
With tsLogFile
	.WriteLine "Total number of computer accounts: " & vbtab & vbtab & vbtab & vbtab & vbtab & iTotal
	.WriteLine "Total number of computer accounts never logged into the domain:" & vbtab & vbtab & iNever
	.WriteLine "Total number of computer accounts that are disabled:" & vbtab & vbtab & vbtab & iDisabled
	.WriteLine "Total number of inactive computer accounts:" & vbtab & vbtab & vbtab & vbtab & iInactive
	.WriteLine "============================================================================================"
End With

' *** Clean Up
Set oDate = Nothing
Set oShell = Nothing
Set oFSO = Nothing
Set iTotal = Nothing
Set iNever = Nothing
Set iDisabled = Nothing
Set iInactive  = Nothing
Set tsOutputFile = Nothing
Set adoCmd = Nothing
Set adoConn = Nothing
Set oRootDSE = Nothing
Set rsComputers = Nothing

WScript.Echo "Script Complete"