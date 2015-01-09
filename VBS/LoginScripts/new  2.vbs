' Logon6.vbs
' VBScript logon script program.
'
' ----------------------------------------------------------------------
' Copyright (c) 2004-2010 Richard L. Mueller
' Hilltop Lab web site - http://www.rlmueller.net
' Version 1.0 - March 28, 2004
' Version 1.1 - July 30, 2007 - Escape any "/" characters in DN's.
' Version 1.2 - November 6, 2010 - No need to set objects to Nothing.
'
' You have a royalty-free right to use, modify, reproduce, and
' distribute this script file in any way you find useful, provided that
' you agree that the copyright owner above has no warranty, obligations,
' or liability for such use.

Option Explicit

Dim objRootDSE, objTrans, strNetBIOSDomain, objNetwork, strNTName
Dim strUserDN, strComputerDN, objGroupList, objUser, strDNSDomain
Dim strComputer, objComputer
Dim strHomeDrive, strHomeShare
Dim adoCommand, adoConnection, strBase, strAttributes

' Constants for the NameTranslate object.
Const ADS_NAME_INITTYPE_GC = 3
Const ADS_NAME_TYPE_NT4 = 3
Const ADS_NAME_TYPE_1779 = 1

Set objNetwork = CreateObject("Wscript.Network")

' Loop required for Win9x clients during logon.
strNTName = ""
On Error Resume Next
Do While strNTName = ""
    strNTName = objNetwork.UserName
    Err.Clear
    If (Wscript.Version > 5) Then
        Wscript.Sleep 100
    End If
Loop
On Error GoTo 0

' Determine DNS domain name from RootDSE object.
Set objRootDSE = GetObject("LDAP://RootDSE")
strDNSDomain = objRootDSE.Get("defaultNamingContext")

' Use the NameTranslate object to find the NetBIOS domain name from the
' DNS domain name.
Set objTrans = CreateObject("NameTranslate")
objTrans.Init ADS_NAME_INITTYPE_GC, ""
objTrans.Set ADS_NAME_TYPE_1779, strDNSDomain
strNetBIOSDomain = objTrans.Get(ADS_NAME_TYPE_NT4)
' Remove trailing backslash.
strNetBIOSDomain = Left(strNetBIOSDomain, Len(strNetBIOSDomain) - 1)

' Use the NameTranslate object to convert the NT user name to the
' Distinguished Name required for the LDAP provider.
objTrans.Set ADS_NAME_TYPE_NT4, strNetBIOSDomain & "\" & strNTName
strUserDN = objTrans.Get(ADS_NAME_TYPE_1779)
' Escape any forward slash characters, "/", with the backslash
' escape character. All other characters that should be escaped are.
strUserDN = Replace(strUserDN, "/", "\/")

' Bind to the user object in Active Directory with the LDAP provider.
Set objUser = GetObject("LDAP://" & strUserDN)

' Map user home directory.
strHomeShare = objUser.homeDirectory
If (strHomeShare <> "") Then
    strHomeDrive = objUser.homeDrive
    If (strHomeDrive = "") Then
        strHomeDrive = "H:"
    End If
    On Error Resume Next
    objNetwork.MapNetworkDrive strHomeDrive, strHomeShare
    If (Err.Number <> 0) Then
        On Error GoTo 0
        objNetwork.RemoveNetworkDrive strHomeDrive, True, True
        objNetwork.MapNetworkDrive strHomeDrive, strHomeShare
    End If
    On Error GoTo 0
End If

' Map a network drive if the user is a member of the group.
If (IsMember(objUser, "Domain Admin") = True) Then
    On Error Resume Next
    objNetwork.MapNetworkDrive "M:", "\\filesrv01\admin"
    If (Err.Number <> 0) Then
        On Error GoTo 0
        objNetwork.RemoveNetworkDrive "M:", True, True
        objNetwork.MapNetworkDrive "M:", "\\filesrv01\admin"
    End If
    On Error GoTo 0
End If

' Use the NameTranslate object to convert the NT name of the computer to
' the Distinguished name required for the LDAP provider. Computer names
' must end with "$".
strComputer = objNetwork.computerName
objTrans.Set ADS_NAME_TYPE_NT4, strNetBIOSDomain _
    & "\" & strComputer & "$"
strComputerDN = objTrans.Get(ADS_NAME_TYPE_1779)
' Escape any forward slash characters, "/", with the backslash
' escape character. All other characters that should be escaped are.
strComputerDN = Replace(strComputerDN, "/", "\/")

' Bind to the computer object in Active Directory with the LDAP
' provider.
Set objComputer = GetObject("LDAP://" & strComputerDN)

' Add a printer connection if the computer is a member of the group.
If (IsMember(objComputer, "Room 231") = True) Then
    objNetwork.AddPrinterConnection "LPT1:", "\\PrintServer\Printer3"
