/// Description
Class dc.demo.imap.IMAPTestSendEmailOperation Extends Ens.BusinessOperation
{

/// 2 modes: Queue, InProc
Parameter INVOCATION = "Queue";

/// Name of the adapter class
Parameter ADAPTER = "EnsLib.EMail.OutboundAdapter";

XData MessageMap
{
<MapItem MessageType="dc.demo.imap.IMAPTestReplyMsg">
<Method>EMailSendReply</Method>
</MapItem>
}

Method EMailSendReply(pRequest As dc.demo.imap.IMAPTestReplyMsg, Output pResponse As Ens.Response) As %Status
{
	If pRequest.Destination = "" $$$TRACE("no email address.") Quit $$$OK
	$$$TRACE("send email to "_pRequest.Destination)
	Set tMailMessage = ##class(%Net.MailMessage).%New()
	Do tMailMessage.To.Insert(pRequest.Destination)
	Set tMailMessage.From = pRequest.Sender
	Set tMailMessage.Subject = "RE: "_pRequest.Text
	set tMailMessage.Charset = "UTF-8"
	Set tSC = tMailMessage.TextData.Write("Sent by IMAP Inbound Adapter Example.") 
    Quit:$$$ISERR(tSC) tSC
	Set tSC = ..Adapter.SendMail(tMailMessage)
	Quit tSC
}

}
