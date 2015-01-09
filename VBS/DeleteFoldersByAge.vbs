' #####################################################################################################
' Script to remove folders over a certain age & log deleted folders to Application event log
'
' Change Record
' ====================
' v1.0 - 11/04/2011 - Initial Version
'
' #####################################################################################################

Option Explicit

Dim iDaysOld		' *** Number of days to retain
Dim sTopFolderPath	' *** Location of folders to delete
Dim oFSO		' *** FileSystemObject
Dim oTopFolder		' *** Top folder object
Dim oSubFolder		' *** Sub folders delete depending on age
Dim oShell		' *** WScript Shell

' *** Set Variables
sTopFolderPath = "C:\Backups"
iDaysOld = 3

Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oTopFolder = oFSO.GetFolder(sTopFolderPath)
Set oShell = CreateObject("WScript.Shell")

For each oSubFolder in oTopFolder.SubFolders
	Set oSubFolder = oFSO.GetFolder(oSubFolder)
	If DateDiff("d",oSubFolder.DateLastModified,Now()) > iDaysOld Then
		oShell.LogEvent 0, oSubFolder.Path & " deleted as per " & iDaysOld & _
			" day local retention policy"
		oSubFolder.Delete
	End If
	Set oSubFolder = Nothing
Next

' *** Clean Up
Set oTopFolder = Nothing
Set oFSO = Nothing