Get-Content demo.csv

Import-Csv demo.csv
Import-Csv demo.csv | Select-Object Name
Import-Csv demo.csv | Where { $_.Age -gt 21 }

Get-ChildItem | Export-Csv demo2.csv
Invoke-Item demo2.csv
Import-Csv demo2.csv
