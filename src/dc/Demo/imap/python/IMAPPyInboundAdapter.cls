/// Description
Class dc.Demo.imap.python.IMAPPyInboundAdapter Extends EnsLib.EMail.InboundAdapter
{

/// Description
Property MailServer As dc.Demo.imap.python.POP3ToIMAPPyAdapter;

/// Description
Property Mailbox As %String [ InitialExpression = "INBOX" ];

Parameter SETTINGS = "POP3Server:Basic,POP3Port:Basic,Credentials:Basic:credentialsSelector,SSLConfig:Connection:sslConfigSelector,SSLCheckServerIdentity:Connection,MatchFrom,MatchTo,MatchSubject,Mailbox";

Method OnInit() As %Status
{
    $$$TOE(sc, ##super())
    Do ..MailServer.SetMailboxName(..Mailbox)
    Return $$$OK
}

}
