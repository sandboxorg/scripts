
$outputFile = "C:\Users\na302167\Desktop\ProfileSizes.csv"

$MasterPath = "I:\Profiles"

$folders = Get-ChildItem -path $MasterPath

foreach ($folder in $folders) {
  $size = Get-ChildItem -Path "$MasterPath\$folder" -Recurse | Measure-Object Length -Sum | Select -ExpandProperty Sum
  
  $size = "{0:N2}" -f ($size / 1MB)
  
  "$folder,$size" | Out-File -FilePath $outputFile -Append 
  
}