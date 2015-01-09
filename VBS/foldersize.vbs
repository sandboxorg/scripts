Option Explicit

Dim oFSO
Dim oFolder
Dim sSubfolder
Dim tsOutputFile
Dim sPath

sPath = "D:\home"

Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oFolder = oFSO.GetFolder(sPath)
Set tsOutputFile = oFSO.CreateTextFile(sPath & "\foldersize.txt")

For Each oFolder in oFolder.SubFolders
	sSubFolder = oFolder.Size
	tsOutputFile.Writeline(oFolder.Path & vbtab & " " & sSubFolder)
	On Error Resume Next
Next

