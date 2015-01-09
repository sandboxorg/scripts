foreach ($user in $expiring){
	$mailaddress = Get-ADUser $user -Properties mail | Select -ExpandProperty mail
	$username = Get-ADUser $user -Properties SamAccountName | Select -expand SamAccountName
	$expirydate = Get-ADUser $user -Properties AccountExpirationDate | Select -ExpandProperty AccountExpirationDate
	$displayname = Get-ADUser $user -Properties Name | select -expand Name
	$singlefield = '"Email address - {0}, Username - {1}, Account Expiry - {2}, Display Name - {3}"' -f $mailaddress, $username, $expirydate, $displayname
	}
	
	