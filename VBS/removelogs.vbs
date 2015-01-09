Option Explicit

Dim intDaysOld, strObjTopFolderPath, strLogFIleSuffix, ObjFS, ObjTopFolder 
Dim ObjDomainFolder, ObjW3SvcFolder, ObjSubFolder, ObjLogFile, ObjFile

intDaysOld        = 30        'Number of days to retain on the server
strObjTopFolderPath    = "c:\windows\system32\logfiles"        'The location of your log files
strLogFIleSuffix    = ".log"    'The suffix of your log files

Set ObjFS = CreateObject("Scripting.FileSystemObject")
Set ObjTopFolder = ObjFS.GetFolder(strObjTopFolderPath)

For Each ObjDomainFolder in ObjTopFolder.SubFolders
   WScript.Echo("  Folder: " & ObjDomainFolder.name)
   Set ObjSubFolder = ObjFS.GetFolder(ObjDomainFolder)
        For each ObjLogFile in ObjSubFolder.files
            Set ObjFile = ObjFS.GetFile(ObjLogFile)
            If datediff("d",ObjFile.DateLastModified,Date()) > intDaysOld and lcase(right(ObjLogFile,4))=strLogFIleSuffix then
                WScript.Echo("    Will delete " & ObjSubFolder.name & "\" & ObjFile.name)
                WScript.Echo("    Deleted " & ObjSubFolder.name & "\" & ObjFile.name)
                ObjFile.Delete
            End If
            Set ObjFile = nothing
        Next
    Set ObjSubFolder = nothing
Next


Set ObjTopFolder = nothing
Set ObjFS = nothing
