/// Description
Class dc.Demo.imap.python.IMAPPy Extends dc.Demo.imap.IMAP
{

/// Description
Property Port As %String [ InitialExpression = 993 ];

/// Description
Property Server As %String [ Internal ];

/// Description
Property UserName As %String [ Internal, Private ];

/// Description
Property MailboxName As %String [ InitialExpression = "INBOX" ];

/// Description
Property imaplib As %SYS.Python [ Transient ];

/// Description
Property client As %SYS.Python;

/// Description
Property Helper As dc.Demo.imap.IMAPHelper;

Method %OnNew() As %Status [ Private ]
{
    Set ..imaplib = ##class(%SYS.Python).Import("imaplib")
    Set ..Helper = ##class(dc.Demo.imap.IMAPHelper).%New()
    Do ..Helper.Log("[%OnNew] imaplib: "_..PythonToString(..imaplib))
	Return $$$OK
}

/// Description
ClassMethod PythonToString(pPythonObj As %SYS.Python) As %String
{
    Return pPythonObj."__str__"()
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
    Try {
        Set ..Server = pServer
        Set ..UserName = pUserName

        Do ..Helper.Log("[Connect] Trying to establish connection to host "_..Server_" (user: "_..UserName_")")
        Set ..client = ..imaplib."IMAP4_SSL"(..Server)
        Do ..Helper.Log("[Connect] client "_..PythonToString(..client))
        Set resp = ..client.login(..UserName, pPassword)
        Do ..Helper.Log("[Connect] login: "_..PythonToString(resp))

        Set ..Connected = 1
        Do ..Helper.Log("[Connect] Connected successfully")
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
            Set tuple = ..client.logout()
            Do ..Helper.Log("[Disconnect] "_..PythonToString(tuple))
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

        Set resp = ..client.select(..MailboxName)
        Do ..Helper.Log("[GetMailBoxStatus] "_..MailboxName_": "_..PythonToString(resp))
        Set ackToken = resp."__getitem__"(0)
        Set dataArray = resp."__getitem__"(1)
        Set NumberOfMessages = dataArray."__getitem__"(0)
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

        // select the mailbox
        Set resp = ..client.select(..MailboxName)
        Do ..Helper.Log("[GetSizeOfMessages] "_..MailboxName_": "_..PythonToString(resp))

        // hack to ensure that MessageNumber is of type %String
        Set MessageNumber = MessageNumber_""
        Set resp = ..client.fetch(MessageNumber, "(RFC822.SIZE)")
        Do ..Helper.Log("[GetSizeOfMessages] fetch: "_..PythonToString(resp))
        Set ackToken = resp."__getitem__"(0)
        Set dataArray = resp."__getitem__"(1)
        
        Set:('$ISOBJECT($Get(ListOfSizes))) ListOfSizes = ##class(%ArrayOfDataTypes).%New()
        Set data = dataArray."__getitem__"(0)
        Set msgIdx = +$Piece(data, " ", 1)
        Set size = +$Piece(data, " ", 3)
        Do ListOfSizes.SetAt(size, msgIdx)
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

        // select the mailbox
        Set resp = ..client.select(..MailboxName)
        Do ..Helper.Log("[GetMessageUIDArray] "_..MailboxName_": "_..PythonToString(resp))
        Set mailboxSize = resp."__getitem__"(1)."__getitem__"(0)
        If (mailboxSize > 0) {
            // hack to ensure that MessageNumber is of type %String
            Set MessageNumber = MessageNumber_""
            // then get the mailbox UIDs
            #; Set param = $CASE(MessageNumber, "":"ALL", :MessageNumber)
            #; Set resp = ..client.uid("search", ##class(%SYS.Python).None(), param)
            Set param = $CASE(MessageNumber, "":"1:*", :MessageNumber)
            Set resp = ..client.fetch(param, "UID")
            Do ..Helper.Log("[GetMessageUIDArray] "_..MailboxName_" search: "_..PythonToString(resp))
            Set ackToken = resp."__getitem__"(0)
            Set dataArray = resp."__getitem__"(1)
            Set len = dataArray."__len__"()
        } Else {
            Set len = 0
        }
        
        Set:('$ISOBJECT($Get(ListOfUniqueIDs))) ListOfUniqueIDs = ##class(%ArrayOfDataTypes).%New(len)
        For i = 1:1:len {
            Set data = dataArray."__getitem__"(i - 1)
            Set msgIdx = +$Piece(data, " ", 1)
            Set size = +$Piece(data, " ", 3)
            Do ListOfUniqueIDs.SetAt(size, msgIdx)
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
        Set:($ISOBJECT($GET(ListOfUniqueIDs))) UniqueID = ListOfUniqueIDs.GetAt(MessageNumber)
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
Method Fetch(MessageNumber As %Integer, ByRef Msg As %Net.MailMessage, Delete As %Boolean, messageStream As %BinaryStream) As %Status
{
    Set sc = $$$OK
    Try {
        Do ..CheckConnection()

        // select the mailbox
        Set resp = ..client.select(..MailboxName)
        Do ..Helper.Log("[Fetch] "_..MailboxName_": "_..PythonToString(resp))

        // hack to ensure that MessageNumber is of type %String
        Set MessageNumber = MessageNumber_""
        // get the whole message
        Set resp = ..client.fetch(MessageNumber, "BODY.PEEK[]")
        #; Do ..Helper.Log("[Fetch] message: "_..PythonToString(resp))
        Set rawMsg = ..TransversePythonArray(resp."__getitem__"(1))
        Do ..Helper.Log("[Fetch] rawMsg: "_rawMsg)

        If $IsObject($Get(messageStream)) {
            $$$TOE(sc, messageStream.Write(rawMsg))
        }
        
        // get message size in bytes
        Set msgSize = ..Helper.GetMessageSizeFromFetch(rawMsg)
        
        // remove tags from message
        Set rawMsg = $Piece(rawMsg, $Char(13, 10), 2, * - 1)

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

        If ($Get(Delete) = 1) {
            $$$TOE(sc, ..DeleteMessage(MessageNumber))
        }
    }
    Catch ex {
        Set sc=ex.AsStatus()
        Do ..Helper.Log("[Fetch] Fetch failed: "_ex.DisplayString())
    }
    Return sc
}

/// Description
ClassMethod TransversePythonArray(pArray As %SYS.Python) As %String
{
    Set acc = ""
    If ($IsObject(pArray)) {
        Set len = pArray."__len__"()
        For i = 1:1:len {
            Set item = pArray."__getitem__"(i - 1)
            If ($IsObject(item)) {
                Set acc = acc_..TransversePythonArray(item)
            } Else {
                Set acc = acc_item
            }
            Set acc = acc_$Char(13, 10)
        }
    } Else {
        Set acc = pArray_$Char(13, 10)
    }
    Return acc
}

/// <P>This function is used to prevent an autologout timer from expiring
/// or to determine if the server is still functioning on the connection.</P>
Method Ping() As %Status
{
    Set sc = $$$OK
    Try {
        Do ..CheckConnection()
        Set resp = ..client.noop()
        Do ..Helper.Log("[Fetch] Ping: "_..PythonToString(resp))
    }
    Catch ex {
        Set sc=ex.AsStatus()
        Do ..Helper.Log("[Ping] Ping failed: "_ex.DisplayString())
    }
    Return sc
}

/// Description
Method CommitMarkedAsDeleted() As %Status [ Internal, Private ]
{
    Set sc = $$$OK
    Try {
        Do ..CheckConnection()

        // select the mailbox
        Set resp = ..client.select(..MailboxName)
        Do ..Helper.Log("[CommitMarkedAsDeleted] "_..MailboxName_": "_..PythonToString(resp))
        
        // transverse array in inverse order to keep numbers integrety, that is,
        // ensures that when onde number is deleted no other message can assume
        // such number
        Set messageNumber = $Order(..MarkedAsDeleted(""), -1)
        While (messageNumber '= "") {
            // hack to ensure that messageNumber is of type %String
            Set messageNumber = messageNumber_""
            Set resp = ..client.store(messageNumber, "+FLAGS", "\Deleted")
            Do ..Helper.Log("[CommitMarkedAsDeleted] "_..MailboxName_": "_..PythonToString(resp))

            Set messageNumber = $Order(..MarkedAsDeleted(messageNumber), -1)
        }
        Kill ..MarkedAsDeleted
        
        Set resp = ..client.expunge()
        Do ..Helper.Log("[CommitMarkedAsDeleted] EXPUNGE: "_..PythonToString(resp))
    }
    Catch ex {
        Set sc=ex.AsStatus()
        Do ..Helper.Log("[CommitMarkedAsDeleted] CommitMarkedAsDeleted failed: "_ex.DisplayString())
    }
    Return sc
}

}