End If

' Clean up.
If (IsObject(adoConnection) = True) Then
    adoConnection.Close
End If

Function IsMember(ByVal objADObject, ByVal strGroupNTName)
    ' Function to test for group membership.
    ' objADObject is a user or computer object.
    ' strGroupNTName is the NT name (sAMAccountName) of the group to test.
    ' objGroupList is a dictionary object, with global scope.
    ' Returns True if the user or computer is a member of the group.
    ' Subroutine LoadGroups is called once for each different objADObject.

    ' The first time IsMember is called, setup the dictionary object
    ' and objects required for ADO.
    If (IsEmpty(objGroupList) = True) Then
        Set objGroupList = CreateObject("Scripting.Dictionary")
        objGroupList.CompareMode = vbTextCompare

        Set adoCommand = CreateObject("ADODB.Command")
        Set adoConnection = CreateObject("ADODB.Connection")
        adoConnection.Provider = "ADsDSOObject"
        adoConnection.Open "Active Directory Provider"
        adoCommand.ActiveConnection = adoConnection

        Set objRootDSE = GetObject("LDAP://RootDSE")
        strDNSDomain = objRootDSE.Get("defaultNamingContext")

        adoCommand.Properties("Page Size") = 100
        adoCommand.Properties("Timeout") = 30
        adoCommand.Properties("Cache Results") = False

        ' Search entire domain.
        strBase = "<LDAP://" & strDNSDomain & ">"
        ' Retrieve NT name of each group.
        strAttributes = "sAMAccountName"

        ' Load group memberships for this user or computer into dictionary
        ' object.
        Call LoadGroups(objADObject)
    End If
    If (objGroupList.Exists(objADObject.sAMAccountName & "\") = False) Then
        ' Dictionary object established, but group memberships for this
        ' user or computer must be added.
        Call LoadGroups(objADObject)
    End If
    ' Return True if this user or computer is a member of the group.
    IsMember = objGroupList.Exists(objADObject.sAMAccountName & "\" _
        & strGroupNTName)
End Function

Sub LoadGroups(ByVal objADObject)
    ' Subroutine to populate dictionary object with group memberships.
    ' objGroupList is a dictionary object, with global scope. It keeps track
    ' of group memberships for each user or computer separately. ADO is used
    ' to retrieve the name of the group corresponding to each objectSid in
    ' the tokenGroup array. Based on an idea by Joe Kaplan.

    Dim arrbytGroups, k, strFilter, adoRecordset, strGroupName, strQuery

    ' Add user name to dictionary object, so LoadGroups need only be
    ' called once for each user or computer.
    objGroupList.Add objADObject.sAMAccountName & "\", True

    ' Retrieve tokenGroups array, a calculated attribute.
    objADObject.GetInfoEx Array("tokenGroups"), 0
    arrbytGroups = objADObject.Get("tokenGroups")

    ' Create a filter to search for groups with objectSid equal to each
    ' value in tokenGroups array.
    strFilter = "(|"
    If (TypeName(arrbytGroups) = "Byte()") Then
        ' tokenGroups has one entry.
        strFilter = strFilter & "(objectSid=" _
            & OctetToHexStr(arrbytGroups) & ")"
    ElseIf (UBound(arrbytGroups) > -1) Then
        ' TokenGroups is an array of two or more objectSid's.
        For k = 0 To UBound(arrbytGroups)
            strFilter = strFilter & "(objectSid=" _
                & OctetToHexStr(arrbytGroups(k)) & ")"
        Next
    Else
        ' tokenGroups has no objectSid's.
        Exit Sub
    End If
    strFilter = strFilter & ")"

    ' Use ADO to search for groups whose objectSid matches any of the
    ' tokenGroups values for this user or computer.
    strQuery = strBase & ";" & strFilter & ";" _
        & strAttributes & ";subtree"
    adoCommand.CommandText = strQuery
    Set adoRecordset = adoCommand.Execute

    ' Enumerate groups and add NT name to dictionary object.
    Do Until adoRecordset.EOF
        strGroupName = adoRecordset.Fields("sAMAccountName").Value
        objGroupList.Add objADObject.sAMAccountName & "\" _
            & strGroupName, True
        adoRecordset.MoveNext
    Loop
    adoRecordset.Close

End Sub

Function OctetToHexStr(ByVal arrbytOctet)
    ' Function to convert OctetString (byte array) to Hex string,
    ' with bytes delimited by \ for an ADO filter.

    Dim k
    OctetToHexStr = ""
    For k = 1 To Lenb(arrbytOctet)
        OctetToHexStr = OctetToHexStr & "\" _
            & Right("0" & Hex(Ascb(Midb(arrbytOctet, k, 1))), 2)
    Next
End Function
