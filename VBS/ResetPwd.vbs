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
	Call subResetPwd

End Function



Dim sUserADsPath
Dim tsInputFileUser
Dim arUser
Dim sGroup

Sub subResetPwd

	Set tsInputFileUser = objFSO.OpenTextFile(sScriptPath & "Users.txt", 1)

	Do While Not tsInputFileUser.AtEndOfStream
		sTemp = tsInputFileUser.ReadLine
		arUser = Split(sTemp, vbTab)
		If UBound(arUser) <> 3 Then
			WScript.Echo "Invalid user entry found"
		Else
			sUserADsPath = ResetPwd(arUser(0), arUser(1), arUser(2), arUser(3))

			On Error Resume Next

		
		End If
	Loop
End sub

Function ResetPwd(sAMAccountName, sFirstName, sLastName, sDescription)

	Dim objUserLDAP
	Dim userActCtrl
	Dim sNewPwd

	sNewPwd = "Password1"

	Set objUserLDAP = ObjContainer.GetObject("user", "CN=" & sFirstName & " " & sLastName)
	WScript.Echo objUserLDAP.Name

	' *** Set password
	objUserLDAP.SetPassword sNewPwd
	objUserLDAP.SetInfo

	' *** Force change at next logon
	objUserLDAP.Put "PwdLastSet", 0

	' *** Enable the account, removing the "password not expire" and "password not required" attributes
	userActCtrl = objUserLDAP.Get("userAccountControl")
	userActCtrl = userActCtrl And Not (ADS_UF_ACCOUNTDISABLE + ADS_UF_PASSWD_NOTREQD + ADS_UF_DONT_EXPIRE_PASSWD)
	objUserLDAP.Put "userAccountControl", userActCtrl
	
	' *** Finally commit the changes
	objUserLDAP.SetInfo

	WScript.Echo sAMAccountName & " password reset to: " & sNewPwd
	'WScript.Echo "User " & sAMAccountName & "@" & sDNSDomainName & " created"
	ResetPwd = objUserLDAP.ADsPath
			

End Function

