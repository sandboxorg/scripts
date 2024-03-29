# Removes PST file when AD User doesn't exist.
# Relies on \\BLSRARC01\archive being mapped to X:\


$archives = Get-ChildItem | Select -ExpandProperty name
Foreach ($archive in $archives){
  $user = Get-ADUser -LDAPFilter "(sAMAccountName=$archive)"
  If ($user -eq $null) {
    Write-Host "User $archive does not exist"
    Dir X:\$archive >> ArchivedPSTs.txt
    Remove-Item X:\$archive\*.*
    Copy-Item .\Archived.txt X:\$archive\Archived.txt
    }
  Else {}
}