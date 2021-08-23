Include %occErrors

/// IMAPv4 implementation
Class dc.Demo.imap.IMAP Extends %Net.FetchMailProtocol
{

/// Description
Property SSLConfiguration As %String;

/// Description
Property Port As %String [ InitialExpression = 993 ];

/// Description
Property Timeout As %Integer [ InitialExpression = 30 ];

/// Description
Property Helper As dc.Demo.imap.IMAPHelper;

/// Description
Property Device As %String [ Internal ];

/// Description
Property Server As %String [ Internal ];

/// Description
Property UserName As %String [ Internal, Private ];

/// Description
Property MailboxName As %String [ InitialExpression = "INBOX" ];

/// Description
Property MarkedAsDeleted [ MultiDimensional ];

Method %OnNew() As %Status [ Private ]
{
    Set ..Helper = ##class(dc.Demo.imap.IMAPHelper).%New()
	Return $$$OK
}

/// Cleanup the temp global used to store the message.
Method %OnClose() As %Status
{
	Do ..Disconnect()
	Return $$$OK
}

/// Description
Method DeviceSet(pValue As %String) As %Status
{
    Set i%Device = pValue
    Set ..Helper.Device = pValue
    Return $$$OK
}

/// Description
Method CheckConnection()
{
    Throw:'..Connected ##class(dc.Demo.imap.IMAPException).%New("Not connected")
}

/// <P>Use to logon to your mail server using the
/// username and password that are the parameters to this routine.</P>
Method Connect(pServer As %String, pUserName As %String, pPassword As %String) As %Status
{
    If ..Connected Return $$$ERROR($$$ConnectedError)

    Set sc = $$$OK
    Set ..Device = "|TCP|"_..Port
    Try {
        Set ..Server = pServer
        Set ..UserName = pUserName

        Do ..Helper.Log("[Connect] Trying to establish connection to host "_..Server_" (user: "_..UserName_")")

        Open ..Device:(..Server:..Port:"C":/TLS=..SSLConfiguration):..Timeout
        If '$TEST {
            Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$ConnectedError))
        }
        Do ..Helper.Log("[Connect] Connection established to host "_pServer)
        Do ..Helper.Log("[Connect] Device is: "_..Device)

        Do ..Helper.SendCommand("LOGIN "_..UserName_" "_pPassword)
        Do ..Helper.Log("[Connect] Connected successfully")

        Set ..Connected = 1
    }
    Catch ex {
        Set sc = ex.AsStatus()
        Do ..Helper.Log("[Connect] Connection failed: "_ex.DisplayString())
    }
    Return sc
}

/// Description
Method Disconnect() As %Status
{
    Set sc = $$$OK
    Try {
        If ..Connected {
            Do ..Helper.SendCommand("LOGOUT")
            Close ..Device
            Set ..Device = ""
            Set ..Connected = 0
            Do ..Helper.Log("[Disconnect] Disconnected")
        }
    }
    Catch ex {
        Set sc=ex.AsStatus()
        Do ..Helper.Log("[Disconnect] Disconnect failed: "_ex.DisplayString())
    }
    Return sc
}

/// <P>Get information about your mail box, the number of bytes it
/// contains, and the number of messages;</P>
Method GetMailBoxStatus(ByRef NumberOfMessages As %Integer, ByRef NumberOfBytes As %Integer) As %Status
{
    Set sc = $$$OK
    Try {
        Do ..CheckConnection()
        Set command = $$$FormatText("SELECT ""%1""", ..MailboxName)
        Set resp = ..Helper.SendCommand(command)
        Do ..Helper.Log("[GetMailBoxStatus] "_..MailboxName_": "_resp)
        Set parsed = ..Helper.ParseSELECT(resp)
        Do ..Helper.Log("[GetMailBoxStatus] Parsed "_..MailboxName_": "_parsed.%ToJSON())
        Set NumberOfMessages = parsed.exists
        // Seems like RFC 3501 doesn't support this feature...
        // A workaround would be use FETCH 1:* (RFC822.SIZE) to get size for every message 
        // and do the maths locally, but this will be slow and hard to mantain in pratice, in 
        // mailbox with thousands of messages.
        // See https://stackoverflow.com/questions/45890749/how-to-get-full-size-of-mailbox-using-imap
        Set NumberOfBytes = -1
    }
    Catch ex {
        Set sc=ex.AsStatus()
        Do ..Helper.Log("[GetMailBoxStatus] GetMailBoxStatus failed: "_ex.DisplayString())
    }
    Return sc
}

