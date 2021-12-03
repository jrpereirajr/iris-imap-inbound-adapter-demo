/// Description
Class dc.demo.imap.python.PythonDecorator Extends %SYS.Python
{

/// Description
Property obj As %SYS.Python;

Method %OnNew(pPythonObj As %SYS.Python) As %Status [ Private ]
{
    Set ..obj = pPythonObj
	Return $$$OK
}

Method %DispatchMethod(Method As %String, Args...)
{
    If (Method = "Get") {
        Set item = ..obj."__getitem__"(Args(1))
        If ($IsObject(item)) && (item.%IsA("%SYS.Python")) {
            Set item = ##class(dc.demo.imap.PythonDecorator).%New(item)
        }
        Return item
    }
}

}
