Function MoveMailbox (Server, RecipName, Moveto_MailboxStore, Moveto_StorageGroup, Moveto_Server)
	
	' Declare variables.
    Dim objUser         ' IADsUser
    Dim iAdRootDSE      ' ActiveDs.IADs
    Dim objMailbox      ' CDOEXM.IMailboxStore
    Dim objServer       ' CDOEXM.ExchangeServer
	Dim objSG           ' CDOEXM.StorageGroup
	Dim objMSDB         ' CDOEXM.MailboxStoreDB
	Dim iDS             ' IDataSource2
	Dim storegroup      ' Variant
	Dim mbx             ' Variant
	Dim bFound          ' Boolean
	Dim sMailStorePath   ' String
	Dim sDirectoryServer ' String
	Dim sDomainName      ' String

	' Initialize MoveMailbox
	MoveMailbox = False

	Set objServer = CreateObject("CDOEXM.ExchangeServer")
	Set objSG = CreateObject("CDOEXM.StorageGroup")
	Set objMSDB = CreateObject("CDOEXM.MailboxStoreDB")

	' Initialize bFound.
	bFound = False
	' Note that although the object is formally known as “IDataSource2”
	' it is accessed as “IDataSource”
	Set iDS = objServer.GetInterface("IDataSource")
	iDS.Open Moveto_Server

	' Check that the destination mailbox store exists.
	For Each storegroup In objServer.StorageGroups
		objSG.DataSource.Open storegroup
		If UCase(Moveto_StorageGroup) = UCase(objSG.Name) Then
			For Each mbx In objSG.MailboxStoreDBs
				objMSDB.DataSource.Open mbx
				If UCase(Moveto_MailboxStore) = UCase(objMSDB.Name) Then
					bFound = True
					sMailStorePath = mbx
					Exit For
				End If
			Next
		End If
		If bFound Then Exit For
	Next

	If Not bFound Then
		wscript.echo "The destination MailStore is not found."
		Exit Function
	End If

		' Get the default naming context.
	Set iAdRootDSE = GetObject(LDAP://RootDSE)
	sDomainName = iAdRootDSE.Get("defaultNamingContext")
	wscript.echo sDomainName
	' Get the Active Directory user object. This sample script assumes that the user exists
	' in the default container but you may rewrite to search for the user as shown in the
	' previous article.

	Set objUser = GetObject("LDAP://CN=" + RecipName + ",CN=users," + sDomainName)
	Set objMailbox = objUser

	' Check if a mailbox exists for the user.
	If objMailbox.HomeMDB = "" Then
		wscript.echo "There is no mailbox to move."
	Else
		wscript.echo "Current MDB: " + objMailbox.HomeMDB
		wscript.echo "Moving mailbox..."

		' Move the mailbox.
		objMailbox.MoveMailbox "LDAP://" + sMailStorePath

		' Save data into the data source.
		objUser.SetInfo
		wscript.echo "The mailbox has been moved to '" + Moveto_MailboxStore + _
			"' mailbox store successfully."
		MoveMailbox = True
	End If
	' Verify that the mailbox has been moved, verify that the HomeMDB server
	' now matches Moveto_Server.
	Set objUser = GetObject("LDAP://CN=" + RecipName + ",CN=users," + sDomainName)
	Set objMailbox = objUser
	If UCase(objMailbox.HomeMDB) = UCase(sMailStorePath) Then
		wscript.echo "The mailbox move is verified."
	Else
	wscript.echo "The mailbox move is not verified."
	End If
End Function