' #####################################################################################################
' Login script for Aircelle @ Burnley
' Global Settings
' ------------------------------------
' 		Maps H:, R:, W:, Z: Globally
'		Copies SAP files - services, saphttp.exe, saplogon.ini, sncgss32.dll from Z:
'
' Per Group Settings
' ------------------------------------
'		If in group G_BL_Comm_AutoStart Communicator will automatically start
'
' Change Record
' ====================
' v1.0 - 26/11/2012 - Initial Version
' v1.1 - 10/12/2012 - Added check for registry key for Communicator - JM
'
' #####################################################################################################

Option Explicit

Dim sScriptPath		' *** Path script is run from
Dim oRootDSE		' *** Root DSA Specific Entry
Dim oFSO			' *** FileSystemObject
Dim sDNSDomainName	' *** DNS root
Dim adoConn			' *** Active Directory connection
Dim adoCmd			' *** Active Directory connection command
Dim oShell			' *** WScript Shell
Dim oNetwork		' *** WScript Network
Dim oGroup			' *** Group Object
Dim oUser			' *** User object
Dim sUser			' *** User String
Dim sNTGroup		' *** Group string
Dim oGroupList		' *** List of groups as a dictionary object
Dim sBase			' *** Base of LDAP query
Dim sFilter			' *** Filter for LDAP query
Dim sQuery			' *** Query string
Dim sTemp			' *** Temporary string
Dim sComputer		' *** Hostname
Dim oWMI			' *** WMI Object
Dim sOS				' *** OS Version

' *** Global objects and strings
sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = CreateObject("WScript.Shell")
Set oNetwork = CreateObject("WScript.Network")
sComputer = "."

' *** Determine DNS domain name from oRootDSE object
Set oRootDSE = GetObject("LDAP://RootDSE")
sDNSDomainName = oRootDSE.Get("defaultNamingContext")

' *** Determine Username from ADSystemInfo
Set sUser = CreateObject("ADSystemInfo")
Set oUser = GetObject("LDAP://" & sUser.UserName)

' *** Global Settings

' *** Remove existing drive mappings to global letters
On Error Resume Next
oNetwork.RemoveNetworkDrive "H:", True, True
oNetwork.RemoveNetworkDrive "R:", True, True
oNetwork.RemoveNetworkDrive "W:", True, True
oNetwork.RemoveNetworkDrive "Z:", True, True
On Error Goto 0

' *** H: drive mapping to BLSRARC01 for Email Archive
oNetwork.MapNetworkDrive "H:", "\\BLSRARC01\Archive\" & oUser.sAMAccountName, True

' *** R: drive mapping to French Groups share
oNetwork.MapNetworkDrive "R:", "\\fichier-lh\groupes", True

' *** W: drive mapping to Data Controlled Documents share
oNetwork.MapNetworkDrive "W:", "\\server-one\Electronic_Data_Controlled_Documents", True

' *** Z: drive mapping to BLSRFS01 temporary shared area
oNetwork.MapNetworkDrive "Z:", "\\BLSRFS01\Shared_Files", True

' *** Copy SAP Files
If (osVersion(sComputer) = "5.1") Then
	oFSO.CopyFile "Z:\#PROGRAMS#\sap\services", "C:\Windows\System32\Drivers\etc\services", True
	oFSO.CopyFile "Z:\#PROGRAMS#\sap\saphttp.exe", "C:\Windows\saphttp.exe", True
	oFSO.CopyFile "Z:\#PROGRAMS#\sap\saplogon.ini", "C:\Windows\saplogon.ini", True
	oFSO.CopyFile "Z:\#PROGRAMS#\sap\system32\sncgss32.dll", "C:\Windows\System32\sncgss32.dll", True
End If

' *** Per Group Settings

' *** Checks for membership of G_BL_Comm_AutoStart
If (IsMember(oUser, "G_BL_Comm_AutoStart") = True) Then
	On Error Resume Next
	sTemp = oShell.RegRead("HKCU\SOFTWARE\Microsoft\Communicator\AutoRunWhenLogonToWindows")
	Select Case Err.Number
		Case 0
			If (sTemp = 0) Then
				oShell.RegWrite "HKCU\SOFTWARE\Microsoft\Communicator\AutoRunWhenLogonToWindows", 1, "REG_DWORD"
			End If
			On Error Goto 0
		Case -2147024894
			oShell.RegWrite "HKCU\SOFTWARE\Microsoft\Communicator\AutoRunWhenLogonToWindows", 0, "REG_DWORD"
			On Error Goto 0
		Case Else
			WScript.Echo "Please report this error to the helpdesk (" & Err.Number & ")"
			On Error Goto 0
	End Select
