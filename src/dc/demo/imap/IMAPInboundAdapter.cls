/// Description
Class dc.demo.imap.IMAPInboundAdapter Extends EnsLib.EMail.InboundAdapter
{

/// Description
Property MailServer As dc.demo.imap.POP3ToIMAPAdapter;

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
