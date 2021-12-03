Include Ensemble

/// An utility class to map POP3 method to the equivalent ones for IMAP,
/// using an IMAP client
Class dc.demo.imap.POP3ToIMAPAdapter Extends %Net.POP3
{

/// Description
Property IMAPClient As dc.demo.imap.IMAP;

/// Description
Method %OnNew() As %Status [ Private ]
{
    Set sc = $$$OK
    Try {
        Set ..IMAPClient = ##class(dc.demo.imap.IMAP).%New()
    }
    Catch ex {
        Set sc=ex.AsStatus()
    }
    Return sc
}

/// Description
Method ConnectedGet() As %Boolean
{
    Return ..IMAPClient.Connected
}

/// Description
Method SSLConfigurationSet(pValue As %String) As %Status
{
    Set i%SSLConfiguration = pValue
    Set ..IMAPClient.SSLConfiguration = pValue
    Return $$$OK
}

/// Description
Method SetMailboxName(pValue As %String) As %Status
{
    Set sc = $$$OK
    Set ..IMAPClient.MailboxName = pValue
    Return sc
}

/// Description
Method ConnectPort(PopServer As %String, PopPort As %Integer = 110, UserName As %String, Password As %String) As %Status
{
    Set ..IMAPClient.Port = PopPort
    Return ..IMAPClient.Connect(PopServer, UserName, Password)
}

/// Description
Method FetchMessageHeaders(MessageNumber As %Integer, ByRef MsgHeadersArray As %String) As %Status
{
    Set sc = $$$OK
    $$$TOE(sc, ..FetchMessageInfo(MessageNumber, "", .From, .To, .Date, .Subject, .MessageSize, .MsgHeaders, .MessageText))
    Set headerVal = MsgHeaders.GetNext(.header)
    While (header '= "") {
        Set lowerHeader = $ZConvert(header, "L")
        Set MsgHeadersArray(lowerHeader) = headerVal
        Set headerVal = MsgHeaders.GetNext(.header)
    }
    Return sc
}

Method Connect(pServer As %String, pUserName As %String, pPassword As %String) As %Status
{
    Return ..IMAPClient.Connect(pServer, pUserName, pPassword)
}

Method GetMailBoxStatus(ByRef NumberOfMessages As %Integer, ByRef NumberOfBytes As %Integer) As %Status
{
    Return ..IMAPClient.GetMailBoxStatus(.NumberOfMessages, .NumberOfBytes)
}

Method GetSizeOfMessages(MessageNumber As %String = "", ByRef ListOfSizes As %ArrayOfDataTypes) As %Status
{
    Return ..IMAPClient.GetSizeOfMessages(MessageNumber, .ListOfSizes)
}

Method GetMessageUIDArray(MessageNumber As %String = "", ByRef ListOfUniqueIDs As %ArrayOfDataTypes) As %Status
{
    Return ..IMAPClient.GetMessageUIDArray(MessageNumber, .ListOfUniqueIDs)
}

Method GetMessageUID(MessageNumber As %Integer, ByRef UniqueID As %String) As %Status
{
    Return ..IMAPClient.GetMessageUIDArray(MessageNumber, .UniqueID)
}

Method Fetch(MessageNumber As %Integer, ByRef Msg As %Net.MailMessage, Delete As %Boolean = 0, messageStream As %BinaryStream = "") As %Status
{
    Return ..IMAPClient.Fetch(MessageNumber, .Msg, Delete, messageStream)
}

Method FetchFromStream(messageStream As %BinaryStream, ByRef Msg As %Net.MailMessage) As %Status
{
    Return ..IMAPClient.FetchFromStream(MessageNumber, .Msg)
}

Method FetchMessage(MessageNumber As %Integer, ByRef From As %String, ByRef To As %String, ByRef Date As %String, ByRef Subject As %String, ByRef MessageSize As %Integer, ByRef MsgHeaders As %ArrayOfDataTypes, ByRef Msg As %Net.MailMessage, Delete As %Boolean) As %Status
{
    Return ..IMAPClient.FetchMessage(MessageNumber, .From, .To, .Date, .Subject, .MessageSize, .MsgHeaders, .Msg, Delete)
}

Method FetchMessageInfo(MessageNumber As %Integer, Lines As %Integer, ByRef From As %String, ByRef To As %String, ByRef Date As %String, ByRef Subject As %String, ByRef MessageSize As %Integer, ByRef MsgHeaders As %ArrayOfDataTypes, ByRef MessageText As %String) As %Status
{
    Return ..IMAPClient.FetchMessageInfo(MessageNumber, Lines, .From, .To, .Date, .Subject, .MessageSize, .MsgHeaders, .MessageText)
}

Method DeleteMessage(MessageNumber As %Integer) As %Status
{
    Return ..IMAPClient.DeleteMessage(MessageNumber)
}

Method RollbackDeletes() As %Status
{
    Return ..IMAPClient.DeleteMessage()
}

Method QuitAndCommit() As %Status
{
    Return ..IMAPClient.QuitAndCommit()
}

Method QuitAndRollback() As %Status
{
    Return ..IMAPClient.QuitAndRollback()
}

Method Ping() As %Status
{
    Return ..IMAPClient.Ping()
}

}
