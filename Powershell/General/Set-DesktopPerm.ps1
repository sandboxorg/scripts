$foldername = F:\users\*

$usernames = get-childitem $foldername 
foreach ($name in $usernames ){icacls $name\desktop.ini /deny "Administrators:(R)"}