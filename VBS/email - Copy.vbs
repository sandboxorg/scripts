


 sFrom       = "speedyhire@readingroom.com"
 sTo         = "extranettest@speedyhire.com"
 sSubject    = "Test SMTP Mail"
 sTextBody   = "This is and Automated message please do not reply"
 sSMTPServer = "10.20.4.230"
 sSMTPPort   = 25

'


    ' Define value's
    Dim i, oEmail

    ' Use custom error handling
    On Error Resume Next

    ' Create an e-mail message object
    Set oEmail = CreateObject( "CDO.Message" )

    ' Fill in the field values
    With oEmail
        .From     = sFrom
        .To       = sTo
        ' Extra options to be added:
        ' .Cc     = ...
        ' .Bcc    = ...
        .Subject  = sSubject
        .Textbody = sTextBody
        If sSMTPPort = "" Then
            sSMTPPort = 25
        End If
        With .Configuration.Fields
            .Item( "http://schemas.microsoft.com/cdo/configuration/sendusing"      ) = 2
            .Item( "http://schemas.microsoft.com/cdo/configuration/smtpserver"     ) = sSMTPServer
            .Item( "http://schemas.microsoft.com/cdo/configuration/smtpserverport" ) = sSMTPPort
            .Update
        End With
        ' Send the message
        .Send
    End With
    ' Return status message
    If Err Then
        EMail = "ERROR " & Err.Number & ": " & Err.Description
        WScript.Echo Email
	Err.Clear
    Else
        EMail = "Message sent ok"
	WScript.Echo Email
    End If

    ' Release the e-mail message object
    Set oEmail = Nothing
    ' Restore default error handling
    On Error Goto 0
'End Function