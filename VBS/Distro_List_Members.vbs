' #####################################################################################################
' This script will search AD for all groups with an email address
' Then it will list the group in an Excel Worksheet entitled Distribution Lists
' It will create a new Worksheet for each group, name after the group and list the members
' Save the Excel file in the path the script is run from, entitled sText
' Nested groups will be highlighted in Bold & Contacts will be highlighted in Italics
' Group managers will be listed in Cell A2 & highlighted in red
'
' Change Record
' ====================
' v1.0 - 17/06/2011 - Initial Version
' v1.1 - 30/06/2011 - Added group manager
'
' #####################################################################################################

Option Explicit

Const ADS_ACETYPE_ACCESS_ALLOWED_OBJECT = &H5
Const ADS_RIGHT_DS_WRITE_PROP = &H20
Const ADS_FLAG_OBJECT_TYPE_PRESNT = &H01
Const ADS_OBJECT_WRITE_MEMBERS = "{BF9679C0-0DE6-11D0-A285-00AA003049E2}"

Dim sText			' *** Name of output XLSX file
Dim sScriptPath		' *** Path script is run from
Dim oExcel			' *** Excel Object
Dim oBook			' *** Excel Workbook
Dim oSheet			' *** Excel Worksheet
Dim adoConn			' *** AD Connection
Dim adoCmd			' *** AD Command
Dim oRootDSE		' *** Root Directory Service Entry
Dim sDNSDomainName	' *** Root Domain Name
Dim sBase			' *** Base of LDAP query
Dim sFilter			' *** Filter for LDAP
Dim sQuery			' *** Query for LDAP
Dim rsGroup			' *** Group RecordSet
Dim oGroup			' *** Group object
Dim oMember			' *** Group member object
Dim k				' *** Current Worksheet 1 Cell Number
Dim j				' *** Current Worksheet i Cell Number
Dim sGroup			' *** Group String
Dim sManaged		' *** Group manager
Dim oManaged		' *** Group manager object
Dim oSD				' *** Security Descriptor Object
Dim oDACL			' *** Discretionary ACL Object
Dim oACE			' *** ACE object
Dim oUser			' *** User object
Dim sChkbx			' *** Modify membership of group check box

' *** Set Variables
sText = "BMSGroup - Distribution List Members"

'*** Create an XLSX file to save results
sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oExcel = CreateObject("Excel.Application")
Set oBook = oExcel.Workbooks.Add
Set oSheet = oBook.Worksheets(1)

' *** Rename Sheet 1 and put a column header in cell A1
With oSheet
	.Name = "Distribution Lists"
	.Range("A1").Value = "Distribution List Name"
	.Range("A1").Font.Bold = True
End With

' *** Delete Sheets 2 & 3 within the Excel Workbook
Set oSheet = oBook.Worksheets("Sheet2")
oSheet.Delete
Set oSheet = oBook.Worksheets("Sheet3")
oSheet.Delete

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
sFilter = "(&(objectCategory=group)(objectClass=group)(mail=*))"

' *** Set query string
sQuery = sBase & ";" & sFilter & ";ADsPath, name" & ";subtree"

' *** Set the command to the query string
With adoCmd
	.CommandText = sQuery
	.Properties("Page Size") = 100
	.Properties("Timeout") = 30
	.Properties("Cache Results") = False
End With

' *** Execute the command
Set rsGroup = adoCmd.Execute

' *** Loop through recordset enumerating members & writing to Excel file
k = 2
oExcel.Visible = True

Do Until rsGroup.EOF
	j = 1
	Set oGroup = GetObject(rsGroup.Fields("ADsPath").Value)
	oGroup.GetInfo
	Set oSheet = oBook.Worksheets("Distribution Lists")
	oSheet.Range("A" & k).Value = oGroup.displayName
	k = k + 1
	sManaged = oGroup.managedBy
	Set oSD = oGroup.Get("ntSecurityDescriptor")
	Set oDACL = oSD.DiscretionaryACL
		
	' *** Replace bad characters & trim name length
	sGroup = oGroup.displayName
	sGroup = Replace(sGroup, ":", "_")
	sGroup = Replace(sGroup, "/", "_")
	If Len(sGroup) > 30 Then
		sGroup = Left(sGroup, 30)
	End If
	
	On Error Resume Next
	
	Set oSheet = oBook.Worksheets.Add( , oBook.Worksheets(oBook.Worksheets.Count))
	With oSheet
		.Name = sGroup
		.Range("A" & j).Value = "Distribution Group: " & oGroup.displayName
		.Range("A" & j).Font.Bold = True
	End With

	' *** Check to see if group name exists on spreadsheet	
	If Err.Number = 1004 Then
		WScript.Echo sGroup & " Duplicate Group name exists.  " & Err.Description
	ElseIf Err.Number = 0 Then
	Else 
		WScript.Echo "There has been an error with " & sGroup & ".  The error description is " & Err.Description
	End If	
	j = j + 1
	
	On Error Goto 0

	' *** Check for the 'Managed By' field.  If present put in cell A2 & mark red
	If (IsEmpty(sManaged)) Then
		sManaged = "None"
	Else
		Set oUser = GetObject("LDAP://" & sManaged)
	
		For Each oACE in oDACL
			If InStr(1, oACE.Trustee, oUser.Get("sAMAccountName"), VbTextCompare) Then
				sChkBx = 1
			End If
		Next
		Set oManaged = GetObject("LDAP://" & sManaged)
		sManaged = oManaged.displayName
	End If
	oSheet.Range("A" & j).Value = sManaged
	oSheet.Range("A" & j).Font.ColorIndex = 3
	If sChkBx = 1 Then
		oSheet.Range("A" & j).Font.Bold = True
	End If
	
	j = j + 1
	
	For Each oMember in oGroup.Members
		If (LCase(oMember.Class) = "user") Then
			oSheet.Range("A" & j).Value = oMember.displayName
			j = j + 1
		ElseIf (LCase(oMember.Class) = "group") Then
			oSheet.Range("A" & j).Value = oMember.displayName
			oSheet.Range("A" & j).Font.Bold = True
			j = j + 1
		ElseIf (LCase(oMember.Class) = "contact") Then
			oSheet.Range("A" & j).Value = oMember.displayName
			oSheet.Range("A" & j).Font.Italic = True
			j = j + 1
		End If
	Next
	rsGroup.MoveNext
Loop

' *** Save Excel file and quit Excel
oBook.SaveAs sScriptPath & sText & ".xlsx"
oExcel.Quit

' *** Clean Up
Set adoCmd = Nothing
Set adoConn = Nothing
Set oRootDSE = Nothing
Set rsGroup = Nothing
Set oExcel = Nothing

WScript.Echo "Script Complete"