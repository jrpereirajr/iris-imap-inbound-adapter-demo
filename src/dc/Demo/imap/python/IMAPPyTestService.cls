Class dc.Demo.imap.python.IMAPPyTestService Extends Ens.BusinessService
{

Parameter ADAPTER = "dc.Demo.imap.python.IMAPPyInboundAdapter";

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
        Set tSendReply = ##class(dc.Demo.imap.IMAPTestReplyMsg).%New()
        Set tSendReply.Text = tSubject
        Set tSendReply.Destination = pMailMessage.From
        Set tSendReply.Sender = pMailMessage.To.GetAt(1)
        Set tSC = ..SendRequestAsync("dc.Demo.imap.IMAPTestSendEmailOperation", tSendReply)
        $$$TRACE("SendRequestAsync to dc.Demo.imap.IMAPTestSendEmailOperation")    
    } Catch(ex) {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

}
