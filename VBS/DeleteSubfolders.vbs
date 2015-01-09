Option Explicit

Dim oFSO
Dim oFolder
Dim oSubFolder
Dim sSubFolder

Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oFolder = oFSO.GetFolder("Y:\Users")

For each oFolder in oFolder.SubFolders
	sSubFolder = oFolder.Path
	Set oSubFolder = oFSO.GetFolder("Y:\Users\" & sSubFolder & "\my documents\recycler")
	For Each oSubFolder in oSubFolder.SubFolders
		WScript.Echo oSubFolder.Path " will be deleted"
		oSubFolder.Delete
	Next
Next