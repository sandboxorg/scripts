Option Explicit

Const ADS_SECURE_AUTHENTICATION = 1
Const ADS_SERVER_BIND = 512

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

' *** Bind to OU which contains the user

Function BindOU(sDC, sOU, sUser, sPwd, sDNSDomainName)

	Set oRootDSE = GetObject("LDAP:")
	Set objContainer = oRootDSE.OpenDSObject("LDAP://" & _
		sDC & "/" & _
		sOU, _
		sUser, _
		sPwd, _
		ADS_SECURE_AUTHENTICATION + ADS_SERVER_BIND)
	Call subChangeHome

End Function



Dim sUserADsPath
Dim tsInputFileUser
Dim arUser
Dim sGroup

Sub subChangeHome

	Set tsInputFileUser = objFSO.OpenTextFile(sScriptPath & "Users.txt", 1)

	Do While Not tsInputFileUser.AtEndOfStream
		sTemp = tsInputFileUser.ReadLine
		arUser = Split(sTemp, vbTab)
		If UBound(arUser) <> 3 Then
			WScript.Echo "Invalid user entry found"
		Else
			sUserADsPath = ChangeHome(arUser(0), arUser(1), arUser(2), arUser(3))

			On Error Resume Next

		End If
	Loop
End sub

Function ChangeHome(sAMAccountName, sFirstName, sLastName, sDescription)

	Dim objUserLDAP
	Dim userActCtrl
	Dim sHomeDirectory
	Dim sHomeDrive
	Dim objFSOHome
	Dim objFSOFolder
	Dim oWSHShell
	
	sHomeDirectory = "\\csf-fap\userdata$\"
	sHomeDrive = "H:"

	Set objUserLDAP = ObjContainer.GetObject("user", "CN=" & sFirstName & " " & sLastName)
	
	' *** Set homeDirectory
	objUserLDAP.Put "homeDirectory", sHomeDirectory & sAMAccountName
	objUserLDAP.Put "homeDrive", sHomeDrive
	objUserLDAP.SetInfo

	' *** Create Home Directory & Set Permissions
	Set objFSOHome = CreateObject("Scripting.FileSystemObject")
	If Not objFSOHome.FolderExists(sHomeDirectory & sAMAccountName) Then
		Set objFSOFolder = objFSOHome.CreateFolder(sHomeDirectory & sAMAccountName)
		
		Set oWSHShell = WScript.CreateObject("WScript.Shell")

		' *** Add Permissions
		oWSHShell.Run("cacls.exe " & sHomeDirectory & sAMAccountName & _
			" /t /e /g " & """csfgroup\domain admins:F""" & _
			" " & sAMAccountName & ":F" & _
			" system:F")

		' *** Remove unnecessary permissions
		oWSHShell.Run("cacls.exe " & sHomeDirectory & sAMAccountName & _
			" /t /e /r " & """authenticated users""" & _
			" csfgroup\dean.stimpson" & _
			" everyone")

		WScript.Echo sAMAccountName & " home drive changed to: " & sHomeDirectory & sAMAccountName
	Else
		WScript.Echo "Home Directory Already Exists, permissions not changed but account modified"
	End If


	ChangeHome = objUserLDAP.ADsPath
			

End Function

