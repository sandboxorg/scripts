Option Explicit

Dim sDNSDomainName
Dim sContainer
Dim oRootDSE
Dim oGroup
Dim oMember
Dim oNGroup
Dim cMembers
Dim sMember
Dim sPath
Dim tsOutputFile
Dim oFSO
Dim sFile

' *** Output file name
sFile = "Admins"


' *** Create a csv file to save results
sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set tsOutputFile = oFSO.CreateTextFile(sScriptPath & "\" & sFile & ".csv", True)
tsOutputFile.WriteLine "Username" & "," & "Display Name"

'Bind to AD
sContainer = "CN=Administrators,CN=Builtin,"
Set oRootDSE = GetObject("LDAP://RootDSE")
sDNSDomainName = oRootDSE.Get("DefaultNamingContext")

'Get Builtin Admin Group
Set oGroup = GetObject("LDAP://" & sContainer & sDNSDomainName)
oGroup.GetInfo

For Each oMember in oGroup.Members
	If (LCase(oMember.Class) = "user") Then
		WScript.Echo "User: " & oMember.Name
	Elseif (LCase(oMember.Class) = "group") Then
		WScript.Echo "Group: " & oMember.Name
		Set oNGroup = GetObject(oMember.ADsPath)
		GetNested(oNGroup)
	End If
Next

Function GetNested(oNGroup)
	For Each sMember in oNGroup.Members
		tsOutputFile.WriteLine sMember.sAMAccountName & "," & sMember.Name
	Next
End Function

WScript.Echo "Script Complete"