$rfidlist = Import-Csv .\rfid_upload.csv

foreach ($line in $rfidlist) {

    # Map fields in CSV file
    #$name = $line.name
    $username = $line.user
    $pager = $line.pager
    
    $user = Get-ADUser $username -Properties pager
    $user.pager = $pager

    Set-ADUser -Instance $user
    
}