/// Description
Class dc.Demo.imap.IMAPHelper Extends %RegisteredObject
{

/// Description
Property TagCounter As %String [ InitialExpression = 0 ];

/// Description
Property Device As %String;

/// Description
Property Timeout As %Integer [ InitialExpression = 30 ];

/// Based on RFC 2045, page 11, section 5.1 (https://datatracker.ietf.org/doc/html/rfc2045#section-5.1)
Property AllowedBodyPartTypes As %String [ InitialExpression = {$LISTBUILD("text", "image", "audio", "video", "application")} ];

/// Description
Property CurrentCommand As %String [ Internal, Private ];

/// Description
Property CurrentTag As %String [ Internal, Private ];

/// Description
Property LogEnabled As %Boolean [ InitialExpression = 1 ];

/// Description
Method Log(pMsg As %String) As %Status
{
    Return:'..LogEnabled $$$OK
    Set sc = $$$OK
    Set ts = $ZDT($H, 3)
    Set ^dc.Demo.imap.IMAPHelper($JOB, $I(^dc.Demo.imap.IMAPHelper($JOB)), ts) = pMsg
    Return sc
}

/// Sends a command to IMAP server, waits for, validates and return its response.
/// Returns the response as a string.
/// A response is considered valid when it start with the string "* OK". If anything else is returned, 
/// an IMAPExpcetion is thrown.
Method SendCommand(pCommand As %String = "") As %String
{
    Set currIO = $IO
    Set exception = ""
    Try {
        Set command = ""
        If (pCommand '= "") {
            Set tag = ..GetTag()
            Set command = tag_" "_pCommand
        }

        Do ..Log("Using device: "_..Device)
        Use ..Device

        If ($FIND(command, " LOGIN ") > 0) {
            // don't log passwords
            Do ..Log("Sending command: "_$P(command, " ", 1, 3)_" <password hidden>")
        } Else {
            Do ..Log("Sending command: "_command)
        }
        Write:(command '= "") command,!

        Set ..CurrentCommand = pCommand
        Set ..CurrentTag = tag
        Do ..ReadResponse(.response)
        Do ..Log("Command executed successfully")
    }
    Catch ex {
        Set exception = ex
        Do ..Log("Error in command execution: "_ex.DisplayString())
    }
    Use currIO
    Throw:$IsObject(exception) exception
    Return response
}

/// Description
Method ReadResponse(ByRef pResponse As %String) [ Internal ]
{
    Do ..Log("Reading command response")
    Set buffer = ""
    Set pResponse = ""
    Set tokensLine = ""
    While(1) {
        Read buffer:..Timeout
        Set readOK = $TEST
        Set pResponse = pResponse_buffer
        If (..CurrentCommand = "") Quit
        If (readOK) {
            // splits the current response by CRLF
            Set lines = $LISTFROMSTRING(buffer, $Char(13, 10))
            // if the whole response was retrieved, the line with the 
            // tag of the command is the (n-1)-th, due the message 
            // finishes with CRLF, so the n-th list element is ""
            Set ackLine = $LISTGET(lines, * - 1)
            // splits the lines by white space
            Set tokensLine = $LISTFROMSTRING(ackLine, " ")
            // if the whole message was retrieved, the first token has
            // the tag of the command
            Set tagToken = $LISTGET(tokensLine, 1)
            // check if the first token is the expeted tag, if so, the
            // whole message was retrieved and leave the loop
            If (tagToken = ..CurrentTag) Quit
        } Else {
            Quit
        }
    }
    Do ..Log("Command response fetched")

    // check if the whole message was retrieved and its status is OK
    Set ackToken = $LISTGET(tokensLine, 2)
    If (ackToken '= "OK") {
        Throw ##class(dc.Demo.imap.IMAPException).%New("IMAP error: "_$LISTTOSTRING(tokensLine, " "))
    }
}

/// Description
Method GetSequenceTag() As %String
{
    Set ..TagCounter = ..TagCounter + 1
    Return ..TagCounter
}

/// Description
Method GetTag() As %String
{
    Set tag = "TAG"_..GetSequenceTag()
    Return tag
}

/// Description
Method ParseSELECT(ByRef pOutput As %String) As %DynamicObject
{
    Set lines = $LISTFROMSTRING(pOutput, $CHAR(13, 10))
    Set exists = $PIECE($LISTGET(lines, 1), " ", 2)
    Set recent = $PIECE($LISTGET(lines, 2), " ", 2)
    Set flags = $PIECE($LISTGET(lines, 3), " ", 3, *)
    Set resp = {
        "exists": (exists),
        "recent": (recent),
        "flags": (flags)
    }
    Return resp
}

/// Description
Method "ParseFETCH_SIZE"(ByRef pOutput As %String) As %DynamicArray
{
    Set sc = $$$OK
    Set resp = []
    Set lines = $LISTFROMSTRING(pOutput, $CHAR(13, 10))
    Set len = $LISTLENGTH(lines) - 1
    For i=1:1:len {
        Set msgIdx = $PIECE($LISTGET(lines, i), " ", 2)
        Continue:'$ISVALIDNUM(msgIdx)
        Set size = +$PIECE($LISTGET(lines, i), " ", 5)
        Do resp.%Set(msgIdx, size)
    }
    Return resp
}

/// Description
Method "ParseSEARCH_UID"(ByRef pOutput As %String) As %DynamicArray
{
    Set lines = $LISTFROMSTRING(pOutput, $CHAR(13, 10))
    Set uidList = $PIECE($LISTGET(lines, 1), " ", 3, *)
    Set uidList = "["_$REPLACE(uidList, " ", ",")_"]"
    Set resp = [].%FromJSON(uidList)
    Return resp
}

/// Description
ClassMethod GetMailMessageParts(pPart As %Net.MIMEPart, ByRef pInitalMailPart As %Net.MailMessagePart = "") As %Net.MailMessagePart
{
    Set mailPart = pInitalMailPart
    If '$ISOBJECT(mailPart) {
        Set mailPart = ##class(%Net.MailMessagePart).%New()
    }

    Set contentType = $Piece(pPart.GetHeader("CONTENT-TYPE"), ";", 1)
    Set contentDisposition = $Piece(pPart.GetHeader("CONTENT-DISPOSITION"), ";", 1)
    Set contentTransferEncoding = pPart.GetHeader("CONTENT-TRANSFER-ENCODING")
    Set type = $Piece(contentType, "/", 1)
    Set subtype = $Piece(contentType, "/", 2)

    Set mailPart.IsMultiPart = (type = "multipart")
    Set:(mailPart.IsMultiPart) mailPart.MultiPartType = subtype
    Set mailPart.IsBinary = $Case(type, "text": 0, "message": 0, "multipart": 0, "": 0, : 1)
    Set mailPart.IsHTML = (subtype = "html")
    Set mailPart.ContentType = contentType
    Set mailPart.ContentTransferEncoding = contentTransferEncoding
    If ('mailPart.IsBinary) && ('mailPart.IsMultiPart) {
        // %Net.MailMessagePart expect a file stream, so a conversion is necessary
        Set raw = ""
        While ('pPart.Body.AtEnd) {
            Set raw = raw_pPart.Body.Read(, .sc)
        }
        $$$TOE(sc, sc)
        Set stream = ##class(%FileCharacterStream).%New()
        $$$TOE(sc, stream.Write(raw))
        Set mailPart.TextData = stream
    }
    If (mailPart.IsBinary) {
        Set mailPart.BinaryData = pPart.Body
    }
    Set mailPart.InlineAttachment = contentDisposition = "inline"
    Set mailPart.Charset = pPart.GetContentTypeAttribute("CHARSET")
    Set header = ""
    Do {
        Set header = pPart.NextHeader(header)
        If (header '= "") {
            Set headerValue = pPart.GetHeader(header, .headerOriginalName)
            Do mailPart.Headers.SetAt(headerValue, headerOriginalName)
        }
    } While (header '= "")

    // call the method itself to get message parts, if exists
    For i=1:1:pPart.Parts.Count() {
        Do mailPart.Parts.SetAt(..GetMailMessageParts(pPart.Parts.GetAt(i)), i)
    }

    Return mailPart
}

/// Description
Method GetMessageSizeFromFetch(ByRef pOutput As %String) As %Integer
{
    Set firstLine = $Piece(pOutput, $CHAR(13, 10), 1)
    Set resp = +$PIECE(firstLine, "{", 2)
    Return resp
}

}
