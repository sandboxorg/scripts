Option Explicit

Dim oFSO
Dim tsInputFile
Dim sScriptPath
Dim adoCmd
Dim adoConn
Dim oRootDSE
Dim sDNSDomainName
Dim sBase
Dim sFilter
Dim rsUser
Dim sTemp
Dim sADsPath
Dim sQuery
Dim oUser

' *** Open disableusers.txt for reading
sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set tsInputFile = oFSO.OpenTextFile(sScriptPath & "disableusers.txt", 1)

' *** Get the current domain details to query against
Set oRootDSE = GetObject("LDAP://RootDSE")
sDNSDomainName = oRootDSE.Get("DefaultNamingContext")

' *** Base of query
sBase = "<LDAP://" & sDNSDomainName & ">"

' *** Create and open connection
Set adoConn = CreateObject("ADODB.Connection")
Set adoCmd = CreateObject("ADODB.Command")
With adoConn
	.Provider = "ADsDSOObject"
	.Open = "Active Directory Provider"
End With

Set adoCmd.ActiveConnection = adoConn

' *** Set the command to the query string
With adoCmd
	.Properties("Page Size") = 100
	.Properties("Timeout") = 30
	.Properties("Cache Results") = False
End With

Do While Not tsInputFile.AtEndOfStream
	sTemp = tsInputFile.ReadLine

	' *** Filter for query
	sFilter = "(&(ObjectCategory=person)(ObjectClass=user)(sAMAccountName=" & sTemp & "))"

	' *** Set query string
	sQuery = sBase & ";" & sFilter & ";AdsPath;subtree"

	adoCmd.CommandText = sQuery

	' *** Execute the command
	Set rsUser = adoCmd.Execute

	If Not (rsUser.BOF Or rsUser.EOF) Then
		sADsPath = rsUser.Fields(0)
		Set oUser = GetObject(sADsPath)
		oUser.Put "userAccountControl" , 514
		oUser.SetInfo
		WSCript.Echo sTemp & " account disabled"
	
	End If

Loop


' *** Close Connections
Set adoConn = Nothing
Set adoCmd = Nothing
Set oRootDSE = Nothing
Set rsUser = Nothing

WScript.Echo "Script Complete"
