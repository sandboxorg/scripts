$ADS_UF_ACCOUNTDISABLE = 0x0002
$ADS_UF_PASSWD_NOTREQD = 0x0020
$ADS_UF_DONT_EXPIRE_PASSWD = 0x10000

$users = Import-Csv ".\users.csv"
$DNSDomainName = ([ADSI] "LDAP://rootDSE").defaultNamingContext
$OU = [ADSI] ("LDAP://OU=ACS,OU=Admins," + $DNSDomainName)
$Group = [ADSI] ("LDAP://CN=ACS_Admins,OU=ACS,OU=Admins," + $DNSDomainName)
$users | foreach {
	$FirstName = $_.FirstName
	$LastName = $_.LastName
	$sAMAccountName = $_.sAMAccountName
	$newUser = $OU.Create("user","cn=" + $FirstName + " " + $LastName)
	$newUser.Put("sAMAccountName", "adm" + $sAMAccountName)
	$newUser.Put("userPrincipalName", "adm" + $sAMAccountName + "@lab.local")
	$newUser.Put("displayName", $FirstName + " " + $LastName)
	$newUser.Put("givenName", $FirstName)
	$newUser.Put("sn", $LastName)
	$newUser.SetInfo()
	$userActCtrl = $newUser.userAccountControl.Item(0)
	If (($userActCtrl -band $ADS_UF_ACCOUNTDISABLE) -ne 0)
	{
		$userActCtrl = ($userActCtrl -bxor $ADS_UF_ACCOUNTDISABLE)
		$newUser.Put("userAccountControl", $userActCtrl)
	}
	If (($userActCtrl -band $ADS_UF_DONT_EXPIRE_PASSWD) -ne 0)
	{
		$userActCtrl = ($userActCtrl -bxor $ADS_UF_DONT_EXPIRE_PASSWD)
		$newUser.Put("userAccountControl", $userActCtrl)
	}
	If (($userActCtrl -band $ADS_UF_PASSWD_NOTREQD) -ne 0)
	{
		$userActCtrl = ($userActCtrl -bxor $ADS_UF_PASSWD_NOTREQD)
		$newUser.Put("userAccountControl", $userActCtrl)
	}
	$newUser.SetPassword("Password1")
	$newUser.pwdLastSet = 0
	$newUser.SetInfo()
	$Group.Add($newUser.ADsPath)
	$Group.SetInfo()
}