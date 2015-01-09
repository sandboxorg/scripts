' #####################################################################################################
' Function to convert Integer8 value to a date, adjusted for local time bias
'
'			INCOMPLETE
' Change Record
' ====================
' v1.0 - 01/07/2011 - Initial Version
'
' #####################################################################################################

Option Explicit

Dim oShell			' *** WScript Shell object
Dim oDate			' *** Date object
Dim sDate			' *** Date after Integer8 conversion

Set oShell = CreateObject("WScript.Shell")

Function Date(ByVal oDate)

Dim iBiasKey		' *** Time offset from registry
Dim iBias			' *** Time offset after registry comparison
Dim iHigh			' *** High part of date
Dim iLow			' *** Low part of date

' *** Get local time bias from registry

iBiasKey = oShell.RegRead("HKLM\System\CurrentControlSet\Control\TimeZoneInformation\ActiveTimeBias")

If (UCase(TypeName(iBiasKey)) = "LONG") Then
	iBias = iBiasKey
ElseIf (UCase(TypeName(iBiasKey)) = "VARIANT()") Then
	iBias = 0
	For k = 0 To UBound(iBiasKey)
		iBias = iBias + (iBiasKey(k) * 256^k)
	Next
End If

iHigh = oDate.HighPart
iLow = oDate.LowPart

If (iLow < 0) Then
	iHigh = iHigh + 1
End If

If (iHigh = 0) And (iLow = 0) Then
	sDate = #1/1/1601#
Else
	sDate = #1/1/1601# + (((iHigh * (2 ^ 32)) + iLow)/600000000 - iBias)/1440
End If

If sDate = #1/1/1601# Then
	sDate = "Never"
End If

End Function