' #####################################################################################################
' Aircelle
' Migrate all user's key profile folders
'
'
' Change Record
' ====================
' v1.0 - 14/11/2012 - Initial Version
'
' #####################################################################################################

Option Explicit

Dim oFSO			' FileSystemObject
Dim sScriptPath		' Path script is run from
Dim sAMAccountName	' Username - from input
Dim oInput			' Input
Dim tsLogFile		' Log File
Dim sProfilePath	' Current profile path
Dim sUPMPath		' UPM path
Dim sRedirPath		' Folder redirection path
Dim sHomePath		' Home directory path
Dim adoConn			' Active Directory connection
Dim adoCmd			' Active Directory connection command
Dim oRootDSE		' Root Directory Services
Dim sDNSDomainName	' Domain
Dim sBase			' Base of LDAP query
Dim sFilter			' Filter for LDAP query
Dim sQuery			' Query string
Dim rsUser			' User Recordset
Dim sUser			' User string

sProfilePath = "\\server-email\roaming\"
sUPMPath = "\\blsrfs01\upm$\"
sRedirPath = "\\blsrfs01\folderredir$\"

sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oInput = WScript.Arguments
sAMAccountName = oInput(0)
Set tsLogFile = oFSO.OpenTextFile(sScriptPath & "\" & sAMAccountName & ".log", 8, True, 0)

sProfilePath = sProfilePath & sAMAccountName
sUPMPath = sUPMPath & sAMAccountName & "\UPM_Profile"
sRedirPath = sRedirPath & sAMAccountName

sHomePath = funcHomeDir(sAMAccountName)

Function funcHomeDir(sAMAccountName)
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
	sFilter = "(&(objectCategory=person)(objectClass=user)(cn=" & sAMAccountName & "))"

	' *** Set query string
	sQuery = sBase & ";" & sFilter & _
		";sAMAccountName, homeDirectory" & ";subtree"

	' *** Set the command to the query string
	With adoCmd
		.CommandText = sQuery
		.Properties("Page Size") = 100
		.Properties("Timeout") = 30
		.Properties("Cache Results") = False
	End With
dim ouser
	' *** Execute the command
	Set oUser = adoCmd.Execute

	WScript.Echo oUser.Fields("homeDirectory")
	' *** Loop through the record set putting the fields into the CSV file
	'Do Until rsUser.EOF
	'	sUser = rsUser.Fields("sAMAccountName")
	'	Select Case sUser
	'	Case sUser = sAMAccountName
	'		sHomePath = rsUser.Fields("homeDirectory")
	'		Exit Function
	'	End Select
'		If sUser = sAMAccountName Then
'			sHomePath = rsUser.Fields("homeDirectory")
'		End If
	'L'oop

End Function

WScript.Echo sProfilePath
WScript.Echo sUPMPath
WScript.Echo sRedirPath
WScript.Echo sHomePath
WScript.Echo sUser