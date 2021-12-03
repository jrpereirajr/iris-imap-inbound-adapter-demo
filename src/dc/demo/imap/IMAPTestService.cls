Class dc.demo.imap.IMAPTestService Extends Ens.BusinessService
{

Parameter ADAPTER = "dc.demo.imap.IMAPInboundAdapter";

Method OnProcessInput(pMailMessage As %Net.MailMessage, pOutput As %RegisteredObject) As %Status
{
    Set tSC = $$$OK
    Try {
        $$$TRACE("received email from "_pMailMessage.From)
        Set tSubject = pMailMessage.Subject
        If '(tSubject [ "[IMAP test]") {
            $$$TRACE("EMail rejected: "_tSubject)
            Quit
        }
        Set tSendReply = ##class(dc.demo.imap.IMAPTestReplyMsg).%New()
        Set tSendReply.Text = tSubject
        Set tSendReply.Destination = pMailMessage.From
        Set tSendReply.Sender = pMailMessage.To.GetAt(1)
        Set tSC = ..SendRequestAsync("dc.demo.imap.IMAPTestSendEmailOperation", tSendReply)
        $$$TRACE("SendRequestAsync to dc.demo.imap.IMAPTestSendEmailOperation")    
    } Catch(ex) {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

}
