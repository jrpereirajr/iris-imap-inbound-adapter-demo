Include Ensemble

/// An utility class to map POP3 method to the equivalent ones for IMAP,
/// using an IMAP client based on imaplib Python library
Class dc.Demo.imap.python.POP3ToIMAPPyAdapter Extends dc.Demo.imap.POP3ToIMAPAdapter
{

/// Description
Method %OnNew() As %Status [ Private ]
{
    Set sc = $$$OK
    Try {
        Set ..IMAPClient = ##class(dc.Demo.imap.python.IMAPPy).%New()
    }
    Catch ex {
        Set sc=ex.AsStatus()
    }
    Return sc
}

}
