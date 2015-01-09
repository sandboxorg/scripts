Option Explicit

Const ADS_SECURE_AUTHENTICATION = 1
Const ADS_SERVER_BIND = 512
Const ADS_UF_PASSWD_NOTREQD = &H20
Const ADS_UF_DONT_EXPIRE_PASSWD = &H10000 
Const ADS_UF_ACCOUNTDISABLE = 2
Const ADS_PROPERTY_APPEND = 3

Dim sScriptPath
Dim oRootDSE
Dim objContainer
Dim objGroup
Dim objFSO
Dim arDomain
Dim tsInputFileDomain
Dim sOUADsPath
Dim sDNSDomainName
Dim sTemp


sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set tsInputFileDomain = objFSO.OpenTextFile(sScriptPath & "Domain.txt", 1)

' *** Get Entries from the domain input file & pipe into array.  Call BindOU Function
Do While Not tsInputFileDomain.AtEndOfStream
	sTemp = tsInputFileDomain.ReadLine
	arDomain = Split(sTemp, vbTab)
	If UBound(arDomain) <> 4 Then
		WScript.Echo "Invalid domain entry found"
	Else
		sDNSDomainName = arDomain(4)
		sOUADsPath = BindOU(arDomain(0), arDomain(1), arDomain(2), arDomain(3), arDomain(4))
	End If
Loop

' *** Bind to OU which will contain the user

Function BindOU(sDC, sOU, sUser, sPwd, sDNSDomainName)

	Set oRootDSE = GetObject("LDAP:")
	Set objContainer = oRootDSE.OpenDSObject("LDAP://" & _
		sDC & "/" & _
		sOU, _
		sUser, _
		sPwd, _
		ADS_SECURE_AUTHENTICATION + ADS_SERVER_BIND)

	' *** Select the group to add the user to, create the user & add the user to the group
	Select Case sDC 
		Case "10.100.2.1"
			Call subCreateUser("10.100.2.1", "OU=Groups,OU=Support,OU=BMS ADMIN,DC=bmsgroup,DC=com", sUser, sPwd)
			Exit Function
		Case "192.168.30.50"
			Call subCreateUser("192.168.30.50", "OU=cantono,OU=external users,DC=psm,DC=local", sUser, sPwd)
			Exit Function
		Case "10.36.0.11"
			Call subCreateUser("10.36.0.11", "OU=CSF Security Groups,DC=csfgroup,DC=com", sUser, sPwd)
			Exit Function
		Case Else
			WScript.Echo "Invalid Domain Controller specified, User cannot be created"
			Exit Function
	End Select
	
End Function

' FOR LOOP STARTS HERE

Dim sUserADsPath
Dim tsInputFileUser
Dim arUser
Dim sGroup

Sub subCreateUser(sDC, sGroupOU, sUser, sPwd)

	Set tsInputFileUser = objFSO.OpenTextFile(sScriptPath & "Users.txt", 1)

	Do While Not tsInputFileUser.AtEndOfStream
		sTemp = tsInputFileUser.ReadLine
		arUser = Split(sTemp, vbTab)
		'If UBound(arUser) <> 3 Then
		'	WScript.Echo "Invalid user entry found"
		'Else
			sUserADsPath = CreateUser(arUser(0), arUser(1), arUser(2), arUser(3))

			On Error Resume Next

			' *** If one domain & description set group to x

			If sDC = "10.36.0.11" Then
				If arUser(3) = "L1" Then
					sGroup = "CN=level 1 admins"
				ElseIf arUser(3) = "L2" Then
					sGroup = "CN=level 2 admins"
				ElseIf arUser(3) = "L3" Then
					sGroup = "CN=level 3 admins"
				Else
					WScript.Echo "Invalid Description Specifed, Cannot Continue"
				End If
			Else
				sGroup = "CN=" & arUser(3)
			End If

			' *** Set Group
			Set objGroup = oRootDSE.OpenDSObject("LDAP://" & sDC & "/" & sGroup & "," & sGroupOU, _
			sUser, sPwd, ADS_SECURE_AUTHENTICATION + ADS_SERVER_BIND)


			' *** Add User to Group
			If Err.Number = 0 Then
				objGroup.Add(sUserADsPath)
				objGroup.SetInfo
			End If
			On Error Goto 0
			
		'End If
	Loop
End sub

Function CreateUser(sAMAccountName, sFirstName, sLastName, sDescription)

	Dim objUserLDAP
	Dim userActCtrl

	' *** Create the user
	Set objUserLDAP = objContainer.Create("user", "CN=" & sFirstName & " " & sLastName)
	objUserLDAP.sAMAccountName = sAMAccountName
	On Error Resume Next
	objUserLDAP.SetInfo
	Select Case Err.Number
		Case 0
		Case -2147019886
			WScript.Echo "User account " & sAMAccountName & "@" & sDNSDomainName & _
			" already exists"
			Exit Function
		Case Else
			WScript.Echo Err.Number & " - " & Err.Description
			Exit Function
	End Select

	' *** Set user's principal name and display name
	objUserLDAP.userPrincipalName = sAMAccountName & "@" & sDNSDomainName
	objUserLDAP.displayName = sFirstName & " " & sLastName

	' *** Set password
	objUserLDAP.SetPassword "Password1"

	' *** Force change at next logon
	objUserLDAP.Put "PwdLastSet", 0

	' *** Enable the account, removing the "password not expire" and "password not required" attributes
	userActCtrl = objUserLDAP.Get("userAccountControl")
	userActCtrl = userActCtrl And Not (ADS_UF_ACCOUNTDISABLE + ADS_UF_PASSWD_NOTREQD + ADS_UF_DONT_EXPIRE_PASSWD)
	objUserLDAP.Put "userAccountControl", userActCtrl

	' *** Set the user's first and last names and description
	objUserLDAP.FirstName = sFirstName
	objUserLDAP.LastName = sLastName
	objUserLDAP.Description = sDescription
	
	' *** Finally commit the changes
	objUserLDAP.SetInfo

	WScript.Echo "User " & sAMAccountName & "@" & sDNSDomainName & " created"
	CreateUser = objUserLDAP.ADsPath
			

End Function

