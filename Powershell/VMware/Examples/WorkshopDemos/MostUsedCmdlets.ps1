# Foreach-Object iterates through a list.
Get-ChildItem
$items = Get-ChildItem
Foreach ($item in $items) {
	Write-Output $item
}

# Where-Object is used to filter in the pipeline.
Get-ChildItem | Where-Object { $_.Length -gt 5000 }
Get-ChildItem | Where-Object { $_.Mode -eq "-a---" }

# Objects all have associated properties.
# Sort-Object can sort based on a specified property.
Get-ChildItem | Sort-Object -Property Length

# Get-Content will read from a file.
Get-Content $env:windir\system32\eula.txt

# Select has two main purposes: first to limit the amount you see:
Get-Content $env:windir\system32\eula.txt | Select-Object -First 15

# Second to see the properties of the objects.
Get-ChildItem | Select-Object -First 5
Get-ChildItem | Select-Object -first 5 Name, LastAccessTime

# Read-Host reads user input.
$age = Read-Host "Enter your age"
if ($age -lt 35) {
	Write-Host "$age ??? You look more like", ($age+5), "to me."
} else {
	Write-Host "Ignore all those people who call you grandpa, $age is the perfect age to learn PowerShell."
}
