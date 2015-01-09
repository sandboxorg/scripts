Option Explicit

Dim sScriptPath
Dim oFSO
Dim sRootFolder
Dim oFolder
Dim tsInputFile
Dim oSubFolder
Dim sSubFolder
Dim sCopyFile1
Dim oCopyFile1
Dim sCopyFile2
Dim oCopyFile2
Dim sCopyFolder1
Dim oCopyFolder1

' Set Variables here
sRootFolder = "Y:\Users"
sCopyFile1 = "Y:\users\xmc1\bmstemplates\addins\bmsaddin.ppam"
sCopyFile2 = "Y:\users\xmc1\bmstemplates\bms standard template.potx"
sCopyFolder1 = "Y:\users\xmc1\bmstemplates\document themes"

Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oFolder = oFSO.GetFolder(sRootFolder)
Set oCopyFile1 = oFSO.GetFile(sCopyFile1)
Set oCopyFile2 = oFSO.GetFile(sCopyFile2)
Set oCopyFolder1 = oFSO.GetFolder(sCopyFolder1)

For each oFolder in oFolder.SubFolders
	sSubFolder = oFolder.Path
	Set oSubFolder = oFSO.GetFolder(sSubFolder & "\application data\Microsoft\AddIns")
	oCopyFile1.Copy(oSubFolder.Path & "\")
	Set oSubFolder = oFSO.GetFolder(sSubFolder & "\application data\microsoft\templates")
	oCopyFile2.Copy(oSubFolder.Path & "\")
	oCopyFolder1.Copy(oSubFolder.Path & "\")
	WScript.Echo "Files copied to: " & oSubFolder.Path
Next

WScript.Echo "Script Complete"	