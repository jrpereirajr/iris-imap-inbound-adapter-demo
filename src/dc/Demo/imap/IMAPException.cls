/// Description
Class dc.Demo.imap.IMAPException Extends %Exception.AbstractException
{

/// Override this method to provide a custom conversion of an exception to a status.
/// $$$ERROR(..Code,..Data,,,,,,,,,..Location)
Method OnAsStatus() As %Status [ CodeMode = expression, Private ]
{
$$$ERROR(..Code,..Name,,,,,,,,,..Location)
}

}