Else
	On Error Resume Next
	sTemp = oShell.RegRead("HKCU\SOFTWARE\Microsoft\Communicator\AutoRunWhenLogonToWindows")
	Select Case Err.Number
		Case 0
			If (sTemp <> 0) Then
				oShell.RegWrite "HKCU\SOFTWARE\Microsoft\Communicator\AutoRunWhenLogonToWindows", 0, "REG_DWORD"
			End If
			On Error Goto 0
		Case -2147024894
			oShell.RegWrite "HKCU\SOFTWARE\Microsoft\Communicator\AutoRunWhenLogonToWindows", 0, "REG_DWORD"
			On Error Goto 0
		Case Else
			WScript.Echo "Please report this error to the helpdesk (" & Err.Number & ")"
			On Error Goto 0
	End Select
End If

Function IsMember(ByVal oUser, ByVal sNTGroup)
' *** Function to test group member against the values provided
' *** oUser is the User object as retrieved from Active Directory
' *** sNTGroup is the group to test against

	If (IsEmpty(oGroupList) = True) Then
		Set oGroupList = CreateObject("Scripting.Dictionary")
		oGroupList.CompareMode = vbTextCompare
		
		' *** Create and open connection
		Set adoConn = CreateObject("ADODB.Connection")
		Set adoCmd = CreateObject("ADODB.Command")
		With adoConn
			.Provider = "ADsDSOObject"
			.Open "Active Directory Provider"
		End With
		Set adoCmd.ActiveConnection = adoConn
		
		' *** Determine DNS domain name from oRootDSE object
		Set oRootDSE = GetObject("LDAP://RootDSE")
		sDNSDomainName = oRootDSE.Get("defaultNamingContext")
		
		' *** Base of query
		sBase = "<LDAP://" & sDNSDomainName & ">"

		' *** Set the command to the query string
		With adoCmd
			.Properties("Page Size") = 100
			.Properties("Timeout") = 30
			.Properties("Cache Results") = False
		End With
		
		Call LoadGroups(oUser)
	End If
	
	If (oGroupList.Exists(oUser.sAMAccountName & "\") = False) Then
		Call LoadGroups(oUser)
	End If
	
	IsMember = oGroupList.Exists(oUser.sAMAccountName & "\" & sNTGroup)
	
End Function

Sub LoadGroups(ByVal oUser)
	' *** Subroutine to populate oGroupList dictionary list with group memberships
	Dim arGroups		' *** Array of groups that user is a member of
	Dim k				' *** Count object
	Dim rsGroups		' *** Groups recordset
	Dim sGroup			' *** Group string
	
	' *** Add username to dictionary object
	oGroupList.Add oUser.sAMAccountName & "\", True
	
	oUser.GetInfoEx Array("tokenGroups"), 0
	arGroups = oUser.Get("tokenGroups")
	
	' *** Filter for query
	sFilter = "(|"
	If (TypeName(arGroups) = "Byte()") Then
		' *** tokenGroups only has one entry
		sFilter = sFilter & "(objectSid=" & OctetToHexStr(arGroups) & ")"
	Elseif (UBound(arGroups) > -1) Then
		' *** tokenGroups has at least 2 objectSid's
		For k = 0 To UBound(arGroups)
			sFilter = sFilter & "(objectSid=" & OctetToHexStr(arGroups(k)) & ")"
		Next
	Else
		Exit Sub
	End If
	
	sFilter = sFilter & ")"
		
	' *** Set query string
	sQuery = sBase & ";" & sFilter & ";sAMAccountName" & ";subtree"
	
	adoCmd.CommandText = sQuery
	Set rsGroups = adoCmd.Execute
	
	' *** Loop through recordset adding group name to dictionary list
	Do Until rsGroups.EOF
		sGroup = rsGroups.Fields("sAMAccountName").Value
		oGroupList.Add oUser.sAMAccountName & "\" & sGroup, True
		rsGroups.MoveNext
	Loop
	rsGroups.Close
End Sub

Function OctetToHexStr(ByVal arOctet)
	' *** Function to convert octetstring into Hex string

	Dim k					' *** Count object
	
	OctetToHexStr = ""
	For k = 1 To Lenb(arOctet)
		OctetToHexStr = OctetToHexStr & "\" & Right("0" & Hex(Ascb(Midb(arOctet, k, 1))), 2)
	Next
End Function

Function osVersion(ByVal sComputer)
	' *** Function to test for OS Version & Architecture
	
	Dim rsOS				' *** WMI record set
	Dim oOS					' *** OS Object
	
	Set oWMI = GetObject("winmgmts://" & sComputer & "/root/cimv2")
	Set rsOS = oWMI.ExecQuery("Select * from Win32_OperatingSystem")
	For Each oOS in rsOS
		sOS = Left(oOS.Version, 3)
	Next
	osVersion = sOS
End Function