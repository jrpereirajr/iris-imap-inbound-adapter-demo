/// Description
Class dc.demo.imap.IMAPTestReplyMsg Extends Ens.Request
{

Property Text As %String(MAXLEN = "");

Property Destination As %String(MAXLEN = 1000);

Property Sender As %String(MAXLEN = 1000);

Storage Default
{
<Data name="IMAPTestReplyMsgDefaultData">
<Subscript>"IMAPTestReplyMsg"</Subscript>
<Value name="1">
<Value>Text</Value>
</Value>
<Value name="2">
<Value>Destination</Value>
</Value>
<Value name="3">
<Value>Sender</Value>
</Value>
</Data>
<DefaultData>IMAPTestReplyMsgDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
