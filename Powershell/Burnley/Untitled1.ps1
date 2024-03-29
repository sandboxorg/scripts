$userfolders = Get-ChildItem

foreach ($a in $userfolders) {
    $cookies = Get-ChildItem -Recurse "$a\AppData\Roaming\Microsoft\Windows\Cookies"
    foreach ($cookie in $cookies) {
        If ($_.LastAccessTime -lt (Get-Date).AddDays(30 * -1)) {
            Write-Host $cookie
        }
    }
}


$userfolders = Get-ChildItem

foreach ($a in $userfolders) {
    $cookies = Get-ChildItem -Recurse "$a\AppData\Roaming\Microsoft\Windows\Recent"
    $cookies | Measure
}