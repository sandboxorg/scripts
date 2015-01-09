Dim sScriptPath
Dim objFSO
Dim tsInputFile
Dim sTemp
Dim wShell


ScriptPath = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set tsInputFile = objFSO.OpenTextFile(sScriptPath & "app.txt", 1)
Set wShell = CreateObject("WScript.Shell")

Do while Not tsInputFile.AtEndOfStream
	sTemp = tsInputFile.ReadLine
	sTemp2 = Mid(sTemp,46,15)
	If inStr(1,sTemp2,"PROD-CITRIX") Then
		WScript.Echo sTemp2
		wShell.Run "M:\Anix\McLeod\test.cmd"
	Else
		WScript.Echo "no server"
	End If
Loop