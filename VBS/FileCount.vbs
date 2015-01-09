' #####################################################################################################
' This script will search a specified folder for all subfolders & count the number of files within the
' recent folder.  It will output the number of files to a csv file & delete the files
'
' Change Record
' ====================
' v1.0 - 30/03/2011 - Initial Version
'
' #####################################################################################################

Option Explicit

Dim oFSO			'FileSystemObject
Dim oFolder			'Folder Object
Dim oSubFolder		'SubFolder Object
Dim sSubFolder		'Subfolder path
Dim oFile			'File to delete
Dim sCount			'Number of files
Dim tsOutputFile	'TextStream Output File
Dim sScriptPath		'Path the script is run from
Dim sOutput			'Output file name
Dim sFolder			'Folder to check against
Dim sCheckFolder	'Subfolder to count files from

'#####################################
' Declare Variables

sOutput = "RecentNumber" 'Output text file name, will be stored in the script directory
sFolder = "D:\Roaming" 'Folder to check against
sCheckFolder = "recent" 'Folder to count files from

sScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oFolder = oFSO.GetFolder(sFolder)
Set tsOutputFile = oFSO.CreateTextFile(sScriptPath & sOutput & ".csv", True)

tsOutputFile.WriteLine "Username" & ", " & "File Count"

On Error Resume Next

For each oFolder in oFolder.SubFolders
	sSubFolder = oFolder.Path
	Set oSubFolder = oFSO.GetFolder(sSubFolder & "\" & sCheckFolder)
	sCount = oSubFolder.Files.Count
	tsOutputFile.WriteLine oFolder.Name & ", " & sCount
	'For Each oFile in oSubFolder.Files
		'oFile.Delete
	'Next
Next

WScript.Echo "Script Complete"