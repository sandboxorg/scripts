$job = Start-Job -ScriptBlock {

   try {
$errorlog = "c:\users\jklimis\error.log"
                                            $ssStr =$args[0]
                                             $ssGrp = $args[1]
                                             $ssMail = $args[2]
                                             
                                             Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
                                             if (-not $?) {throw $error[0].Exception}  # this is required for any errors that are non terminating                                                                     
                                             New-Mailbox $ssStr -Shared -UserPrincipalName $ssMail
                                             if (-not $?) {throw $error[0].Exception}  # this is required for any errors that are non terminating         
                                             Add-MailboxPermission -AccessRights FullAccess -Identity $ssStr -user $ssgrp
            if (-not $?) {throw $error[0].Exception}  # this is required for any errors that are non terminating
   
}
catch [Exception] {
   add-content -path $errorlog -value (get-date),$_.Exception.Message
}

}                                            
                              
Wait-Job $job
Receive-Job $job
