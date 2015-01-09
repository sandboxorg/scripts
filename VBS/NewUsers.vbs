' #####################################################################################################
' Script to create new users imported from a text file - users.txt - located in the same directory
' as the script.
' Text file must be comma separated, with 3 values - firstname, surname, username
' 
' All passwords will be set to 'Password1'
' 
' Log file (NewUsers.Log) will output:
'		1) Date & Time the script was run
'		2) Total number of user accounts Created
'		3) Total number of user accounts that have never logged into the domain
'		4) Total number of disabled user accounts
'		5) Total number of inactive user accounts
'		6) Total number of user accounts that have never changed password
'		7) Total number of user accounts that have password set to never expire
'
' Change Record
' ====================
' v1.0 - 04/11/2011 - Initial Version
'
' #####################################################################################################

Option Explicit

' *** Declare constants - Need to check that these are all needed

Const ADS_SECURE_AUTHENTICATION = 1
Const ADS_SERVER_BIND = 512
Const ADS_UF_PASSWD_NOTREQD = &H20
Const ADS_UF_DONT_EXPIRE_PASSWD = &H10000 
Const ADS_UF_ACCOUNTDISABLE = 2
Const ADS_PROPERTY_APPEND = 3

' *** Declare Variables

Dim sScriptPath		' *** Path that script is run from
Dim oRootDSE		' *** Root DSA Specific Entry
Dim oFSO			' *** FileSystemObject
Dim tsInputFile		' *** Iutput file
Dim sDNSDomainName	' *** DNS root
Dim sDomainConfig	' *** Domain configuration path
Dim sStatus			' *** Account status
Dim sPStatus		' *** Password status
Dim sDescription	' *** Account description
Dim sUser			' *** Username
Dim tsLogFile		' *** TextStream log file
Dim iTotal			' *** Total user accounts
Dim sGroup			' *** Group to add users to
Dim oGroup			' *** Group object
Dim sOu				' *** OU to create users in
Dim oOu				' *** OU to create users in
Dim sTemp 			' *** Temporary String
Dim arUser			' *** Temparary Array with the user details
Dim sFirstName
Dim sLastName
Dim sAMAccountName
Dim sUAC

' *** Set Variables
sOU = "OU=ACS,OU=Admins"
sGroup = "ACS_Admins"
'iDaysold = 180

'*** Create a csv file to save results
sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")

' *** Open log file for appending (if it doesn't already exist it will be created)
Set tsLogFile = oFSO.OpenTextFile(sScriptPath & "NewUsers.log", 8, True, 0)

' *** Write initial section of log file
With tsLogFile
	.WriteBlankLines(1)
	.WriteLine "============================================================================================"
	.WriteLine "NewUsers.vbs Started at: " & Now()
	.WriteBlankLines(1)
End With

'*** Get the current domain details to query against
Set oRootDSE = GetObject("LDAP://RootDSE")
sDNSDomainName = oRootDSE.Get("DefaultNamingContext")
Set oOU = oRootDSE.OpenDSObject("LDAP://" & sOU & "," & sDNSDomainName)

Set tsInputFile = oFSO.OpenTextFile(sScriptPath & "Users.txt", 1)

Do While Not tsInputFile.AtEndOfStream
	sTemp = tsInputFile.ReadLine
	arUser = Split(sTemp,",")

	If UBound(arUser) <> 2 Then
		WScript.Echo "Invalid user entry found"
	Else
		arUser(0) = sFirstName
		arUser(1) = sLastName
		arUser(2) = sAMAccountName
		Set oUser = oOU.Create("user", "CN=" & sFirstName & " " &sLastName)
		oUser.sAMAccountName = "adm" & sAMAccountName
		On Error Resume Next
		oUser.SetInfo
		Select Case Err.Number
			Case 0
			Case -2147019886
				WScript.Echo "User account " & sAMAccountName & "@" & sDNSDomainName & " already exists"
			Case Else
				WScript.Echo Err.Number & " - " & Err.Description
		End Select

		On Error Goto 0
		
		oUser.userPrincipalName = sAMAccountName & "@" & sDNSDomainName
		oUser.displayName = sFirstName & " " & sLastName
		
		oUser.SetPassword = "Password1"
		
		oUser.Put "PwdLastSet", 0
		
		sUAC = oUser.Get("userAccountControl")
		sUAC = sUAC And Not(ADS_UF_ACCOUNTDISABLE + ADS_UF_PASSWD_NOTREQD + ADS_UF_DONT_EXPIRE_PASSWD)
		oUser.Put "userAccountControl", sUAC
		
		oUser.FirstName = sFirstName
		oUser.LastName = sLastName
		
		oUser.SetInfo
		sUser = oUser.ADsPath
		
		' *** These needs to go in the log file
		WScript.Echo "User " & sAMAccountName & "@" & sDNSDomainName & " created"
		
		Set oGroup = oRootDSE.OpenDSObject("LDAP://" & sGroup & "," & sOU & "," & sDNSDomainName)
		oGroup.Add(sUser)
		oGroup.SetInfo
	End If
Loop
		