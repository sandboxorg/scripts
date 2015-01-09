' #####################################################################################################
' Script to remove files over a certain age
'
' Change Record
' ====================
' v1.0 - 22/11/2012 - Initial Version
'
' #####################################################################################################

Option Explicit

Dim iDaysOld		' *** Number of days to retain
Dim sTopFolderPath	' *** Location of folders to delete
Dim oFSO			' *** FileSystemObject
Dim oTopFolder		' *** Top folder object
Dim oLogFile		' *** Sub folders delete depending on age
Dim oShell			' *** WScript Shell
Dim oInput			' *** Input object
Dim iInputCount		' *** Count of input arguments

' *** Get input from script arguments
iInputCount = WScript.Arguments.Count
Set oInput = WScript.Arguments
If iInputCount <> 2 Then
	WScript.Echo "Invalid input - E.g. - cscript DeleteFilesByAge.vbs path\to log\files 7"
	WScript.Quit
Else
	sTopFolderPath = oInput(0)
	iDaysOld = oInput(1)
End If

Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oTopFolder = oFSO.GetFolder(sTopFolderPath)
Set oShell = CreateObject("WScript.Shell")

For each oLogFile in oTopFolder.Files
	Set oLogFile = oFSO.GetFile(oLogFile)
	If DateDiff("d",oLogFile.DateLastModified,Now()) > iDaysOld Then
		oLogFile.Delete
	End If
	Set oLogFile = Nothing
Next

' *** Clean Up
Set oTopFolder = Nothing
Set oFSO = Nothing