/// <P>If you pass in an empty string "", an array with an element for 
/// each of the messages not marked for deletion is returned.  
/// Each element of the array has the message number as its index 
/// and the size of the message in bytes as its value..</P>
/// 
/// <P>If you pass in a message number, a one element array is returned. The element
/// has the message number as its index and the size of the message 
/// in bytes as its value.  An error status is returned if a message
/// with this message number does not exist or has been marked for deletion.</P>
Method GetSizeOfMessages(MessageNumber As %String = "", ByRef ListOfSizes As %ArrayOfDataTypes) As %Status
{
    Set sc = $$$OK
    Try {
        Do ..CheckConnection()
        If (MessageNumber = "") {
            // TODO: performance test needed
            Throw ##class(dc.Demo.imap.IMAPException).%New("Not implemented: get size of all messages in mailbox.")
        }
        Set command = $$$FormatText("FETCH %1 (RFC822.SIZE)", MessageNumber)
        Set resp = ..Helper.SendCommand(command)
        Do ..Helper.Log("[GetSizeOfMessages] fetch: "_resp)
        Set parsed = ..Helper."ParseFETCH_SIZE"(resp)
        Do ..Helper.Log("[GetSizeOfMessages] Parsed fetch: "_parsed.%ToJSON())
        
        Set:('$ISOBJECT($Get(ListOfSizes))) ListOfSizes = ##class(%ArrayOfDataTypes).%New()
        Set it = parsed.%GetIterator()
        While(it.%GetNext(.msgIdx, .size)){
            Do ListOfSizes.SetAt(size, msgIdx)
        }
    }
    Catch ex {
        Set sc=ex.AsStatus()
        Do ..Helper.Log("[GetSizeOfMessages] GetSizeOfMessages failed: "_ex.DisplayString())
    }
    Return sc
}

/// <P>If you pass in an empty string "", an array with an element for 
/// each of the messages not marked for deletion is returned.  
/// Each element of the array has the message number as its index 
/// and the unique message identifier (UID) as its value..</P>
/// 
/// <P>If you pass in a message number, a one element array is returned. The element
/// has the message number as its index and unique message identifier (UID)
/// as its value.  An error status is returned if a message
/// with this message number does not exist or has been marked for deletion.</P>
/// 
/// <P>The unique message identifier is at most 70 characters long and
/// each character is ASCII and printable (0x21 to 0x7E).</P>
/// 
/// <P>Each identifier is unique within the mailbox and is persistent.
/// If a given message has a particular unique identifier in one
/// session, it must have the same unique ID in all sessions.  Once
/// used, a given UID can never be reused even if the corresponding
/// message is deleted.</P>
/// 
/// <P>If a specified message (corresponding to MessageNumber) does not
/// exist or is marked for deletion, the function returns an error status.
/// 
/// <P>This command is used to implement a poor man's server-based
/// message store.  Basically, a client does not automatically
/// delete messages, after getting messages, then at the start of
/// each session, it calls GetMessageUIDArray to obtain an
/// array of all messages currently on the server.  Any UIDs not
/// currently known by the client are retrieved.  That of course
/// requires the client to keep track of the UIDs for all retrieved
/// messages.</P>
Method GetMessageUIDArray(MessageNumber As %String = "", ByRef ListOfUniqueIDs As %ArrayOfDataTypes) As %Status
{
    Set sc = $$$OK
    Try {
        Do ..CheckConnection()
        // first select mailbox in order to fetch its UIDs
        Set command = $$$FormatText("SELECT ""%1""", ..MailboxName)
        Set resp = ..Helper.SendCommand(command)
        Do ..Helper.Log("[GetMessageUIDArray] "_..MailboxName_": "_resp)
        // then get the mailbox UIDs
        Set param = $CASE(MessageNumber, "":"ALL", :MessageNumber)
        Set command = $$$FormatText("UID SEARCH %1", param)
        // todo: replace above for this:
        #; Set param = $CASE(MessageNumber, "":"1:*", :MessageNumber)
        #; Set command = $$$FormatText("FETCH %1 (UID)", param)
        Set resp = ..Helper.SendCommand(command)
        Do ..Helper.Log("[GetMessageUIDArray] "_..MailboxName_" search: "_resp)
        Set parsed = ..Helper."ParseSEARCH_UID"(resp)
        Do ..Helper.Log("[GetMessageUIDArray] Parsed "_..MailboxName_": "_parsed.%ToJSON())
        
        Set:('$ISOBJECT($Get(ListOfUniqueIDs))) ListOfUniqueIDs = ##class(%ArrayOfDataTypes).%New()
        Set it = parsed.%GetIterator()
        While(it.%GetNext(.msgIdx, .uid)){
            Do ListOfUniqueIDs.SetAt(uid, msgIdx + 1)
        }
    }
    Catch ex {
        Set sc=ex.AsStatus()
        Do ..Helper.Log("[GetMessageUIDArray] GetMessageUIDArray failed: "_ex.DisplayString())
    }
    Return sc
}

/// <P>For the message number singled out by MessageNumber, this
/// function returns the corresponding unique id.  The message
/// number must not correspond to a non-existent message or a
/// message already marked for deletion or an error message is
/// returned.</P>
/// 
/// <P>The unique message identifier is at most 70 characters long and
/// each character is ASCII and printable (0x21 to 0x7E).</P>
/// 
/// <P>Each identifier is unique within the mailbox and is persistent.
/// If a given message has a particular unique identifier in one
/// session, it must have the same unique ID in all sessions.  Once
/// used, a given UID can never be reused even if the corresponding
/// message is deleted.</P>
/// 
/// <P>If a specified message (corresponding to MessageNumber) does not
/// exist or is marked for deletion, the function returns an
/// error %Status.</P>
/// 
/// <P>This command is used to implement a poor mans server-based
/// message store.  Basically, a client does not automatically
/// delete messages, after getting messages, then at the start of
/// each session, it calls GetMessageUIDs to obtain a
/// list of all messages currently on the server.  Any UIDs not
/// currently known by the client are retrieved.  That of course
/// requires the client to keep track of the UIDs for all retrieved
/// messages.<P>
Method GetMessageUID(MessageNumber As %Integer, ByRef UniqueID As %String) As %Status
{
    Set sc = $$$OK
    Try {
        $$$TOE(sc, ..GetMessageUIDArray(MessageNumber, .ListOfUniqueIDs))
        Set:($ISOBJECT($GET(ListOfUniqueIDs))) UniqueID = ListOfUniqueIDs.GetAt(1)
    }
    Catch ex {
        Set sc=ex.AsStatus()
        Do ..Helper.Log("[Fetch] GetMessageUIDArray failed: "_ex.DisplayString())
    }
    Return sc
}

/// <p>This method retrieves a single message.  MessageNumber must be a
/// valid message number and the message must not be currently
/// marked for deletion.</P>
/// 
/// <P>Msg is a MailMessage (possibly multipart) and a return parameter.  
/// The fetched mail message is returned in this parameter</P>
/// 
/// <P>If Delete is 1, the message is deleted.  If 0, it is not deleted.</P>
/// 
/// <p>If messageStream is specified, then the original message is written to this binary stream.
/// messageStream needs to be a binary stream since mail messages may include binary data
/// and multiple charsets.
Method Fetch(MessageNumber As %Integer, ByRef Msg As %Net.MailMessage, Delete As %Boolean = 0, messageStream As %BinaryStream) As %Status
{
    Set sc = $$$OK
    Try {
        Do ..CheckConnection()
        
        // first select the mailbox in order to get a message
        Set command = $$$FormatText("SELECT ""%1""", ..MailboxName)
        Set resp = ..Helper.SendCommand(command)
        Do ..Helper.Log("[Fetch] "_..MailboxName_": "_resp)

        // get the whole message
        Set command = $$$FormatText("FETCH %1 BODY.PEEK[]", MessageNumber)
        Set rawMsg = ..Helper.SendCommand(command)
        Do ..Helper.Log("[Fetch] message: "_rawMsg)

        If $IsObject($Get(messageStream)) {
            $$$TOE(sc, messageStream.Write(rawMsg))
        }
        
        // get message size in bytes
        Set msgSize = ..Helper.GetMessageSizeFromFetch(rawMsg)
        
        // remove tags from message
        Set rawMsg = $Piece(rawMsg, $Char(13, 10), 2, * - 2)

        // %Net.MIMEReader requires the content in stream format
        Set stream = ##class(%Stream.GlobalCharacter).%New()
        $$$TOE(sc, stream.Write(rawMsg))

        // uses %Net.MIMEReader to parse the MIME content in message 
        // in a %Net.MIMEPart object
        Set reader = ##class(%Net.MIMEReader).%New()
        $$$TOE(sc, reader.OpenStream(stream))
        $$$TOE(sc, reader.ReadMIMEMessage(.msgPart))

        // prepare the %Net.MIMEPart return object
        Set Msg = ##class(%Net.MailMessage).%New()

        // get message headers
        Do Msg.To.Insert(msgPart.GetHeader("TO"))
        Do Msg.Cc.Insert(msgPart.GetHeader("CC"))
        Do Msg.Bcc.Insert(msgPart.GetHeader("BCC"))
        Set Msg.From = msgPart.GetHeader("FROM")
        Set Msg.Subject = msgPart.GetHeader("SUBJECT")
        Set Msg.Date = msgPart.GetHeader("DATE")

        // walks through parts of the parsed message and return a 
        // %Net.MailMessagePart object
        Set Msg = ..Helper.GetMailMessageParts(msgPart, .Msg)
        Set Msg.MessageSize = msgSize

        If (Delete = 1) {
            $$$TOE(sc, ..DeleteMessage(MessageNumber))
        }
    }
    Catch ex {
        Set sc=ex.AsStatus()
    }
    Return sc
}

/// <p>This method retrieves a single eml format message from a binary stream.  
/// messageStream must be a binary stream containing the message.</p>
/// 
/// <P>Msg is a MailMessage (possibly multipart) and a return parameter.  
/// The fetched mail message is returned in this parameter</P>
Method FetchFromStream(messageStream As %BinaryStream, ByRef Msg As %Net.MailMessage) As %Status
{
    Set sc = $$$OK
    Try {
        Do ..CheckConnection()

        // uses %Net.MIMEReader to parse the MIME content in message 
        // in a %Net.MIMEPart object
        Set reader = ##class(%Net.MIMEReader).%New()
        $$$TOE(sc, reader.OpenStream(messageStream))
        $$$TOE(sc, reader.ReadMIMEMessage(.msgPart))

        // prepare the %Net.MIMEPart return object
        Set Msg = ##class(%Net.MailMessage).%New()

        // get message headers
        Do Msg.To.Insert(msgPart.GetHeader("TO"))
        Do Msg.Cc.Insert(msgPart.GetHeader("CC"))
        Do Msg.Bcc.Insert(msgPart.GetHeader("BCC"))
        Set Msg.From = msgPart.GetHeader("FROM")
        Set Msg.Subject = msgPart.GetHeader("SUBJECT")
        Set Msg.Date = msgPart.GetHeader("DATE")

        // walks through parts of the parsed message and return a 
        // %Net.MailMessagePart object
        Set Msg = ..Helper.GetMailMessageParts(msgPart, .Msg)
        
        // get message size in bytes
        Set Msg.MessageSize = ..GetTextSize(Msg)
    }
    Catch ex {
        Set sc=ex.AsStatus()
    }
    Return sc
}

/// Description
Method GetTextSize(pPart As %Net.MailMessagePart) As %Integer [ Internal, Private ]
{
    Set size = 0
    If pPart.Parts.Count() = 0 {
        If pPart.ContentType [ "text" {
            Set size = pPart.TextData.Size
        }
    } Else {
        For i=1:1:pPart.Parts.Count() {
            Set size = size + ..GetTextSize(pPart.Parts.GetAt(i))
        }
    }
    Return size
}

/// <P>This method retrieves a single message.  MessageNumber must be a
/// valid message number and the message must not be currently
/// marked for deletion.</P>
/// 
/// <P>Msg is a MailMessage (possibly multipart) and a return parameter.  
/// The fetched mail message is returned in this parameter</P>
/// 
/// <P>If Delete is 1, the message is deleted.  If 0, it is not deleted.</P>
/// 
/// <P>FetchMessage also returns selected headers in additional by 
/// reference parameters as well as the array of all headers.</P>
Method FetchMessage(MessageNumber As %Integer, ByRef From As %String, ByRef To As %String, ByRef Date As %String, ByRef Subject As %String, ByRef MessageSize As %Integer, ByRef MsgHeaders As %ArrayOfDataTypes, ByRef Msg As %Net.MailMessage, Delete As %Boolean) As %Status
{
    Set sc = $$$OK
    Try {
        $$$TOE(sc, ..Fetch(MessageNumber, .Msg))
        Set From = Msg.From
        Set To = Msg.To
        Set Date = Msg.Date
        Set Subject = Msg.Subject
        Set MessageSize = Msg.MessageSize
        Set MsgHeaders = Msg.Headers

        If (Delete = 1) {
            $$$TOE(sc, ..DeleteMessage(MessageNumber))
        }
    }
    Catch ex {
        Set sc=ex.AsStatus()
    }
    Return sc
}

/// <P>This method retrieves a single message.  MessageNumber must be a
/// valid message number and the message must not be currently
/// marked for deletion.</P>
/// 
/// <P>An upper bound is put on number of lines of message text
/// retrieved by Lines.</P>
/// 
/// <P>The text of the retrieved message is returned in the MessageText argument as a %String.</P>
/// 
/// <P>FetchMessageInfo is typically used to get From, Date, and other
/// header information without actually getting the message text.  This
/// allows one to filter out messages from parties one wishes to exclude
/// or to zero in on messages one particularly wants.  Since getting
/// message text is something that can happen over a slow modem, this
/// is a desirable feature.</P>
Method FetchMessageInfo(MessageNumber As %Integer, Lines As %Integer = "", ByRef From As %String, ByRef To As %String, ByRef Date As %String, ByRef Subject As %String, ByRef MessageSize As %Integer, ByRef MsgHeaders As %ArrayOfDataTypes, ByRef MessageText As %String) As %Status
{
    Set sc = $$$OK
    Try {
        $$$TOE(sc, ..Fetch(MessageNumber, .Msg))
        Set From = Msg.From
        Set To = Msg.To
        Set Date = Msg.Date
        Set Subject = Msg.Subject
        Set MsgHeaders = Msg.Headers
        Set MessageSize = Msg.MessageSize
        Set MessageText = ""

        Set textPart = ..FindTextPart(Msg)
        Set lineCount = 0
        If $IsObject(textPart) {
            Do {
                If (Lines '= "") {
                    Set lineCount = lineCount + 1
                    Quit:(lineCount > Lines)
                }
                Set MessageText = MessageText_textPart.TextData.ReadLine()_$Char(13, 10)
            } While 'textPart.TextData.AtEnd
        }
    }
    Catch ex {
        Set sc=ex.AsStatus()
    }
    Return sc
}

/// Return the fisrt text/* part in the message, if any exists
Method FindTextPart(pPart As %Net.MailMessagePart) As %Net.MailMessagePart [ Internal, Private ]
{
    Set textPart = ""
    If pPart.Parts.Count() = 0 {
        If pPart.ContentType [ "text" {
            Set textPart = pPart
        }
    } Else {
        For i=1:1:pPart.Parts.Count() {
            Set textPart = ..FindTextPart(pPart.Parts.GetAt(i))
            Quit:$IsObject(textPart)
        }
    }
    Return textPart
}

/// <P>This method deletes a single message.  MessageNumber must be a
/// valid message number and the message must not be currently
/// marked for deletion.</P>
Method DeleteMessage(MessageNumber As %Integer) As %Status
{
    Set sc = $$$OK
    Try {
        Do ..CheckConnection()
        Set ..MarkedAsDeleted(MessageNumber) = 1
    }
    Catch ex {
        Set sc=ex.AsStatus()
    }
    Return sc
}

/// <P>This method unmarks any messages previously marked for deletion.</P>
Method RollbackDeletes() As %Status
{
    Kill ..MarkedAsDeleted
    Return $$$OK
}

/// <P>This method ends the session of this Protocl object with the
/// mail server.</P>
/// 
/// <P>Also, as a side-effect, any messages marked for deletion are deleted.</P>
/// 
/// <P>This function (or its companion QuitAndRollback) must be
/// executed before the process that issued a connect ends or havoc
/// could be wreaked upon the mail server.  (Mail servers do not
/// have to bullet proof themselves against connects not followed by
/// a quit.)</P>
Method QuitAndCommit() As %Status
{
    Set sc = $$$OK
    Try {
        Do ..CheckConnection()
        $$$TOE(sc, ..CommitMarkedAsDeleted())
        $$$TOE(sc, ..Disconnect())
    }
    Catch ex {
        Set sc=ex.AsStatus()
    }
    Return sc
}

/// <P>This function calls RollbackDeletes and then quits.</P>
/// 
/// <P>This method ends the session of this Protocl object with the
/// mail server.</P>
/// 
/// <P>This function (or its companion QuitAndCommit) must be
/// executed before the process that issued a connect ends or havoc
/// could be wreaked upon the mail server.  (Mail servers do not
/// have to bullet proof themselves against connects not followed by
/// a quit.)</P>
Method QuitAndRollback() As %Status
{
    Set sc = $$$OK
    Try {
        $$$TOE(sc, ..RollbackDeletes())
        $$$TOE(sc, ..Disconnect())
    }
    Catch ex {
        Set sc=ex.AsStatus()
    }
    Return sc
}

/// <P>This function is used to prevent an autologout timer from expiring
/// or to determine if the server is still functioning on the connection.</P>
Method Ping() As %Status
{
    Set sc = $$$OK
    Try {
        Do ..CheckConnection()
        Set resp = ..Helper.SendCommand("NOOP")
    }
    Catch ex {
        Set sc=ex.AsStatus()
    }
    Return sc
}

/// Description
Method CommitMarkedAsDeleted() As %Status [ Internal, Private ]
{
    Set sc = $$$OK
    Try {
        Do ..CheckConnection()
        Set command = $$$FormatText("SELECT ""%1""", ..MailboxName)
        Set resp = ..Helper.SendCommand(command)
        Do ..Helper.Log("[CommitMarkedAsDeleted] "_..MailboxName_": "_resp)
        
        // transverse array in inverse order to keep numbers integrety, that is,
        // ensures that when onde number is deleted no other message can assume
        // such number
        Set messageNumber = $Order(..MarkedAsDeleted(""), -1)
        While (messageNumber '= "") {
            Set command = $$$FormatText("STORE %1 +FLAGS (\Deleted)", messageNumber)
            Set resp = ..Helper.SendCommand(command)
            Do ..Helper.Log("[CommitMarkedAsDeleted] "_..MailboxName_": "_resp)

            Set messageNumber = $Order(..MarkedAsDeleted(messageNumber), -1)
        }
        Kill ..MarkedAsDeleted
        
        Set resp = ..Helper.SendCommand("EXPUNGE")
        Do ..Helper.Log("[CommitMarkedAsDeleted] EXPUNGE: "_resp)
    }
    Catch ex {
        Set sc=ex.AsStatus()
    }
    Return sc
}

}
