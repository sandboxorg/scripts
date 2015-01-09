#Created by Randy Wintle MVP, Communications Server
#Basic Script to Enable user accounts for AD,Exchange 2010, Unified Messaging and Lync Server 2010

#This script will create a new AD user, enable their mailbox, enable their online archive, enable for UM and enable for Lync.

#This script has a lot of pauses in it, I was running into issues when running the commands too quickly, the pause may be reduced, but this worked for my environment.


#Define Environment Variables

$Lyncserver="Lync Pool"
$exchangeserver="Exchange 2010 Server"
$umpolicy="UM Mailbox Policy"
$dialplan="Lync Voice Dial Plan"
$voicepolicy="Lync Voice Policy"
$locationpolicy="Lync Location Policy"
$externalaccesspolicy="Lync External Access Policy"
$userou="OU Where the user shoudl be created"
$companyname="Your Company Name (Organization Tab in ADUC)"
$mailboxdatabase="Your Mailbox Database"
$archivedatabase="Your Database holding online archives"
$retentionpolicy="Your retention policy"
$sipdomain="your sip domain"

#Import Session information for Exchange and Lync Server

$usercredential= get-credential
$exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$exchangeserver/PowerShell/ -Authentication Kerberos -Credential $UserCredential
Import-PsSession $exchangesession
$lyncsession = new-pssession -connectionuri https://$Lyncserver/ocspowershell -credential $usercredential
Import-PSSession $lyncsession


#Prompt for Username and Password
$firstname = read-host -prompt "Enter First Name"
$lastname = read-host -prompt "Enter Last Name"
$username = read-host -prompt "Enter User Name (First Initial, Last Name  IE Jfallon)"
$department = read-host -prompt "Enter Department: List Department Options"
$title = read-host -prompt "Enter Job Title"
$manager = read-host -prompt "Enter Manager in format of username IE jfallon"
$Name=$Firstname+" "+$Lastname
$accountpassword = read-host -assecurestring -prompt "Please Enter Temporary Password"
#adjust how your UPN should look
$upn = $username+ "@domain.com"



# You should adjust the $teluri field to customize how you want that teluri to be formatted. In my example, we have "2 digit extension", and our tel uri is the full DID below, you can adjust as neeeded
#Prompt for extension and lync info
$extension = read-host -prompt "Enter the extension"
$teluri="tel:+120751896"+$extension

#create user and enable mailbox

New-Mailbox  -name $name -userprincipalname $upn -Alias $username -OrganizationalUnit $userou -SamAccountName $username -FirstName $FirstName -Initials '' -LastName $LastName -Password $accountpassword -ResetPasswordOnNextLogon $true -Database $mailboxdatabase -Archive -ArchiveDatabase $archivedatabase -RetentionPolicy $retentionpolicy

#pause for 30 seconds for AD 
write-host -foregroundcolor Green "Pausing for 30 seconds for AD Changes"
Start-Sleep -s 30 

#set user properties

Get-Mailbox $username | Set-User -Company $companyname -Department $department -title $title -Manager $manager 


#Enable For Unified Messaging

Get-Mailbox $username | Enable-UMMailbox -ummailboxpolicy $umpolicy -sipresourceidentifier $upn -extensions $extension 

#pause 10 for AD changes

write-host -foregroundcolor Green "Pausing 10 Seconds for AD Changes"
Start-Sleep -s 10

#enable for lync and configure settings

Get-mailbox $username | Enable-csuser  -registrarpool $lyncserver -sipaddresstype EmailAddress -sipdomain $sipdomain

#pause 30 for Lync changes

write-host -foregroundcolor Green "Pausing 30 Seconds for Lync Changes"
Start-Sleep -s 30

Get-mailbox $username | Set-CSUser -enterprisevoiceenabled $True -lineuri $teluri

Get-mailbox $username | Grant-CSVoicePolicy -policyname $voicepolicy

Get-mailbox $username | Grant-CSDialPlan -policyname $dialplan

Get-mailbox $username | Grant-CSLocationPolicy -policyname $locationpolicy

Get-mailbox $username | Grant-CSExternalAccessPolicy -policyname $externalaccesspolicy


#pause 30 Seconds and provide summary

write-host -foregroundcolor Green "Pausing 30 seconds for changes, then will provide a summary, if you do not wish to view the summary here you may close this window."
Start-Sleep -s 30

write-host -foregroundcolor Green "Mailbox Summary"
Get-Mailbox $username 

write-host -foregroundcolor Green "Press any key to view UM and Lync Summaries ..."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

get-ummailbox $username 

write-host -foregroundcolor Green "Press any key to view Lync Summary..."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Get-CSUser $username 

write-host -foregroundcolor Green "Press any key to exit"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

exit





 
