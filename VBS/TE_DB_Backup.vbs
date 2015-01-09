' #####################################################################################################
' Script to backup TE to folder named by Date in format yymmdd & logs to Application event log
'
' Change Record
' ====================
' v1.0 - 11/04/2011 - Initial Version
'
' #####################################################################################################

Option Explicit

Dim sBackupPath	' *** Path of backups
Dim sDate		' *** Date in format yyyymmdd
Dim oFSO		' *** FileSystemObject
Dim oShell		' *** WScript Shell
Dim sTEBin		' *** Tripwire Enterprise bin path
Dim sSvcPwd		' *** Tripwire Enterprise services password
Dim sConfig		' *** Configuration backup file
Dim sDatabase	' *** Database backup file
Dim sBackupCmd	' *** Backup command string
Dim tsTmpFile	' *** Temp file for verbose output
Dim sTemp		' *** Contents of temp file
Dim sCmd		' *** Command to run tetool

' *** Set variables
sDate = Year(Date)*10000 + Month(Date)*100 + Day(Date)
sBackupPath = "C:\Backups\" & sDate & "\"
sTEBin = "C:\Program Files\Tripwire\TE\Server\Bin\"
sSvcPwd = "T0qqW58z"
sConfig = "config.bak"
sDatabase = "database.bak"

Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = CreateObject("WScript.Shell")

' *** Make sure backup folder doesn't already exist & if not run backup
If oFSO.FolderExists(sBackupPath) Then
	oShell.LogEvent 2, "Tripwire Enterprise cannot be backed up as backup already exists.  Confirm successful backup"
Else
	oFSO.CreateFolder(sBackupPath)
	oShell.LogEvent 4, "Tripwire Enterprise backup commenced"
	sBackupCmd = Chr(34) & sTEBin & "tetool.cmd" & Chr(34) & " backup -v -p " & sSvcPwd & " " & sBackupPath & _
		sConfig & " " & sBackupPath & sDatabase & ">> C:\Temp\tetool.txt"
	sCmd = oShell.Run (sBackupCmd, 0, True)
	Set tsTmpFile = oFSO.OpenTextFile("C:\Temp\tetool.txt", 1)
	sTemp = tsTmpFile.ReadAll
	If instr(sTemp, "error") Then
		oShell.LogEvent 1, sTemp
	Else
		oShell.LogEvent 0, "Tripwire Enterprise backup completed"
	End If
	Set tsTmpFile = oFSO.GetFile("C:\Temp\tetool.txt")
	tsTmpFile.Delete
End If

' *** Clean Up
Set oFSO = Nothing
Set oShell = Nothing
Set tsTmpFile = Nothing
Set sCmd = Nothing